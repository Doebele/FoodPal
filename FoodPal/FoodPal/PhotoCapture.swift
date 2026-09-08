import SwiftUI
import SwiftData
import PhotosUI
import ImagePlayground

/// Foto aufnehmen, schätzen lassen, bestätigen.
///
/// Vier Zustände, kein Assistent mit Schritten: aufnehmen, analysieren,
/// bestätigen, oder gescheitert. Der Weg zur manuellen Eingabe steht in
/// jedem davon offen.
struct PhotoCapture: View {
    let onSaved: () -> Void

    @Environment(\.modelContext) private var context
    @AppStorage(Preference.healthSync) private var healthSync = true
    @AppStorage(Preference.provider) private var providerRaw = Provider.claude.rawValue
    @AppStorage(Preference.models) private var modelsJSON = "{}"
    @AppStorage(Preference.addresses) private var addressesJSON = "{}"

    @State private var health = HealthKitSync()
    @State private var phase = {
        #if DEBUG
        return ProcessInfo.processInfo.environment["START_DESCRIBE"] == "1" ? Phase.describing : .idle
        #else
        return Phase.idle
        #endif
    }()
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var saves = 0
    @State private var spoken = ""
    /// Merkt sich, dass der Abgang ein Erfolg war und nicht ein Abbruch.
    @State private var saved = false

    private enum Phase {
        case idle
        /// Beschreiben statt fotografieren — der Text kommt übers Diktat der
        /// Systemtastatur, deshalb braucht es hier kein Mikrofon.
        case describing
        /// `source` steht auf dem Ladescreen — sonst behauptet er, Claude
        /// arbeite, während in Wahrheit die Datenbank gefragt wird.
        case analysing(UIImage?, source: String)
        /// **Mehrere** Gerichte: „Spaghetti, dazu eine Minestrone" sind zwei
        /// Einträge. Beim Foto ist es immer genau eines.
        ///
        /// `per100g` unterscheidet die Quellen: die Datenbank liefert je 100 g
        /// und braucht ein Mengenfeld, die Schätzung gilt für die Portion.
        case ready(UIImage?, [MealEstimate], per100g: Bool)
        case failed(UIImage?, String)

        var isIdle: Bool {
            if case .idle = self { return true }
            return false
        }
    }

    private var provider: Provider { Provider(rawValue: providerRaw) ?? .claude }
    private var effectiveModel: String { provider.model(from: modelsJSON) }

