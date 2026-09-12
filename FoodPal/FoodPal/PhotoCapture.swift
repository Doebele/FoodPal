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
    /// Ruft die Einstellungen auf, wenn noch kein Modell eingerichtet ist.
    var onSetup: () -> Void = {}

    @Environment(\.modelContext) private var context
    @AppStorage(Preference.healthSync) private var healthSync = true
    @AppStorage(Preference.provider) private var providerRaw = Provider.claude.rawValue
    @AppStorage(Preference.roast) private var roastRaw = Roast.hell.rawValue
    @AppStorage(Preference.models) private var modelsJSON = "{}"
    @AppStorage(Preference.addresses) private var addressesJSON = "{}"
    @AppStorage(Preference.hand) private var handRaw = Hand.right.rawValue

    @Environment(\.dynamicTypeSize) private var typeSize

    @State private var health = HealthKitSync()
    @State private var phase = {
        #if DEBUG
        let env = ProcessInfo.processInfo.environment
        if env["START_DESCRIBE"] == "1" { return Phase.describing }
        // Der Wartezustand ist sonst nur zu sehen, solange ein Modell
        // tatsaechlich rechnet — fuer einen Blick darauf zu kurz.
        if env["START_ANALYSING"] == "1" { return Phase.analysing(nil, source: "Claude · claude-sonnet-5") }
        if env["START_CONFIRM"] == "1" {
            return Phase.ready(nil, [MealEstimate(
                name: "Coca-Cola Zero mittel",
                kcal: 3, proteinG: 0, carbsG: 0, fatG: 0, caffeineMg: 36
            )], per100g: false)
        }
        return .idle
        #else
        return Phase.idle
        #endif
    }()
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var saves = 0
    @State private var spoken = ""
    @State private var dictation = Dictation()
    /// Was vor dem Diktat schon im Feld stand. Die Erkennung liefert immer den
    /// ganzen erkannten Satz, nicht das Neue daran — ohne diesen Anker würde
    /// ein zweites Diktat das erste überschreiben.
    @State private var beforeDictation = ""
    /// Merkt sich, dass der Abgang ein Erfolg war und nicht ein Abbruch.
    @State private var saved = false
    @State private var askSetup = false

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
    private var hand: Hand { Hand(rawValue: handRaw) ?? .right }

    /// **Ohne Modell keine Mahlzeit.** Kaffee geht immer, der steht als Sorte
    /// bereit; eine Mahlzeit dagegen schaetzt ein Modell aus Foto oder
    /// Beschreibung, und ohne Schluessel antwortet keines. Die App startet
    /// bewusst im Kaffeemodus, also trifft das genau den, der zum ersten Mal
    /// auf kcal wechselt.
    ///
    /// `isConfigured` sagt für die Dienste im eigenen Netz immer ja: die
    /// brauchen keinen Schluessel. Stimmt dort die Adresse nicht, sagt es der
    /// Verbindungstest in den Einstellungen, nicht dieser Dialog.
    private var ready: Bool { provider.isConfigured }
    private var roast: Roast { Roast(rawValue: roastRaw) ?? .hell }
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
            // **Modal, weil hier nichts weitergeht.** Ein Hinweis in der Ecke
            // liesse den Tipp ins Leere laufen; der Dialog nennt den Grund und
            // den naechsten Schritt in einem Zug.
            .alert("Noch kein Modell eingerichtet", isPresented: $askSetup) {
                Button("Einstellungen öffnen") { onSetup() }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Mahlzeiten schätzt ein Sprachmodell aus dem Foto oder deiner Beschreibung. Trage in den Einstellungen einen Anbieter und seinen Schlüssel ein. Oder wähle Apple, das auf dem Gerät rechnet und keinen Schlüssel braucht.")
            }
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

    private var workTitle: LocalizedStringKey {
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
            // Das Kreuz steht oben und sagt, worum es hier geht: hinzufügen.
            // Es ist keine Schaltfläche — der Weg wird unten gewählt, wo der
            // Daumen liegt.
            DotArt.cross
                .frame(width: 186, height: 186)
                .frame(maxWidth: .infinity)
                .padding(.top, 24)

            Spacer(minLength: 24)

            // Zwei mal zwei, und das Feld oben links bleibt leer: der Blick
            // faellt vom Kreuz nach unten, und dort liegt auch der Daumen.
            // Aus dem Entwurf (Node `160:111885`) — vorher standen hier drei
            // Zeilen untereinander.
            VStack(spacing: CaptureTile.gap) {
                if typeSize.isAccessibilitySize {
                    // Bei den Bedienhilfengroessen steht jede Kachel fuer sich:
                    // in einer halben Spalte bricht „aus fotos waehlen" sonst
                    // mitten im Wort.
                    fromPhotos
                    describing
                    fromCamera
                } else {
                    // Das leere Feld liegt der Bedienhand gegenueber, und
                    // die Kamera landet in ihrer Ecke.
                    row {
                        if hand == .right {
                            Color.clear.frame(maxWidth: .infinity)
                            fromPhotos
                        } else {
                            fromPhotos
                            Color.clear.frame(maxWidth: .infinity)
                        }
                    }
                    row {
                        if hand == .right {
                            describing
                            fromCamera
                        } else {
                            fromCamera
                            describing
                        }
                    }
                }
            }

            // Steht nicht im Entwurf, bleibt trotzdem: wer als Schaetzer
            // Apple gewaehlt hat, bekommt aus einem Foto nichts — und muss
            // das sehen, bevor er eins macht.
            // Klein steht der Satz schon im Katalog; der Name kommt gross aus
            // `provider.label`. Ein `textCase(.lowercase)` waere hier falsch:
            // es machte aus Claude ein claude.
            Text(provider.readsPhotos
                 ? "geschätzt wird von \(provider.label)."
                 : "\(provider.label) schätzt nur aus Beschreibungen.")
                .scaledFont(11)
                .foregroundStyle(Palette.ink2)
                .padding(.top, 10)
        }
    }

    private var fromPhotos: some View {
        // Ohne Modell **kein** Auswahlblatt: sonst sucht man ein Foto aus und
        // erfaehrt erst danach, dass es niemanden gibt, der es anschaut.
        Group {
            if ready {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    CaptureTile(label: "Aus Fotos wählen", marks: [.photos(color: Palette.ink)])
                }
            } else {
                Button { askSetup = true } label: {
                    CaptureTile(label: "Aus Fotos wählen", marks: [.photos(color: Palette.ink)])
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var fromCamera: some View {
        Button { ready ? showCamera = true : (askSetup = true) } label: {
            CaptureTile(label: "Foto aufnehmen", marks: [.camera(color: Palette.ink)])
        }
        .buttonStyle(.plain)
    }

    private var describing: some View {
        Button { ready ? (phase = .describing) : (askSetup = true) } label: {
            CaptureTile(label: "Beschreiben",
                        marks: [.pencil(color: Palette.ink), .microphone(color: Palette.ink)])
        }
        .buttonStyle(.plain)
    }

    /// Eine Kachelzeile. Beide Kacheln bekommen dieselbe Hoehe — die der
    /// hoeheren: bei grosser Schrift waechst eine Beschriftung auf zwei
    /// Zeilen, und ohne das stuende die andere Kachel kuerzer daneben.
    private func row<Inhalt: View>(@ViewBuilder _ inhalt: () -> Inhalt) -> some View {
        HStack(spacing: CaptureTile.gap) {
            inhalt().frame(maxHeight: .infinity)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Beschreiben

    /// Sprache ist hier der Hauptweg, nicht die Ausweichlösung: das Feld hat
    /// beim Öffnen den Fokus, und ein Tippen auf die Rosette diktiert direkt
    /// hinein. Getippt wird trotzdem in dasselbe Feld.
    ///
    /// Abgeschickt wird **nicht** automatisch. Diktat verhört sich bei
    /// Essensnamen zuverlässig, und ein Weg, der aufnimmt und sofort schätzt,
    /// würde den Fehler unsichtbar weiterreichen. Man sieht, was ankam.
    private var describe: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                if !dictation.isRunning { beforeDictation = spoken.isEmpty ? "" : spoken + " " }
                dictation.toggle()
            } label: {
                DotArt.speaker(color: dictation.isRunning ? roast.color : Palette.rule)
                    .frame(width: 187, height: 187)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(dictation.isRunning ? "Diktat beenden" : "Diktieren")

            Text("was und wann")
                .scaledFont(11).tracking(0.8)
                .foregroundStyle(Palette.ink2)
                .padding(.top, 24)

            // Der Platzhalter liegt in SwiftUI hinter dem Feld statt als
            // `UILabel` darin: so folgt er derselben Schrift- und
            // Farbregelung wie alles andere und bricht von selbst um.
            ZStack(alignment: .topLeading) {
                if spoken.isEmpty {
                    Text("Gestern Abend um neun eine kleine Ramensuppe mit Frühlingszwiebel, dazu drei Scheiben Baguette dünn mit Butter")
                        .scaledFont(17)
                        .foregroundStyle(Palette.ink2)
                        .allowsHitTesting(false)
                }
                SpokenField(
                    text: $spoken,
                    font: UIFont(name: Fira.name(.regular, .default, condensed: false), size: 17)
                        ?? .systemFont(ofSize: 17),
                    // Zweiter Weg zum Diktat, dort wo die Tastatur ohnehin
                    // steht — bei grosser Schrift ist die Rosette nach oben
                    // aus dem Bild geschoben.
                    dictateTitle: dictation.isRunning
                        ? String(localized: "Diktat beenden")
                        : String(localized: "Diktat"),
                    dictateColor: dictation.isRunning ? roast.color : Palette.ink,
                    onDictate: {
                        if !dictation.isRunning {
                            beforeDictation = spoken.isEmpty ? "" : spoken + " "
                        }
                        dictation.toggle()
                    }
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 10)

            Rectangle().fill(Palette.rule).frame(height: 1).padding(.top, 10)

            Text(dictation.error
                 ?? (dictation.isRunning
                     ? String(localized: "Hört zu. Nochmal tippen beendet das Diktat.")
                     : String(localized: "Auf die Rosette tippen, um zu diktieren. Zeitangaben wie \u{201E}gestern Abend um neun\u{201C} werden übernommen; mehrere Gerichte werden einzeln erfasst.")))
                .scaledFont(11)
                .foregroundStyle(dictation.error == nil ? Palette.ink2 : roast.color)
                .padding(.top, 12)

            Spacer(minLength: 0)

            Button {
                dictation.stop()
                Task { await analyse(spoken) }
            } label: {
                Text("Schätzen")
                    .scaledFont(17, weight: .medium)
                    .textCase(.lowercase)
                    .foregroundStyle(Palette.paper)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 54)
                    .background(spoken.isEmpty ? Palette.ink2 : Palette.ink)
            }
            .buttonStyle(.plain)
            .disabled(spoken.isEmpty)
        }
        .onChange(of: dictation.transcript) { _, heard in
            guard dictation.isRunning else { return }
            spoken = beforeDictation + heard
        }
        .onDisappear { dictation.stop() }
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
                    .scaledFont(15)
                    .foregroundStyle(Palette.ink2)
                    .padding(.top, 20)
            }

            ProgressMatrix().padding(.top, 14)

            Text("Analysiere")
                .scaledFont(22, weight: .light)
                .textCase(.lowercase)
                .foregroundStyle(Palette.ink)
                .padding(.top, 18)
            Text(source)
                .scaledFont(13)
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
                .scaledFont(22, weight: .light)
                .textCase(.lowercase)
                .foregroundStyle(Palette.ink)
                .padding(.top, 20)

            // Anbieter und Modell mit dazu: ohne sie ist eine Fehlermeldung
            // nicht zuzuordnen, wenn zwoelf Dienste in Frage kommen.
            Text(provider.label + " · " + effectiveModel)
                .scaledFont(12, design: .monospaced)
                .foregroundStyle(Palette.ink2)
                .padding(.top, 6)

            ScrollView {
                Text(message)
                    .scaledFont(13)
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

    private func action(_ title: LocalizedStringKey, run: @escaping () -> Void) -> some View {
        Button(action: run) { rowLabel(title) }
            .buttonStyle(.plain)
            .overlay(alignment: .bottom) { Rectangle().fill(Palette.rule).frame(height: 1) }
    }

    private func rowLabel(_ title: LocalizedStringKey) -> some View {
        HStack {
            Text(title)
                .scaledFont(17, weight: .medium)
                .textCase(.lowercase)
                .foregroundStyle(Palette.ink)
            Spacer()
        }
        .frame(minHeight: 56)
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
                name: item.name.isEmpty ? String(localized: "Mahlzeit") : item.name,
                kind: .meal,
                kcal: item.kcal,
                caffeineMg: item.caffeineMg ?? 0,
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

    @AppStorage(Preference.roast) private var roastRaw = Roast.hell.rawValue
    @AppStorage(Preference.hand) private var handRaw = Hand.right.rawValue
    private var roast: Roast { Roast(rawValue: roastRaw) ?? .hell }
    private var hand: Hand { Hand(rawValue: handRaw) ?? .right }

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
        var caffeine = ""
        var date: Date?
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if drafts.count == 1 {
                    // Zwei Spalten: links die Zahlen, rechts Bild, Zeitpunkt
                    // und Bezeichnung. Bei mehreren Gerichten bleibt es bei
                    // den kompakten Zeilen — der Satzspiegel traegt **ein**
                    // Gericht, nicht drei nebeneinander.
                    // 244 = Bild 212 plus seine 32 pt Luft. Damit beginnen
                    // die Zahlen auf Höhe des Zeitpunkts, und oben links
                    // bleibt es leer.
                    SplitForm(leftOffset: 244) {
                        numbers
                    } right: {
                        VStack(alignment: .leading, spacing: 0) {
                            picture
                            timeField
                            nameField
                        }
                    }
                } else {
                    picture
                    timeField
                    ForEach($drafts) { $draft in compactRow($draft) }
                }

                // Ein Wert, der nicht stimmen kann, bekommt hier seinen Satz —
                // und zwar bevor gesichert wird, nicht danach. Der Knopf
                // darunter bleibt unberuehrt: es ist ein Hinweis, kein Riegel.
                PlausibilityNote(
                    kcal: drafts.map(\.kcal).max(by: { (Double($0) ?? 0) < (Double($1) ?? 0) }) ?? "",
                    caffeine: drafts.map(\.caffeine).max(by: { (Double($0) ?? 0) < (Double($1) ?? 0) }) ?? ""
                )

                // Der Knopf haengt unten, im Daumenbereich — dazwischen
                // steht der Weissraum, der den Satz traegt.
                Spacer(minLength: 24)

                Button { commit() } label: {
                    Text(drafts.count > 1 ? "\(drafts.count) Einträge sichern" : "Sichern")
                        .scaledFont(17, weight: .medium)
                        .textCase(.lowercase)
                        .foregroundStyle(Palette.paper)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 54)
                        .background(Palette.ink)
                }
                .buttonStyle(.plain)
                .padding(.top, 12)
            }
        }
        .scrollIndicators(.hidden)
        .onChange(of: grams) { _, _ in if per100g { rescale() } }
        .sheet(isPresented: $editingTime) {
            QuarterHourSheet(date: $when)
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Palette.paper)
        }
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
                    caffeine: estimate.caffeineMg.flatMap { $0 > 0 ? String(Int($0)) : nil } ?? "",
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
            // Quadratisch und so breit wie seine Spalte — im Entwurf ist es
            // genau das: 212,6 auf 212,8.
            // Der Rahmen kommt von `Color.clear`, das Bild haengt als Overlay
            // darin: ein `scaledToFill`-Bild als Rahmen meldet die
            // ueberstehende Groesse zurueck und macht die Spalte breiter als
            // die Seite. 212 ist die Kantenlaenge aus dem Entwurf.
            Color.clear
                .frame(height: 212)
                .frame(maxWidth: .infinity)
                .overlay {
                    Image(uiImage: shown).resizable().scaledToFill()
                }
                .clipped()
                // Oben rechts, wie am Eintrag — die einzige Ecke, in der
                // bei einem Essensfoto selten etwas Wichtiges steht.
                .overlay(alignment: .topTrailing) {
                    if image == nil {
                        Text("erzeugt")
                            .scaledFont(10).tracking(0.8)
                            .textCase(.lowercase)
                            .foregroundStyle(Palette.paper)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Palette.ink)
                            .padding(8)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 20)
        } else {
            // Ohne Bild bleibt der Platz **leer stehen**. Der Weissraum ist
            // Teil des Satzes, und er haelt die Felder unten rechts, wo der
            // Daumen sie erreicht — ohne ihn ruecken sie nach oben und die
            // Komposition kippt.
            // Feste Hoehe statt Seitenverhaeltnis: `Color` hat keine eigene
            // Groesse, und `aspectRatio` fiel im Scrollbereich auf die halbe
            // zusammen. 212 ist die Kantenlaenge aus dem Entwurf.
            Color.clear
                .frame(height: 212)
                .frame(maxWidth: .infinity)
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
        // Durch dasselbe `FormField` wie die Zahlen — sonst sitzt der Wert
        // enger unter seiner Beschriftung als nebenan und die Reihen der
        // beiden Spalten stehen versetzt.
        Button { editingTime = true } label: {
            FormField(label: "zeitpunkt") {
                Text(when.formatted(.dateTime.day().month().year().hour().minute()))
                    .scaledFont(24, weight: .light, condensed: true)
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onChange(of: when) { _, _ in timeTouched = true }
    }

    // MARK: - Felder

    /// Die linke Spalte: nur Zahlen, kurz und untereinander.
    @ViewBuilder private var numbers: some View {
        if let draft = $drafts.first {
            if per100g { number("menge · g", text: $grams) }
            // Koffein **zuoberst**, wo es vorkommt: bei einem Getraenk ist es
            // der Wert, um den es geht — die drei Kalorien einer Cola Zero
            // sind daneben eine Fussnote. Bei einem Teller Nudeln steht das
            // Feld gar nicht erst da.
            if !draft.caffeine.wrappedValue.isEmpty {
                number("koffein · mg", text: draft.caffeine, tint: roast.color)
            }
            number("kcal", text: draft.kcal)
            number("protein · g", text: draft.protein)
            number("kohlenhydrate · g", text: draft.carbs)
            number("fett · g", text: draft.fat)
        }
    }

    /// Die Bezeichnung steht rechts, wo sie Platz zum Umbrechen hat — und
    /// darunter, rechtsbuendig, der Weg zum erzeugten Bild.
    @ViewBuilder private var nameField: some View {
        if let draft = $drafts.first {
            VStack(alignment: .leading, spacing: 6) {
                Text("bezeichnung")
                    .scaledFont(11).tracking(0.8)
                    .foregroundStyle(Palette.ink2)
                TextField("", text: draft.name, axis: .vertical)
                    .scaledFont(24, weight: .light, condensed: true)
                    .foregroundStyle(Palette.ink)
                Rectangle().fill(Palette.rule).frame(height: 1)

                // Auch wenn schon ein erzeugtes Bild steht: das laesst sich
                // ersetzen, ein **Foto** nicht. Ein Foto ist ein Beleg; was
                // die App gezeichnet hat, ist eine Merkhilfe und darf neu
                // gezeichnet werden.
                if image == nil, #available(iOS 18.1, *) {
                    GenerateImageRow(
                        label: generated == nil ? "Bild erzeugen" : "Neues Bild erzeugen",
                        disabled: concept.isEmpty
                    ) { showPlayground = true }
                }
            }
            .padding(.bottom, 18)
        }
    }

    private func number(
        _ label: LocalizedStringKey,
        text: Binding<String>,
        tint: Color = Palette.ink
    ) -> some View {
        FormField(label: label, alignment: .trailing) {
            TextField("", text: text)
                .keyboardType(.decimalPad)
                .scaledFont(24, design: .monospaced)
                .foregroundStyle(tint)
        }
    }

    /// Name und kcal nebeneinander, mehr braucht die Durchsicht nicht. Die
    /// Makros sind gespeichert und stehen im Eintrag, falls sie stoeren.
    private func compactRow(_ draft: Binding<Draft>) -> some View {
        HStack(spacing: 12) {
            TextField("Gericht", text: draft.name)
                .scaledFont(17)
                .foregroundStyle(Palette.ink)
            TextField("0", text: draft.kcal)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .scaledFont(17, design: .monospaced)
                .foregroundStyle(Palette.ink)
                .frame(width: 70)
            Text("kcal")
                .scaledFont(11)
                .foregroundStyle(Palette.ink2)
            // Erkanntes Koffein steht mit dabei — sonst sieht man bei drei
            // Gerichten nicht, dass die Cola im mg-Band landet. Korrigieren
            // laesst es sich danach am Eintrag.
            if let mg = Double(draft.caffeine.wrappedValue), mg > 0 {
                Text("\(Int(mg)) mg")
                    .scaledFont(11, design: .monospaced)
                    .foregroundStyle(roast.color)
            }
        }
        .frame(minHeight: 52)
        .overlay(alignment: .bottom) { Rectangle().fill(Palette.rule).frame(height: 1) }
    }

    private func field(_ label: LocalizedStringKey, text: Binding<String>, mono: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .scaledFont(11).tracking(0.8)
                .foregroundStyle(Palette.ink2)
            TextField("", text: text)
                .keyboardType(mono ? .decimalPad : .default)
                .scaledFont(22, weight: .light, design: mono ? .monospaced : .default)
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
        drafts[0].caffeine = scaled(estimate.caffeineMg)
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
                caffeineMg: number(draft.caffeine),
                // Am Rad gedreht heisst: dieser Zeitpunkt gilt fuer alle.
                // Sonst behaelt jedes Gericht seinen eigenen, falls das Modell
                // mehrere genannt hat.
                date: timeTouched ? when : draft.date
            )
        }
        onSave(image ?? generated, image == nil && generated != nil, items, when)
    }
}

