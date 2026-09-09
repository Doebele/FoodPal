import SwiftUI
import SwiftData

/// Eintrag ansehen, ändern, löschen.
///
/// Löschen ist bewusst **nicht rot**: der Akzent gehört dem Koffein, ein
/// zweiter Signalton würde das System aufweichen. Die Sicherung liegt im
/// zweiten Schritt — Nachfrage statt Warnfarbe.
struct EntryDetailView: View {
    let entry: Entry

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(Preference.healthSync) private var healthSync = true
    @AppStorage(Preference.roast) private var roastRaw = Roast.hell.rawValue

    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var health = HealthKitSync()
    @State private var name = ""
    @State private var date = Date.now
    @State private var kcal = ""
    @State private var caffeine = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var askDelete = false
    @State private var editingTime = false
    @State private var loaded = false
    /// Nach dem Loeschen feuert `onDisappear` ebenfalls — ohne diese Marke
    /// schriebe das Sichern auf einen Eintrag, den es nicht mehr gibt.
    @State private var deleted = false
    @State private var showPlayground = false
    @State private var imageExpanded = false
    @State private var showLore = false

    private var roast: Roast { Roast(rawValue: roastRaw) ?? .hell }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollsWhenNeeded {
                VStack(alignment: .leading, spacing: 0) {
                    // Das Bild laeuft randlos ueber die ganze Breite und
                    // steht deshalb **ausserhalb** des Satzspiegels — anders
                    // als beim Bestaetigen, wo es in seiner Spalte sitzt.
                    picture

                    // Kein Versatz: die Zahlen beginnen auf **derselben
                    // Höhe** wie der Zeitpunkt rechts. Mit gleich grossen
                    // Werten auf beiden Seiten stehen damit die ersten
                    // Zeilen beider Spalten im selben Raster.
                    SplitForm {
                        numbers
                    } right: {
                        VStack(alignment: .leading, spacing: 0) {
                            timeField
                            nameField
                            // Löschen steht **unten** rechts, nicht direkt
                            // unter der Bezeichnung: der Weissraum dazwischen
                            // ist Teil des Satzes, und der seltenste Griff
                            // gehört am weitesten weg vom häufigsten.
                            //
                            // Einspaltig faellt es dagegen ans Ende — sonst
                            // stuende das Loeschen mitten im Formular,
                            // zwischen Bezeichnung und Naehrwerten.
                            if !typeSize.isAccessibilitySize {
                                Spacer(minLength: 40)
                                deleteSection
                            }
                        }
                        .frame(maxHeight: .infinity, alignment: .top)
                    }
                    .padding(.horizontal, Metric.margin)

                    if typeSize.isAccessibilitySize {
                        deleteSection.padding(.horizontal, Metric.margin)
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .background(Palette.paper)
        .task {
            guard !loaded else { return }
            load()
            loaded = true
        }
        // **Beim Verschwinden**, nicht beim Knopf: sonst gingen die
        // Aenderungen verloren, sobald man das Sheet nach unten wischt statt
        // „Fertig" zu tippen. Einen Abbrechen-Weg gibt es hier nicht — der
        // Screen bearbeitet an Ort und Stelle, und Loeschen hat seine eigene
        // Nachfrage.
        .onDisappear { persist() }
        .sheet(isPresented: $editingTime) {
            QuarterHourSheet(date: $date)
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Palette.paper)
        }
        .modifier(PlaygroundSheet(isPresented: $showPlayground, concept: name) { image in
            entry.photo = VisionEstimator.downscaled(image, maxEdge: 900)
            entry.generatedImage = true
        })
        .confirmationDialog(
            "Eintrag löschen?",
            isPresented: $askDelete,
            titleVisibility: .visible
        ) {
            Button("Löschen", role: .destructive) { remove() }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text(healthSync
                 ? "Der Eintrag wird auch aus Apple Health entfernt."
                 : "Der Eintrag wird gelöscht.")
        }
    }

    /// Dieselbe Kopfzeile wie die uebrigen Sheets, nur mit „Fertig" —
    /// samt Impuls beim Aufklappen.
    private var header: some View {
        SheetHeader(title: "Eintrag", action: "Fertig")
            .padding(.bottom, 16)
    }

    /// Die linke Spalte: nur Zahlen.
    @ViewBuilder private var numbers: some View {
        // Koffein **zuoberst**, wo es vorkommt: bei einem Getraenk ist es
        // der Wert, um den es geht — die drei Kalorien einer Cola Zero sind
        // daneben eine Fussnote. Und es steht bei jedem Eintrag, der welches
        // hat, nicht nur bei Kaffee.
        if entry.kind == .coffee || (Double(caffeine) ?? 0) > 0 {
            numberField("koffein · mg", text: $caffeine, tint: roast.color)
        }
        numberField("kcal", text: $kcal, tint: Palette.ink)
        numberField("protein · g", text: $protein, tint: Palette.ink)
        numberField("kohlenhydrate · g", text: $carbs, tint: Palette.ink)
        numberField("fett · g", text: $fat, tint: Palette.ink)
    }

    /// Die Bezeichnung steht rechts, wo sie Platz zum Umbrechen hat — bei
    /// „Bowl mit Lachs, Avocado, Bambussprossen …" sind das fuenf Zeilen.
    private var nameField: some View {
        VStack(alignment: .leading, spacing: 0) {
            FormField(label: "bezeichnung") {
                TextField("", text: $name, axis: .vertical)
                    .scaledFont(24, weight: .light, condensed: true)
                    .foregroundStyle(Palette.ink)
            }

            // Auch nachtraeglich: ein Eintrag ohne Bild bekommt hier eins,
            // aus seiner Bezeichnung. Und ein **erzeugtes** Bild laesst sich
            // ersetzen — ein Foto nicht. Ein Foto ist ein Beleg; was die App
            // gezeichnet hat, ist eine Merkhilfe und darf neu gezeichnet
            // werden, wenn der Wurf danebenging.
            if entry.photo == nil || entry.generatedImage, #available(iOS 18.1, *) {
                GenerateImageRow(
                    label: entry.photo == nil ? "Bild erzeugen" : "Neues Bild erzeugen",
                    disabled: name.isEmpty
                ) { showPlayground = true }
            }
        }
    }