    var body: some View {
        intake
            .padding(.horizontal, Metric.margin)
            .haptic(trigger: saves)
            .photosPicker(isPresented: .constant(false), selection: $photoItem)
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task { await load(item) }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { image in
                    showCamera = false
                    if let image { Task { await analyse(image) } }
                }
                .ignoresSafeArea()
            }
            // Alles nach der Wahl des Wegs liegt eine Ebene tiefer — siehe
            // `work`. Nach unten wischen bricht ab, ohne etwas zu speichern.
            //
            // Das Schliessen der Erfassung haengt an `onDismiss` und nicht
            // direkt am Sichern: solange das innere Sheet noch verschwindet,
            // schluckt UIKit die zweite Anweisung, und die Erfassung bliebe
            // offen stehen. `onDismiss` feuert, wenn wirklich nichts mehr da
            // ist.
            .sheet(isPresented: working, onDismiss: {
                guard saved else { return }
                saved = false
                onSaved()
            }) {
                work
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.large])
                    .presentationBackground(Palette.paper)
            }
    }

    /// Offen, sobald ein Weg gewählt ist. Zurück auf `idle` heisst zu: das
    /// Wischen nach unten und der Schliessen-Knopf laufen beide hierdurch.
    private var working: Binding<Bool> {
        Binding(get: { !phase.isIdle }, set: { if !$0 { phase = .idle } })
    }

    /// **Der zweite Screen als eigenes Sheet.**
    ///
    /// Vorher stand darunter weiter der kcal/mg-Umschalter der Erfassung — ein
    /// Fehltipp auf mg warf jede eingetippte Beschreibung weg. Hier gibt es
    /// nur noch zwei Ausgänge: absenden oder abbrechen. Zwei Handlungen auf
    /// einem Screen sind eine zu viel, wenn eine davon die andere vernichtet.
    private var work: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(title: workTitle)

            Group {
                switch phase {
                case .idle: EmptyView()
                case .describing: describe
                case .analysing(let image, let source): analysing(image, source)
                case .ready(let image, let estimates, let per100g):
                    Confirm(image: image, estimates: estimates, per100g: per100g, onSave: save)
                case .failed(let image, let message): failure(image, message)
                }
            }
            .padding(.horizontal, Metric.margin)
            // Den Fussraum, den vorher der Umschalter der Erfassung gab, gibt
            // es hier nicht mehr — sonst laeuft der Sichern-Knopf in den
            // Home-Indikator.
            .padding(.bottom, 12)
        }
        .background(Palette.paper)
    }

    private var workTitle: String {
        switch phase {
        case .describing: "Beschreiben"
        case .analysing: "Analyse"
        case .ready: "Bestätigen"
        case .failed: "Fehlgeschlagen"
        case .idle: ""
        }
    }

    // MARK: - Aufnahme

    private var intake: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)

            Rectangle().fill(Palette.rule).frame(height: 1)
            action("Foto aufnehmen") { showCamera = true }
            PhotosPicker(selection: $photoItem, matching: .images) {
                rowLabel("Aus Fotos wählen")
            }
            .buttonStyle(.plain)
            .overlay(alignment: .bottom) { Rectangle().fill(Palette.rule).frame(height: 1) }
            action("Beschreiben") { phase = .describing }
            action("Manuell eingeben") {
                phase = .ready(nil, [MealEstimate(name: "", kcal: 0)], per100g: false)
            }

            Text(provider.readsPhotos
                 ? "Geschätzt wird von \(provider.label)."
                 : "\(provider.label) schätzt nur aus Beschreibungen.")
                .font(.system(size: 11))
                .foregroundStyle(Palette.ink2)
                .padding(.top, 12)
        }
    }

    // MARK: - Beschreiben

    /// Ein Textfeld, kein Mikrofonknopf. Diktieren kann die Systemtastatur
    /// bereits — das spart die Spracherkennung samt zweier Berechtigungen und
    /// hat den wichtigeren Vorteil: **du siehst den Text, bevor er weggeht.**
    /// Diktat verhört sich bei Essensnamen zuverlässig, und ein Knopf, der
    /// direkt aufnimmt und schickt, würde den Fehler unsichtbar weiterreichen.
    private var describe: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("was und wann")
                .font(.system(size: 11)).tracking(0.8)
                .foregroundStyle(Palette.ink2)
                .padding(.top, 16)

            TextField(
                "Gestern Abend um neun eine kleine Ramensuppe mit Frühlingszwiebel, dazu drei Scheiben Baguette dünn mit Butter",
                text: $spoken,
                axis: .vertical
            )
            .lineLimit(4...12)
            .font(.system(size: 17))
            .foregroundStyle(Palette.ink)
            .padding(.top, 10)

            Rectangle().fill(Palette.rule).frame(height: 1).padding(.top, 10)

            Text("Diktieren über das Mikrofon der Tastatur. Zeitangaben wie \u{201E}gestern Abend um neun\u{201C} werden übernommen; mehrere Gerichte werden einzeln erfasst.")
                .font(.system(size: 11))
                .foregroundStyle(Palette.ink2)
                .padding(.top, 12)

            Spacer(minLength: 0)

            Button {
                Task { await analyse(spoken) }
            } label: {
                Text("Schätzen")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Palette.paper)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(spoken.isEmpty ? Palette.ink2 : Palette.ink)
            }
            .buttonStyle(.plain)
            .disabled(spoken.isEmpty)
        }
    }

    // MARK: - Analyse

    private func analysing(_ image: UIImage?, _ source: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 260)
                    .clipped()
                    .padding(.top, 12)
            } else {
                // Ohne Foto steht der gesprochene Text an seiner Stelle — man
                // sieht beim Warten, was gerade geschaetzt wird.
                Text(spoken)
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.ink2)
                    .padding(.top, 20)
            }

            ProgressDots().padding(.top, 14)

            Text("Analysiere")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(Palette.ink)
                .padding(.top, 18)
            Text(source)
                .font(.system(size: 13))
                .foregroundStyle(Palette.ink2)
                .padding(.top, 4)

            Spacer(minLength: 0)
        }
    }

    // MARK: - Fehler

    private func failure(_ image: UIImage?, _ message: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let image {
                Image(uiImage: image)
                    .resizable().scaledToFill().frame(height: 180).clipped()
                    .padding(.top, 12)
            }
            Text("Schätzung fehlgeschlagen")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(Palette.ink)
                .padding(.top, 20)

            // Anbieter und Modell mit dazu: ohne sie ist eine Fehlermeldung
            // nicht zuzuordnen, wenn zwoelf Dienste in Frage kommen.
            Text(provider.label + " · " + effectiveModel)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Palette.ink2)
                .padding(.top, 6)

            ScrollView {
                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.ink2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .scrollIndicators(.hidden)
            .frame(maxHeight: 160)
            .padding(.top, 8)

            Spacer(minLength: 0)

            Rectangle().fill(Palette.rule).frame(height: 1)
            if let image {
                action("Erneut versuchen") { Task { await analyse(image) } }
            } else if !spoken.isEmpty {
                action("Erneut versuchen") { Task { await analyse(spoken) } }
                action("Beschreibung ändern") { phase = .describing }
            }
            action("Manuell eingeben") {
                phase = .ready(image, [MealEstimate(name: "", kcal: 0)], per100g: false)
            }
        }
    }

    // MARK: - Bausteine

    private func action(_ title: String, run: @escaping () -> Void) -> some View {
        Button(action: run) { rowLabel(title) }
            .buttonStyle(.plain)
            .overlay(alignment: .bottom) { Rectangle().fill(Palette.rule).frame(height: 1) }
    }

    private func rowLabel(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Palette.ink)
            Spacer()
        }
        .frame(height: 56)
        .contentShape(Rectangle())
    }

    // MARK: - Ablauf

    private func load(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        photoItem = nil
        await analyse(image)
    }

    private func analyse(_ image: UIImage) async {
        // Erst der billige Weg: sitzt ein lesbarer Barcode auf dem Bild, kommen
        // exakte Werte aus der Datenbank — kein LLM-Aufruf, keine Schätzung.
        // Findet sich keiner oder kennt die Datenbank das Produkt nicht, läuft
        // stillschweigend der gewohnte Weg weiter.
        if let code = Barcode.read(image) {
            phase = .analysing(image, source: "Open Food Facts")
            if let product = try? await FoodDatabase.lookup(code) {
                phase = .ready(image, [product], per100g: true)
                return
            }
        }

        phase = .analysing(image, source: provider.label + " · " + effectiveModel)
        do {
            let estimate = try await VisionEstimator.estimate(
                image: image,
                provider: provider,
                model: effectiveModel,
                baseURL: provider.address(from: addressesJSON)
            )
            phase = .ready(image, [estimate], per100g: false)
        } catch {
            phase = .failed(image, error.localizedDescription)
        }
    }

    /// Beschreibung statt Foto — kein Barcode-Umweg, keine Datenbank.
    private func analyse(_ text: String) async {
        phase = .analysing(nil, source: provider.label + " · " + effectiveModel)
        do {
            let estimates = try await VisionEstimator.estimate(
                text: text,
                provider: provider,
                model: effectiveModel,
                baseURL: provider.address(from: addressesJSON)
            )
            phase = .ready(nil, estimates, per100g: false)
        } catch {
            phase = .failed(nil, error.localizedDescription)
        }
    }

    /// Ein Sprachsatz kann mehrere Gerichte enthalten, also entstehen mehrere
    /// Eintraege. Das Bild — Foto wie erzeugtes — gehoert der Mahlzeit als
    /// ganzer und haengt deshalb an jedem davon; bei 80 kB je Kopie ist das
    /// billiger als eine Gruppierung im Modell, die es sonst nirgends braucht.
    private func save(_ image: UIImage?, _ generated: Bool, _ items: [MealEstimate], _ when: Date) {
        let data = image.flatMap { VisionEstimator.downscaled($0, maxEdge: 900) }

        for item in items {
            let entry = Entry(
                date: item.date ?? when,
                name: item.name.isEmpty ? "Mahlzeit" : item.name,
                kind: .meal,
                kcal: item.kcal,
                proteinG: item.proteinG,
                carbsG: item.carbsG,
                fatG: item.fatG,
                photo: data,
                generatedImage: generated
            )
            context.insert(entry)
            if healthSync {
                Task { entry.hkIDs = (try? await health.save(entry)) ?? [] }
            }
        }
        saves += 1
        saved = true

        // Kurz warten, damit der Impuls ankommt, bevor sich etwas bewegt.
        Task {
            try? await Task.sleep(for: .milliseconds(120))
            phase = .idle
        }
    }
}