/// Eine Kachel der Erfassung: das Zeichen oben links, die Beschriftung unten
/// links, dieselbe Flaeche wie bei der Getraenkeauswahl.
///
/// Der Entwurf setzt die Beschriftung in zwei von drei Kacheln an den Fuss und
/// in der dritten direkt unter das Zeichen. Hier steht sie ueberall unten:
/// Kacheln nebeneinander, deren Zeilen auf einer Hoehe liegen, sind ruhiger
/// als solche, die es fast tun.
struct CaptureTile: View {
    let label: LocalizedStringKey
    /// Meist eines. „Beschreiben" traegt zwei — Stift und Mikrofon, und die
    /// Einstellungen tragen gar keines: dort ist die Kachel selbst der
    /// Hinweis, und ein Zeichen waere Zierat an der unwichtigeren Stelle.
    var marks: [DotArt] = []
    /// Aus dem Entwurf: 160 in der Erfassung, 120 und 60 in der Leiste unten.
    var height: CGFloat = 160

    static let gap: CGFloat = 4
    /// Kantenlaenge des Zeichens, ebenfalls aus dem Entwurf.
    private static let mark: CGFloat = 47

    var body: some View {
        // **Die Beschriftung traegt die Hoehe, das Zeichen liegt darueber.**
        // Vorher spannte ein `maxHeight: .infinity` die Kachel von innen auf,
        // damit ein Abstandhalter die Zeile nach unten schob — und weil das
        // nach jeder angebotenen Hoehe griff, wurde die halbhohe Kachel der
        // Einstellungen genauso hoch wie die daneben. Jetzt setzt `minHeight`
        // die Hoehe, und nur eine umbrechende Zeile laesst sie wachsen.
        Text(label)
            .scaledFont(24, weight: .light, condensed: true)
            .textCase(.lowercase)
            .foregroundStyle(Palette.ink)
            // „einstellungen" ist ein langes Wort. Bei grosser Schrift passt
            // es in keine halbe Spalte mehr, und SwiftUI bricht es dann
            // mitten durch: „einstellung / en". Lieber etwas kleiner setzen
            // als ein Wort zerschneiden.
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .frame(minHeight: height, alignment: .bottom)
            .overlay(alignment: .topLeading) {
                // Abstand null: `DotArt` zeichnet in ein Quadrat und laesst
                // links und rechts je zwei Einheiten Luft. Zwei Zeichen
                // stossen damit von selbst im Rastermass aneinander.
                HStack(spacing: 0) {
                    ForEach(Array(marks.enumerated()), id: \.offset) { _, zeichen in
                        zeichen.frame(width: Self.mark, height: Self.mark)
                    }
                }
                .padding(8)
            }
        .background(Palette.tile)
        .contentShape(Rectangle())
    }
}