    private var deleteSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle().fill(Palette.ink).frame(height: 1)
                .padding(.top, 40)
            Button {
                askDelete = true
            } label: {
                HStack {
                    Text("Eintrag löschen")
                        .scaledFont(17, weight: .medium)
                        .textCase(.lowercase)
                        .foregroundStyle(Palette.ink)
                    Spacer()
                }
                .frame(minHeight: 56)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            // Kein Hinweis unter dem Knopf: dass Health mit aufgeraeumt wird,
            // steht in der Nachfrage — und dort steht es rechtzeitig. Zweimal
            // dasselbe macht den Schirm nur unruhig.
        }
    }

    /// Das Bild zum Eintrag — bis hierher wurde es gespeichert und nirgends
    /// gezeigt.
    ///
    /// Ein **erzeugtes** Bild trägt seine Marke. Am Stil sieht man es ohnehin,
    /// Image Playground zeichnet und fotografiert nicht; aber in einem
    /// Tagebuch soll der Unterschied zwischen Beleg und Merkhilfe nachlesbar
    /// sein und nicht nur erkennbar.
    /// Warenkunde zur Sorte — nur bei Kaffee, und nur wo es sie gibt.
    private var lore: CoffeeInfo? {
        entry.kind == .coffee ? CoffeeInfo.of(entry.name) : nil
    }

    /// Erst das Foto, dann das mitgelieferte Bild der Sorte. Ist keins von
    /// beidem da, bleibt der Platz leer — der Weissraum ist Teil des Satzes.
    private var artwork: UIImage? {
        if let data = entry.photo, let image = UIImage(data: data) { return image }
        return lore?.image
    }

    @ViewBuilder private var picture: some View {
        if let image = artwork {
            // **Ein** Bild, kein Wechsel zwischen zweien: gespreizt wird der
            // Rahmen, und das Bild darin fuellt ihn in jedem Zwischenschritt
            // neu. Zwei Ansichten haetten sich ueberblendet statt zu wachsen.
            let aspect = max(image.size.width, 1) / max(image.size.height, 1)
            Color.clear
                .frame(height: imageExpanded ? Self.pageWidth / aspect : 220)
                .frame(maxWidth: .infinity)
                .overlay {
                    // `contentTransition(.identity)`: sonst blendet SwiftUI
                    // den Bildinhalt beim Groessenwechsel ueber, und das Bild
                    // wird mitten in der Bewegung fuer ein paar Bilder blass.
                    // Es soll wachsen, nicht flackern.
                    Image(uiImage: image).resizable().scaledToFill()
                        .contentTransition(.identity)
                }
                .clipped()
                .overlay(alignment: .topTrailing) { badge }
                // Erst aufgespreizt: dort ist Platz für den Satz, und zugeklappt
                // bleibt das Bild ein Bild.
                .overlay(alignment: .bottomTrailing) {
                    if imageExpanded, !showLore, lore != nil { loreButton }
                }
                .overlay { if showLore, let lore { loreCard(lore) } }
                // Ruhend so breit wie die rechte Spalte, gespreizt von Kante
                // zu Kante. Das Polster kommt **nach** dem Overlay: davor
                // haengt die Marke an der Kante des gepolsterten Rahmens,
                // also 156 pt weiter rechts — ausserhalb des Bildes.
                .padding(.leading, imageExpanded ? 0 : Metric.margin + FormGrid.rightInset)
                .padding(.trailing, imageExpanded ? 0 : Metric.margin)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(duration: 0.4, bounce: 0.35)) {
                        imageExpanded.toggle()
                        if !imageExpanded { showLore = false }
                    }
                }
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Vergrössert das Bild und verkleinert es wieder")
        } else {
            // Ohne Bild bleibt der Platz leer — derselbe Weissraum wie mit,
            // damit die Felder dort stehen, wo man sie erreicht.
            Color.clear
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.bottom, 24)
        }
    }

    /// Die Breite, auf die das Bild aufgespreizt wird. Die App steht nur im
    /// Hochformat und das Sheet nimmt die volle Breite — deshalb genuegt der
    /// Bildschirm, und ein `GeometryReader` bleibt draussen: der bringt genau
    /// diese Sheets zum Absturz.
    private static var pageWidth: CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
            .screen.bounds.width ?? 393
    }

    /// Das Info-Zeichen unten rechts — gegenüber der Marke oben rechts, damit
    /// sich die beiden nie ins Gehege kommen.
    private var loreButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) { showLore = true }
        } label: {
            DotArt.info(color: Palette.paper)
                .frame(width: 22, height: 22)
                .padding(5)
                .background(Palette.ink)
                .padding(8)
                // 32 pt Marke in einer 44 pt hohen Trefferfläche.
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Warenkunde")
    }

    /// Die Karte liegt **im** Bild, nicht darunter: das Bild bleibt sichtbar,
    /// nur unscharf. Ein Tippen darauf schliesst sie wieder.
    private func loreCard(_ lore: CoffeeInfo) -> some View {
        // **Nicht Ink und Ink2.** Auf Glas ist die Farbe unter dem Text
        // unbekannt, sie kommt aus dem Bild: Ink2 kam ueber dem Braun einer
        // Tasse auf 3,4 : 1, und `secondary` mit seiner Vibrancy sogar auf
        // 3,1 — beide unter der Schwelle von 4,5 : 1 fuer 11 pt. `primary`
        // haelt in beiden Modi, und das Etikett tritt ueber die Deckkraft
        // zurueck statt ueber die Farbe.
        VStack(alignment: .leading, spacing: 0) {
            Text("Zutaten")
                .scaledFont(11).tracking(0.8).textCase(.lowercase)
                .foregroundStyle(.primary.opacity(0.65))
            Text(lore.ingredients.map(\.label).joined(separator: " · "))
                .scaledFont(15)
                .textCase(.lowercase)
                .foregroundStyle(.primary)
                .padding(.top, 6)

            Text("Zubereitung")
                .scaledFont(11).tracking(0.8).textCase(.lowercase)
                .foregroundStyle(.primary.opacity(0.65))
                .padding(.top, 20)
            Text(lore.preparation)
                .scaledFont(15)
                .lineSpacing(3)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(Metric.margin)
        // `regularMaterial`, nicht `ultraThin`: über einem Foto — und diese
        // Bilder sind Fotos — bleibt vom dünnsten Glas zu wenig Kontrast für
        // 11-pt-Etiketten übrig. Glas bleibt es, nur eines, durch das man den
        // Satz noch lesen kann.
        .background(.regularMaterial)
        .contentShape(Rectangle())
        .onTapGesture { withAnimation(.easeInOut(duration: 0.25)) { showLore = false } }
        .transition(.opacity)
    }

    /// Die Marke sitzt **im** Bild, oben rechts — die einzige Ecke, in der
    /// bei einem Essensfoto selten etwas Wichtiges steht.
    @ViewBuilder private var badge: some View {
        if entry.generatedImage {
            Text("erzeugt")
                .scaledFont(10)
                .tracking(0.8)
                .textCase(.lowercase)
                .foregroundStyle(Palette.paper)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Palette.ink)
                .padding(8)
        }
    }

    /// Zeitpunkt statt nur Uhrzeit: so lassen sich Einträge nachtragen,
    /// die schon vorbei sind. Nach vorn ist bei jetzt Schluss — ein Eintrag
    /// in der Zukunft wäre unsichtbar, weil die Tagesansicht bei heute endet.
    ///
    /// Der Wert steht als schlichter Text wie jeder andere; erst beim
    /// Antippen klappt das Rad aus. Apples kompakter DatePicker bringt sonst
    /// eine graue Kastenpille mit, die es sonst nirgends gibt.
    ///
    /// Das Rad rastet in Viertelstunden — siehe `QuarterHourPicker`.
    private var timeField: some View {
        // Durch dasselbe `FormField` wie die Zahlen: der Abstand zwischen
        // Beschriftung und Wert war hier null statt sechs, und dadurch sassen
        // die Reihen der beiden Spalten versetzt.
        Button { editingTime = true } label: {
            FormField(label: "zeitpunkt") {
                Text(stamp)
                    .scaledFont(24, weight: .light, condensed: true)
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var stamp: String {
        let calendar = Calendar.current
        let day: String
        if calendar.isDateInToday(date) {
            day = String(localized: "Heute")
        } else if calendar.isDateInYesterday(date) {
            day = String(localized: "Gestern")
        } else {
            day = date.formatted(.dateTime.day().month(.abbreviated))
        }
        return day + " · " + date.formatted(date: .omitted, time: .shortened)
    }

    // MARK: - Bausteine

    private func field<Content: View>(
        _ label: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .scaledFont(11)
                .tracking(0.8)
                .foregroundStyle(Palette.ink2)
            content()
            Rectangle().fill(Palette.rule).frame(height: 1)
        }
        .padding(.bottom, 20)
    }

    private func numberField(_ label: LocalizedStringKey, text: Binding<String>, tint: Color) -> some View {
        FormField(label: label) {
            TextField("", text: text)
                .keyboardType(.decimalPad)
                .scaledFont(24, design: .monospaced)
                .foregroundStyle(tint)
        }
    }

    private func row<Value: View>(_ label: String, @ViewBuilder value: () -> Value) -> some View {
        HStack {
            Text(label)
                .scaledFont(11)
                .tracking(0.8)
                .foregroundStyle(Palette.ink2)
            Spacer()
            value()
        }
        .frame(minHeight: 48)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Palette.rule).frame(height: 1)
        }
        .padding(.bottom, 20)
    }

    // MARK: - Daten

    private func load() {
        name = entry.name
        date = entry.date
        kcal = format(entry.kcal)
        caffeine = format(entry.caffeineMg)
        protein = entry.proteinG.map(format) ?? ""
        carbs = entry.carbsG.map(format) ?? ""
        fat = entry.fatG.map(format) ?? ""
    }

    private func format(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(value)
    }

    private func parse(_ text: String) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: "."))
    }

    /// Übernimmt die Änderungen und schreibt sie **auch nach Health** —
    /// alte Samples löschen, neue anlegen. Sonst driftet Health von der
    /// App weg und niemand merkt es.
    private func persist() {
        // Ohne die Sperren schriebe ein Verschwinden vor dem Laden leere
        // Felder ueber den Eintrag — und eines nach dem Loeschen auf einen,
        // den es nicht mehr gibt.
        guard loaded, !deleted else { return }

        let changed = name != entry.name
            || date != entry.date
            || parse(kcal) != entry.kcal
            || parse(caffeine) != entry.caffeineMg
            || parse(protein) != entry.proteinG
            || parse(carbs) != entry.carbsG
            || parse(fat) != entry.fatG

        entry.name = name.trimmingCharacters(in: .whitespaces)
        entry.date = date
        entry.kcal = parse(kcal) ?? 0
        entry.caffeineMg = parse(caffeine) ?? 0
        entry.proteinG = parse(protein)
        entry.carbsG = parse(carbs)
        entry.fatG = parse(fat)

        if changed && healthSync {
            let old = entry.hkIDs
            Task {
                try? await health.delete(ids: old)
                entry.hkIDs = (try? await health.save(entry)) ?? []
            }
        }
    }

    private func remove() {
        deleted = true
        let ids = entry.hkIDs
        context.delete(entry)
        Task { try? await health.delete(ids: ids) }
        dismiss()
    }
}