/// Bestätigung: alles ist änderbar, bevor es gespeichert wird. Eine Schätzung
/// liegt realistisch daneben — der Schritt ist keine Höflichkeit.
///
/// Ein Gericht bekommt das volle Formular wie bisher. Mehrere bekommen je eine
/// Zeile mit Name und kcal: fünf Felder mal drei Gerichte wären eine Wand, und
/// Makros lassen sich hinterher am Eintrag korrigieren, wo ohnehin alle Felder
/// stehen.
private struct Confirm: View {
    let image: UIImage?
    let estimates: [MealEstimate]
    /// Werte aus der Datenbank gelten je 100 g — dann braucht es ein Mengenfeld,
    /// das sie umrechnet. Bei einer Schätzung gelten sie schon für die Portion.
    let per100g: Bool
    let onSave: (UIImage?, Bool, [MealEstimate], Date) -> Void

    @State private var drafts: [Draft] = []
    @State private var when = Date.now
    @State private var timeTouched = false
    @State private var editingTime = false
    @State private var grams = "100"
    @State private var generated: UIImage?
    @State private var showPlayground = false
    @State private var loaded = false

    private struct Draft: Identifiable {
        let id = UUID()
        var name = ""
        var kcal = ""
        var protein = ""
        var carbs = ""
        var fat = ""
        var date: Date?
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                picture
                timeField