/// Ein stiller Nebenweg unter einem Feld: rechtsbuendig, klein, mit Linie
/// darunter. Dieselbe Groesse und derselbe Schnitt wie „schliessen" in der
/// Kopfzeile — beides sind Nebenwege, keine Hauptsache.
struct QuietRow: View {
    let label: LocalizedStringKey
    var disabled = false
    let action: () -> Void

    var body: some View {
        // **Rechtsbuendig**, wie im Entwurf — und die Trefferflaeche trotzdem
        // ueber die ganze Spalte. Der Spacer stand vorher links vom Text und
        // schob ihn an den linken Rand.
        Button(action: action) {
            HStack {
                Spacer(minLength: 0)
                Text(label)
                    .scaledFont(12)
                    .textCase(.lowercase)
                    .foregroundStyle(disabled ? Palette.ink2 : Palette.ink)
            }
            .frame(minHeight: 46)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .overlay(alignment: .bottom) { Rectangle().fill(Palette.rule).frame(height: 1) }
    }
}

/// Dieselbe Zeile, aber nur wo Image Playground ueberhaupt laeuft — also wo
/// das Geraet Apple Intelligence hat.
@available(iOS 18.1, *)
struct GenerateImageRow: View {
    @Environment(\.supportsImagePlayground) private var supported
    /// „Neues Bild erzeugen", wo schon eins steht — sonst liest sich die
    /// Zeile, als gäbe es noch keins.
    var label: LocalizedStringKey = "Bild erzeugen"
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        if supported {
            QuietRow(label: label, disabled: disabled, action: action)
        }
    }
}