                if drafts.count == 1 {
                    singleForm
                } else {
                    ForEach($drafts) { $draft in compactRow($draft) }
                }

                Button { commit() } label: {
                    Text(drafts.count > 1 ? "\(drafts.count) Einträge sichern" : "Sichern")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Palette.paper)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Palette.ink)
                }
                .buttonStyle(.plain)
                .padding(.top, 12)
            }
        }
        .scrollIndicators(.hidden)
        .onChange(of: grams) { _, _ in if per100g { rescale() } }
        .modifier(PlaygroundSheet(isPresented: $showPlayground, concept: concept) {
            generated = $0
        })
        .task {
            guard !loaded else { return }
            drafts = estimates.map { estimate in
                Draft(
                    name: estimate.name,
                    kcal: estimate.kcal > 0 ? String(Int(estimate.kcal)) : "",
                    protein: estimate.proteinG.map { String(Int($0)) } ?? "",
                    carbs: estimate.carbsG.map { String(Int($0)) } ?? "",
                    fat: estimate.fatG.map { String(Int($0)) } ?? "",
                    date: estimate.date
                )
            }
            when = (estimates.first?.date ?? .now).startOfQuarterHour
            if per100g { rescale() }
            loaded = true
        }
    }

    // MARK: - Bild

    /// Kein Foto und keins erzeugt: dann steht hier die Einladung, eines
    /// erzeugen zu lassen — aber nur, wo das Geraet es kann.
    @ViewBuilder private var picture: some View {
        if let shown = image ?? generated {
            Image(uiImage: shown)
                .resizable().scaledToFill().frame(height: 150).clipped()
                .padding(.top, 12)
                .overlay(alignment: .bottomLeading) {
                    if image == nil {
                        Text("erzeugt")
                            .font(.system(size: 10)).tracking(0.8)
                            .foregroundStyle(Palette.paper)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Palette.ink)
                            .padding(8)
                    }
                }
                .padding(.bottom, 20)
        } else if #available(iOS 18.1, *) {
            GenerateImageRow(disabled: concept.isEmpty) { showPlayground = true }
                .padding(.top, 12)
                .padding(.bottom, 20)
        }
    }

    /// Woraus das Bild entsteht: die Namen der Gerichte, nicht der ganze
    /// gesprochene Satz — Zeitangaben und Mengen helfen einem Bild nicht.
    private var concept: String {
        drafts.map(\.name).filter { !$0.isEmpty }.joined(separator: ", ")
    }

    // MARK: - Zeitpunkt

    /// Aus „gestern Abend um neun" kommt der Zeitpunkt schon richtig zurueck;
    /// hier laesst er sich nachbessern. Das Rad rastet in Viertelstunden, und
    /// nach vorn ist bei jetzt Schluss.
    private var timeField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { editingTime.toggle() }
            } label: {
                HStack {
                    Text("zeitpunkt")
                        .font(.system(size: 11)).tracking(0.8)
                        .foregroundStyle(Palette.ink2)
                    Spacer()
                    Text(when.formatted(.dateTime.day().month().year().hour().minute()))
                        .font(.system(size: 17, weight: .light, design: .monospaced))
                        .foregroundStyle(Palette.ink)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if editingTime {
                QuarterHourPicker(date: $when)
                    .frame(maxWidth: .infinity)
            }

            Rectangle().fill(Palette.rule).frame(height: 1)
        }
        .padding(.bottom, 18)
        .onChange(of: when) { _, _ in timeTouched = true }
    }

    // MARK: - Felder

    @ViewBuilder private var singleForm: some View {
        if let draft = $drafts.first {
            field("bezeichnung", text: draft.name, mono: false)
            if per100g { field("menge · g", text: $grams, mono: true) }
            field("kcal", text: draft.kcal, mono: true)
            field("protein · g", text: draft.protein, mono: true)
            field("kohlenhydrate · g", text: draft.carbs, mono: true)
            field("fett · g", text: draft.fat, mono: true)
        }
    }

    /// Name und kcal nebeneinander, mehr braucht die Durchsicht nicht. Die
    /// Makros sind gespeichert und stehen im Eintrag, falls sie stoeren.
    private func compactRow(_ draft: Binding<Draft>) -> some View {
        HStack(spacing: 12) {
            TextField("Gericht", text: draft.name)
                .font(.system(size: 17))
                .foregroundStyle(Palette.ink)
            TextField("0", text: draft.kcal)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 17, design: .monospaced))
                .foregroundStyle(Palette.ink)
                .frame(width: 70)
            Text("kcal")
                .font(.system(size: 11))
                .foregroundStyle(Palette.ink2)
        }
        .frame(height: 52)
        .overlay(alignment: .bottom) { Rectangle().fill(Palette.rule).frame(height: 1) }
    }

    private func field(_ label: String, text: Binding<String>, mono: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11)).tracking(0.8)
                .foregroundStyle(Palette.ink2)
            TextField("", text: text)
                .keyboardType(mono ? .decimalPad : .default)
                .font(.system(size: 22, weight: .light, design: mono ? .monospaced : .default))
                .foregroundStyle(Palette.ink)
            Rectangle().fill(Palette.rule).frame(height: 1)
        }
        .padding(.bottom, 18)
    }

    // MARK: - Rechnen und Sichern

    /// Menge aendern schreibt die vier Naehrwertfelder neu. Wer danach ein Feld
    /// von Hand korrigiert, behaelt seine Korrektur — bis er die Menge erneut
    /// anfasst. Vorhersehbarer als eine Zwei-Wege-Bindung.
    private func rescale() {
        guard let estimate = estimates.first, !drafts.isEmpty else { return }
        let factor = (Double(grams.replacingOccurrences(of: ",", with: ".")) ?? 0) / 100
        func scaled(_ value: Double?) -> String {
            value.map { String(Int(($0 * factor).rounded())) } ?? ""
        }
        drafts[0].kcal = scaled(estimate.kcal)
        drafts[0].protein = scaled(estimate.proteinG)
        drafts[0].carbs = scaled(estimate.carbsG)
        drafts[0].fat = scaled(estimate.fatG)
    }

    private func commit() {
        func number(_ text: String) -> Double? {
            Double(text.replacingOccurrences(of: ",", with: "."))
        }
        let items = drafts.map { draft in
            MealEstimate(
                name: draft.name,
                kcal: number(draft.kcal) ?? 0,
                proteinG: number(draft.protein),
                carbsG: number(draft.carbs),
                fatG: number(draft.fat),
                // Am Rad gedreht heisst: dieser Zeitpunkt gilt fuer alle.
                // Sonst behaelt jedes Gericht seinen eigenen, falls das Modell
                // mehrere genannt hat.
                date: timeTouched ? when : draft.date
            )
        }
        onSave(image ?? generated, image == nil && generated != nil, items, when)
    }
}