/// Apples Image Playground, hinter einer Verfuegbarkeitspruefung.
///
/// Bewusst das **Sheet** und nicht `ImageCreator`: die programmatische Variante
/// ist abgekuendigt und hoert in iOS 27 auf zu arbeiten. Das Sheet kostet einen
/// Tipp mehr, laeuft dafuer weiter — und sein Stil ist von Haus aus
/// zeichnerisch, ein erzeugtes Bild kann also nie fuer ein Foto gehalten werden.
struct PlaygroundSheet: ViewModifier {
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

/// Der Verlauf während der Schätzung — **im Raster des Zeitstrahls**.
///
/// Vorher war es eine einzelne Reihe, die sich von links füllte: ein
/// Segmentbalken, wie ihn jede App hat. Jetzt läuft eine diagonale Welle
/// durch ein Punktfeld, dieselben 96 Spalten wie oben auf dem Startscreen und
/// dieselbe Bewegung wie beim Wechsel der Dot-Matrix-Ziffern. Die App hat ein
/// Vokabular; ein Wartezeichen ist kein Grund, daraus auszubrechen.
///
/// Ein Balken, der sich füllt, verspricht ausserdem etwas, das er nicht
/// halten kann: wie lange ein Modell braucht, weiss hier niemand. Eine Welle
/// sagt nur „es läuft" — und genau das ist die Wahrheit.
private struct ProgressMatrix: View {
    /// Bewegung, nicht Fortschritt: wer sie abgestellt hat, bekommt ein
    /// Pulsieren an Ort und Stelle statt eines wandernden Bandes.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var phase: Double = 0

    private static let rows = 7
    /// Länge der Welle und Breite des leuchtenden Bandes darin, in Zellen der
    /// Diagonale.
    ///
    /// Das Band muss deutlich breiter sein als das Feld hoch ist, sonst
    /// bleibt vom Parallelogramm nur seine Spitze übrig: bei 9 zu 7 Reihen
    /// liefen Keile durch das Bild, keine Streifen.
    private static let period: Double = 44
    private static let band: Double = 20

    var body: some View {
        Canvas { ctx, size in
            let s = Grid.scale(forWidth: size.width)
            for row in 0..<Self.rows {
                for column in 0..<Grid.columns {
                    let rect = CGRect(
                        x: Grid.x(column) * s,
                        y: CGFloat(row) * Grid.pitch * s,
                        width: Grid.dot * s,
                        height: Grid.dot * s
                    )
                    ctx.fill(Path(rect), with: .color(lit(row: row, column: column) ? Palette.ink : Palette.matrix))
                }
            }
        }
        .aspectRatio(
            Grid.naturalWidth / (CGFloat(Self.rows - 1) * Grid.pitch + Grid.dot),
            contentMode: .fit
        )
        .opacity(reduceMotion ? 0.4 + 0.6 * abs(sin(phase / 6)) : 1)
        .task {
            // 24 Schritte je Sekunde: fein genug, dass die Welle fliesst, und
            // grob genug, dass das Zeichnen des Feldes nicht auffaellt.
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(42))
                phase += 1
            }
        }
        .accessibilityLabel("Analysiere")
    }

    /// Eine diagonale Welle: die Zelle leuchtet, solange die Front über ihr
    /// steht. `row + column` ist die Diagonale, der Rest ist Modulo.
    private func lit(row: Int, column: Int) -> Bool {
        guard !reduceMotion else { return (row + column) % 3 == 0 }
        let offset = (Double(row + column) - phase).truncatingRemainder(dividingBy: Self.period)
        let wrapped = offset < 0 ? offset + Self.period : offset
        return wrapped < Self.band
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