/// Die Zeile, die Apples Bildgenerator oeffnet — nur sichtbar, wo das Geraet
/// Apple Intelligence hat.
@available(iOS 18.1, *)
private struct GenerateImageRow: View {
    @Environment(\.supportsImagePlayground) private var supported
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        if supported {
            Button(action: action) {
                HStack {
                    Text("Bild erzeugen")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(disabled ? Palette.ink2 : Palette.ink)
                    Spacer()
                }
                .frame(height: 56)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(disabled)
            .overlay(alignment: .bottom) { Rectangle().fill(Palette.rule).frame(height: 1) }
        }
    }
}

/// Apples Image Playground, hinter einer Verfuegbarkeitspruefung.
///
/// Bewusst das **Sheet** und nicht `ImageCreator`: die programmatische Variante
/// ist abgekuendigt und hoert in iOS 27 auf zu arbeiten. Das Sheet kostet einen
/// Tipp mehr, laeuft dafuer weiter — und sein Stil ist von Haus aus
/// zeichnerisch, ein erzeugtes Bild kann also nie fuer ein Foto gehalten werden.
private struct PlaygroundSheet: ViewModifier {
    @Binding var isPresented: Bool
    let concept: String
    let onImage: (UIImage) -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18.1, *) {
            content.imagePlaygroundSheet(isPresented: $isPresented, concept: concept) { url in
                if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    onImage(image)
                }
            }
        } else {
            content
        }
    }
}

/// Fortschritt im Punktraster statt als Spinner — ein Balken, der durchläuft.
private struct ProgressDots: View {
    @State private var lit = 0
    private let total = 24

    var body: some View {
        Canvas { ctx, size in
            let s = size.width / (Grid.x(total - 1) + Grid.dot)
            for index in 0..<total {
                let rect = CGRect(x: Grid.x(index) * s, y: 0,
                                  width: Grid.dot * s, height: Grid.dot * s)
                ctx.fill(Path(rect), with: .color(index < lit ? Palette.ink : Palette.rule))
            }
        }
        .aspectRatio((Grid.x(total - 1) + Grid.dot) / Grid.dot, contentMode: .fit)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(90))
                lit = lit >= total ? 0 : lit + 1
            }
        }
    }
}

/// Systemkamera in einem Wrapper — die eigene Kamera-Oberfläche zu bauen
/// wäre für ein Foto je Mahlzeit unverhältnismäßig.
struct CameraPicker: UIViewControllerRepresentable {
    let onResult: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onResult: onResult) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onResult: (UIImage?) -> Void
        init(onResult: @escaping (UIImage?) -> Void) { self.onResult = onResult }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            onResult(info[.originalImage] as? UIImage)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onResult(nil)
        }
    }
}
