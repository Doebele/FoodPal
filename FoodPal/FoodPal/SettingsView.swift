import SwiftUI

/// Einstellungen als Sheet — mit Kopfzeile und Schliessen, wie die Erfassung.
struct SettingsSheet: View {
    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "Einstellungen")
            SettingsView()
        }
        .background(Palette.paper)
    }
}

struct SettingsView: View {
    @AppStorage(Preference.healthSync) private var healthSync = true
    @AppStorage(Preference.haptics) private var haptics = true
    @AppStorage(Preference.scaleText) private var scaleText = true
    @AppStorage(Preference.roast) private var roastRaw = Roast.hell.rawValue
    @AppStorage(Preference.numberStyle) private var styleRaw = NumberStyle.flip.rawValue
    @AppStorage(Preference.appearance) private var appearanceRaw = Appearance.auto.rawValue
    @AppStorage(Preference.provider) private var providerRaw = Provider.claude.rawValue

    @State private var health = HealthKitSync()
    @State private var authError: String?
    @State private var showVision = {
        #if DEBUG
        return ProcessInfo.processInfo.environment["START_VISION"] == "1"
        #else
        return false
        #endif
    }()

    /// Die Sprache, in der die App gerade laeuft — nicht die des Geraets:
    /// `preferredLocalizations` ist die Schnittmenge aus beidem, also das,
    /// was tatsaechlich auf dem Schirm steht. Der Name kommt in seiner
    /// eigenen Sprache und behaelt deren Schreibung („Deutsch", aber
    /// „francais" klein).
    private static var language: String {
        let code = Bundle.main.preferredLocalizations.first ?? "de"
        return Locale(identifier: code).localizedString(forLanguageCode: code) ?? code
    }

    private func open(_ address: String) {
        guard let url = URL(string: address) else { return }
        UIApplication.shared.open(url)
    }

    private var roast: Roast { Roast(rawValue: roastRaw) ?? .hell }
    private var style: NumberStyle { NumberStyle(rawValue: styleRaw) ?? .flip }
    private var appearance: Appearance { Appearance(rawValue: appearanceRaw) ?? .auto }
    private var provider: Provider { Provider(rawValue: providerRaw) ?? .claude }

    var body: some View {
        ScrollView {
            // Sortiert nach Häufigkeit, nicht nach Bedeutung: oben, woran man
            // öfter dreht, unten, was einmal eingerichtet wird und dann steht.
            //
            // 32 pt zwischen den Gruppen: der Weissraum macht die Gruppierung
            // sichtbar, ohne dass es dafür Rahmen oder Flächen bräuchte.
            VStack(alignment: .leading, spacing: 32) {
                group(spacing: 4) {
                    caption("akzent · röstung", value: roast.label.lowercased())
                    roastPicker
                }

                group(spacing: 4) {
                    caption("erscheinungsbild", value: appearance.label.lowercased())
                    appearancePicker
                }

                group(spacing: 12) {
                    caption("anzeige · ziffern", value: style.label.lowercased())
                    stylePicker
                }

                group(spacing: 0) {
                    caption("bedienung")
                    row("Haptik") {
                        Toggle("", isOn: $haptics)
                    }
                    // Aus nagelt die Schrift auf die Groesse fest, in der die
                    // Entwuerfe gesetzt sind. An ist Vorgabe: wer die Schrift
                    // groesser stellt, tut das aus einem Grund.
                    row("Schrift folgt dem System") {
                        Toggle("", isOn: $scaleText)
                    }
                    // Die Sprachwahl gehoert iOS, nicht der App: ein eigener
                    // Schalter koennte `Locale.current` nicht mitdrehen, und
                    // Datum und Monatsnamen liefen weiter der Geraetesprache
                    // nach. Die Zeile steht trotzdem hier — sonst sucht man
                    // sie in den Systemeinstellungen unter „Apps".
                    actionRow("Sprache der App", value: Self.language) {
                        open(UIApplication.openSettingsURLString)
                    }
                    // Der Weg steht daneben, weil der Sprung ihn nicht immer
                    // ganz geht: unter iOS 26 landet `openSettingsURLString`
                    // auch mal auf der Wurzel statt auf der Seite der App.
                    Text("iOS führt die Sprachwahl je App: Einstellungen → Apps → Cafcalog.")
                        .scaledFont(11)
                        .foregroundStyle(Palette.ink2)
                        .padding(.top, 8)
                }

                // Anbieter, Schlüssel, Modell und Adresse sind vier Felder, die
                // nur beim Einrichten gebraucht werden. Sie stehen deshalb hinter
                // einer Zeile statt dauerhaft zwischen den Schaltern.
                group(spacing: 0) {
                    caption("bildanalyse", value: provider.label)
                    actionRow("Anbieter und Modell") { showVision = true }
                }

                // Zuletzt: einmal verbunden, nie wieder angefasst. Der Zustand
                // steht im Gruppenkopf statt in einer eigenen Zeile — er wird
                // gelesen, nicht bedient, und spart so eine ganze Reihe.
                group(spacing: 0) {
                    caption(
                        "apple health",
                        value: health.status.label,
                        marker: health.status == .authorized
                    )
                    if health.status != .authorized {
                        actionRow("Mit Health verbinden") {
                            Task {
                                do { try await health.requestAuthorization() }
                                catch { authError = error.localizedDescription }
                            }
                        }
                    }
                    row("Sync") {
                        Toggle("", isOn: $healthSync)
                    }
                    row("Schreibt") {
                        Text("Kalorien · Koffein · Makros")
                            .scaledFont(16, condensed: true)
                            .foregroundStyle(Palette.ink)
                    }
                }

                // Zwei Bestandteile verlangen eine Nennung, und ein README
                // liegt dem Buendel nicht bei: Fira steht unter der SIL Open
                // Font License, die Naehrwerte von Open Food Facts unter der
                // ODbL. Beide Lizenzen wollen genannt sein, keine will einen
                // Fliesstext — deshalb zwei Zeilen, die den Text oeffnen.
                group(spacing: 0) {
                    caption("lizenzen")
                    actionRow("Fira Sans · Fira Mono", value: "SIL OFL 1.1") {
                        open("https://openfontlicense.org")
                    }
                    actionRow("Nährwerte", value: "Open Food Facts") {
                        open("https://opendatacommons.org/licenses/odbl/")
                    }
                    // Die OFL verlangt den Rechtevermerk, nicht nur den Namen
                    // der Lizenz.
                    Text("Fira © 2012–2015 The Mozilla Foundation und Telefonica S.A.")
                        .scaledFont(11)
                        .foregroundStyle(Palette.ink2)
                        .padding(.top, 8)
                }

                if let authError {
                    Text(authError)
                        .scaledFont(12)
                        .foregroundStyle(Palette.ink2)
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, Metric.margin)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .toggleStyle(InkToggle())
        .background(Palette.paper)
        .haptic(.selection, trigger: roastRaw)
        .sheet(isPresented: $showVision) {
            VisionSheet()
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
                .presentationBackground(Palette.paper)
        }
    }

    // MARK: - Erscheinungsbild

    /// Auch hier gilt: man wählt, was man sieht — nur zeigt das Feld jetzt
    /// dasselbe Punktraster wie Diagramm und Anzeige statt zweier Farbkacheln.
    /// Auf jedem Feld steht ein **A** in Punkten; der Grund darunter sagt den
    /// Modus. Auto teilt beide Gründe senkrecht und dreht das A auf der
    /// dunklen Hälfte um.
    private var appearancePicker: some View {
        // Drei gleiche Drittel, nicht an die Raender gedrueckt: das Bild sitzt
        // mittig in seinem Feld, und der schwarze Strich laeuft ueber die
        // ganze Spaltenbreite. Damit liest sich die Auswahl als Reihe
        // gleichwertiger Felder statt als drei einzeln gesetzte Objekte.
        HStack(spacing: 0) {
            ForEach(Appearance.allCases) { option in
                Button { appearanceRaw = option.rawValue } label: {
                    VStack(spacing: 10) {
                        AppearanceBlock(option: option)
                            .frame(height: 54)
                            // Im Dunkelmodus liegt der dunkle Grund fast auf
                            // dem Papier — ohne Haarlinie haette „dunkel" gar
                            // keine sichtbaren Kanten und stuende als
                            // schwebendes A neben zwei Bloecken.
                            .overlay(Rectangle().strokeBorder(Palette.rule, lineWidth: 1))
                        Text(option.label)
                            .scaledFont(12)
                            .tracking(0.4)
                            .textCase(.lowercase)
                            .foregroundStyle(option == appearance ? Palette.ink : Palette.ink2)
                        Rectangle()
                            .fill(option == appearance ? Palette.ink : .clear)
                            .frame(height: 3)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.label)
            }
        }
    }

    // MARK: - Ziffernstil

    /// Die Auswahl zeigt die **echte Darstellung**, kein Text-Etikett —
    /// man wählt, was man sieht.
    private var stylePicker: some View {
        HStack(spacing: 0) {
            // Drei gleiche Drittel, die Vorschau mittig darin. Alle drei
            // stehen zudem in **einem** 64 pt hohen Kasten: damit liegen
            // Beschriftung und schwarzer Strich auf einer Linie, egal wie hoch
            // die Vorschau selbst ist — die Segment-Acht ist 50, die
            // Flipkarte 64.
            //
            // Der frühere Versatz von −18 pt ist raus: er hat einen Fehler in
            // der Flipkarte ausgeglichen, die 28 pt unter ihrem eigenen Rahmen
            // zeichnete. Seit der Rahmen sitzt, war der Ausgleich doppelt.
            styleCell(.flip) { FlipCard(digit: 8).frame(height: 64) }
            styleCell(.sevenSegment) { SevenSegmentDigit(digit: 8).frame(height: 50) }
            styleCell(.dotMatrix) { DotMatrixDigit(digit: 8).frame(height: 64) }
        }
    }

    private func styleCell<Content: View>(
        _ target: NumberStyle,
        @ViewBuilder preview: () -> Content
    ) -> some View {
        let active = style == target
        return Button { styleRaw = target.rawValue } label: {
            VStack(spacing: 10) {
                preview().frame(height: 64)
                Text(target.label)
                    .scaledFont(12)
                    .tracking(0.4)
                    .textCase(.lowercase)
                    .foregroundStyle(active ? Palette.ink : Palette.ink2)
                    // Drei Spalten geben „7-Segment" bei den
                    // Bedienhilfen-Groessen nicht genug Platz; ohne diese
                    // Reserve brach es zu „7-Segme / nt".
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                Rectangle()
                    .fill(active ? Palette.ink : .clear)
                    .frame(height: 3)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Röstung

    /// Die Farbfelder sitzen im selben Punktraster wie Diagramm und Anzeige.
    private var roastPicker: some View {
        HStack(spacing: 0) {
            ForEach(Array(Roast.allCases.enumerated()), id: \.element.id) { index, candidate in
                if index > 0 { Spacer(minLength: 4) }
                Button { roastRaw = candidate.rawValue } label: {
                    // 34 hoch, das Seitenverhaeltnis macht daraus 49 breit —
                    // zehn Spalten mal sieben Reihen desselben Rasters.
                    VStack(spacing: 4) {
                        DotBlock(color: candidate.color)
                            .frame(height: 34)
                        Rectangle()
                            .fill(candidate == roast ? Palette.ink : .clear)
                            .frame(height: 3)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(candidate.label)
            }
        }
    }

}

/// Ein Farbfeld aus Punkten des gemeinsamen Rasters — 10 Spalten, 7 Reihen.
struct DotBlock: View {
    let color: Color
    var columns = 10
    var rows = 7

    var body: some View {
        Canvas { ctx, size in
            let s = size.width / (Grid.x(columns - 1) + Grid.dot)
            for r in 0..<rows {
                for c in 0..<columns {
                    let rect = CGRect(
                        x: Grid.x(c) * s,
                        y: CGFloat(r) * Grid.pitch * s,
                        width: Grid.dot * s,
                        height: Grid.dot * s
                    )
                    ctx.fill(Path(rect), with: .color(color))
                }
            }
        }
        .aspectRatio(
            (Grid.x(columns - 1) + Grid.dot) / (CGFloat(rows - 1) * Grid.pitch + Grid.dot),
            contentMode: .fit
        )
    }
}

#Preview {
    SettingsView().background(Palette.paper)
}

/// Bildanalyse als eigenes Sheet.
///
/// Anbieter, Schlüssel, Modell und Adresse braucht man einmal beim Einrichten
/// und danach nie wieder. Zwischen Haptik-Schalter und Röstung standen sie
/// dauerhaft im Weg — hier stehen sie, wenn man sie sucht.
struct VisionSheet: View {
    @AppStorage(Preference.provider) private var providerRaw = Provider.claude.rawValue
    @AppStorage(Preference.models) private var modelsJSON = "{}"
    @AppStorage(Preference.addresses) private var addressesJSON = "{}"

    @State private var apiKey = ""
    @State private var probeResult: String?
    @State private var probing = false
    @State private var models: [VisionEstimator.ListedModel] = []
    @State private var modelsNote: String?
    @State private var loadingModels = false
    @State private var showModels = false
    @State private var picks = 0

    private var provider: Provider { Provider(rawValue: providerRaw) ?? .claude }

    /// Schreibt in das JSON je Anbieter statt in einen gemeinsamen Wert — der
    /// Eintrag des vorherigen Dienstes bleibt dadurch unangetastet.
    private var modelField: Binding<String> {
        Binding(get: { PerProvider.value(modelsJSON, provider) },
                set: { modelsJSON = PerProvider.setting(modelsJSON, provider, $0) })
    }

    private var addressField: Binding<String> {
        Binding(get: { PerProvider.value(addressesJSON, provider) },
                set: { addressesJSON = PerProvider.setting(addressesJSON, provider, $0) })
    }

    /// Der Anzeigename der Gruppe steht hier und nicht am `Provider`: der
    /// kennt kein SwiftUI, und Bezeichnungen sind Sache der Ansicht.
    private static func title(for group: Provider.Group) -> LocalizedStringKey {
        switch group {
        case .onDevice: "auf dem gerät"
        case .hosted: "gehostet · mit schlüssel"
        case .selfRun: "selbst betrieben"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "Bildanalyse")

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Der aktive Dienst zuerst: Schluessel einsetzen und testen
                    // ist das Haeufige, den Anbieter wechseln das Seltene.
                    caption("aktiv", value: provider.label)
                        .padding(.top, 8)
                    providerFields

                    Text(hint)
                        .scaledFont(12)
                        .foregroundStyle(Palette.ink2)
                        .padding(.top, 20)

                    // Drei Gruppen statt einer langen Reihe: was es kostet und
                    // wohin das Bild geht, ist die Frage beim Einrichten.
                    ForEach(Array(Provider.Group.allCases.enumerated()), id: \.element) { index, group in
                        caption(Self.title(for: group))
                            .padding(.top, index == 0 ? 32 : 28)
                        list(Provider.allCases.filter { $0.group == group })
                    }
                }
                .padding(.horizontal, Metric.margin)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .background(Palette.paper)
        // Zaehler statt providerRaw: so quittiert auch die Modellwahl, und
        // das Tippen im Schluesselfeld loest nichts aus.
        .haptic(.selection, trigger: picks)
    }

    /// Eine Zeile je Dienst statt eines Umschalters: bei zwoelf Eintraegen
    /// passt keine Segmentleiste mehr, und die Adressen soll niemand abtippen.
    private func list(_ options: [Provider]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(options) { option in
                Button { select(option) } label: {
                    HStack {
                        Text(option.label)
                            .scaledFont(16, weight: option == provider ? .medium : .regular)
                            .foregroundStyle(option == provider ? Palette.ink : Palette.ink2)
                        Spacer()
                        marker(option)
                    }
                    .frame(minHeight: 48)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Palette.rule).frame(height: 1)
                }
            }
        }
    }

    /// Drei Zustaende in einem 9-pt-Quadrat, ohne ein Wort Erklaerung:
    /// **gefuellt** ist aktiv, **umrandet** ist eingerichtet — dorthin
    /// zurueckzuwechseln kostet kein neues Eintragen —, **nichts** heisst,
    /// dass noch ein Schluessel fehlt.
    @ViewBuilder private func marker(_ option: Provider) -> some View {
        if option == provider {
            Rectangle()
                .fill(Palette.ink)
                .frame(width: 9, height: 9)
        } else if option.isConfigured {
            // strokeBorder statt stroke: der Strich liegt innen, das Quadrat
            // misst damit wirklich 9 pt und sitzt buendig zum gefuellten.
            Rectangle()
                .strokeBorder(Palette.ink, lineWidth: 1)
                .frame(width: 9, height: 9)
        }
    }

    /// Wechseln loescht nichts. Schluessel, Modellname und Adresse liegen je
    /// Anbieter getrennt — wer einmal einen Dienst eingerichtet hat, findet ihn
    /// beim Zurueckwechseln unveraendert vor. Nur das Testergebnis gilt nicht
    /// mehr, das gehoerte dem vorherigen.
    private func select(_ option: Provider) {
        providerRaw = option.rawValue
        probeResult = nil
        picks += 1
    }

    /// Der Satz, der beim Einrichten fehlt: wo der Schluessel herkommt und
    /// dass die Liste kein Zaun ist.
    private var hint: AttributedString {
        let markdown: String
        if provider == .apple {
            return "Läuft auf dem Gerät: kein Schlüssel, keine Kosten, nichts "
                + "verlässt das Telefon. Schätzt allerdings nur aus "
                + "Beschreibungen — Fotos brauchen einen der Dienste unten."
        }
        if let page = provider.keyPage {
            markdown = "Schlüssel von [\(provider.keyPageLabel)](\(page.absoluteString)). "
                + "Modellnamen ändern sich; „Verbindung testen\" sagt, ob es den "
                + "eingetragenen noch gibt."
        } else {
            markdown = "Adresse ohne /chat/completions. Jeder Dienst, der die "
                + "OpenAI-API spricht, passt hier hinein — auch einer, der oben "
                + "nicht steht."
        }

        guard var text = try? AttributedString(markdown: markdown) else {
            return AttributedString(markdown)
        }
        // Der Akzent gehoert dem Koffein, auch hier: der Link ist Ink und
        // unterstrichen statt farbig. Die Bereiche vorher einsammeln — waehrend
        // des Laufs ueber runs darf der String nicht veraendert werden.
        for range in text.runs.filter({ $0.link != nil }).map(\.range) {
            text[range].foregroundColor = Palette.ink
            text[range].underlineStyle = .single
        }
        return text
    }

    // MARK: - Modellauswahl

    /// Den Namen abzutippen ist die schlechteste Art, ein Modell zu waehlen:
    /// die IDs sind lang, sie wandern, und der Dienst kennt sie ohnehin. Die
    /// Liste kommt deshalb aus derselben Abfrage, die auch der Verbindungstest
    /// benutzt — geladen wird sie erst beim Aufklappen, nicht auf Verdacht.
    @ViewBuilder private var modelList: some View {
        actionRow(loadingModels ? "Lädt …"
                  : showModels ? "Liste ausblenden"
                  : "Modelle vom Dienst laden") {
            showModels.toggle()
            if showModels, models.isEmpty { loadModels() }
        }

        if showModels {
            if let modelsNote {
                Text(modelsNote)
                    .scaledFont(12)
                    .foregroundStyle(Palette.ink2)
                    .padding(.vertical, 10)
            }

            // Ausgeblendet wird nur, was sich selbst als bildblind ausweist.
            // Wo der Dienst nichts dazu sagt, steht alles in der Liste — raten
            // waere schlimmer als eine Zeile zu viel.
            let choices = models.filter { $0.seesImages != false }
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(choices, id: \.self) { entry in
                    modelRow(entry.id)
                }
            }

            if choices.count < models.count {
                Text("\(models.count - choices.count) ohne Bildeingang ausgeblendet.")
                    .scaledFont(12)
                    .foregroundStyle(Palette.ink2)
                    .padding(.top, 10)
            }
        }
    }

    private func modelRow(_ id: String) -> some View {
        let active = PerProvider.value(modelsJSON, provider) == id
        return Button {
            modelField.wrappedValue = id
            probeResult = nil
            picks += 1
            showModels = false
        } label: {
            HStack {
                Text(id)
                    .scaledFont(14, design: .monospaced)
                    .foregroundStyle(active ? Palette.ink : Palette.ink2)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 12)
                Rectangle()
                    .fill(active ? Palette.ink : .clear)
                    .frame(width: 9, height: 9)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Palette.rule).frame(height: 1)
        }
    }

    private func loadModels() {
        Task {
            loadingModels = true
            modelsNote = nil
            do {
                models = try await VisionEstimator.models(
                    provider: provider,
                    baseURL: provider.address(from: addressesJSON)
                )
                if models.isEmpty { modelsNote = "Der Dienst nennt keine Modelle." }
            } catch {
                modelsNote = error.localizedDescription
            }
            loadingModels = false
        }
    }

    @ViewBuilder private var providerFields: some View {
        VStack(alignment: .leading, spacing: 0) {
            if provider.editableAddress {
                row("Adresse") {
                    TextField(provider.defaultAddress, text: addressField)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .multilineTextAlignment(.trailing)
                        .scaledFont(15, design: .monospaced)
                        .foregroundStyle(Palette.ink)
                }
            }

            if provider.hasModelChoice {
                row("API-Schlüssel") {
                    SecureField(provider.needsKey ? "nicht hinterlegt" : "optional", text: $apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.trailing)
                    .scaledFont(15, design: .monospaced)
                    .foregroundStyle(Palette.ink)
                    .onSubmit { storeKey() }
                        .onChange(of: apiKey) { _, _ in storeKey() }
                }

                row("Modell") {
                    TextField(provider.defaultModel.isEmpty ? "eintragen" : provider.defaultModel, text: modelField)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .multilineTextAlignment(.trailing)
                        .scaledFont(15, design: .monospaced)
                        .foregroundStyle(Palette.ink)
                }

                modelList
            }

            actionRow(probing ? "Prüfe …" : provider.hasModelChoice ? "Verbindung testen" : "Verfügbarkeit prüfen") {
                Task {
                    probing = true
                    probeResult = await VisionEstimator.probe(
                        provider: provider,
                        model: provider.model(from: modelsJSON),
                        baseURL: provider.address(from: addressesJSON)
                    )
                    probing = false
                }
            }

            if let probeResult {
                Text(probeResult)
                    .scaledFont(12)
                    .foregroundStyle(Palette.ink2)
                    .padding(.top, 8)
            }
        }
        .task(id: providerRaw) {
            apiKey = Keychain.get(provider.keychainAccount) ?? ""
            // Die Liste gehoerte dem vorherigen Dienst.
            models = []
            modelsNote = nil
            showModels = false
        }
    }

    /// Der Schlüssel geht in die Keychain, nicht in UserDefaults — und er
    /// verlässt das Gerät nur als Kopfzeile der Anfrage an den Anbieter.
    private func storeKey() {
        Keychain.set(apiKey, for: provider.keychainAccount)
    }

}

// MARK: - Bausteine, dateiweit

/// Gruppenkopf: **Beschriftung — Haarlinie — Wert.** Die Linie füllt, was
/// zwischen beiden übrig bleibt, und bindet sie damit zu einer Zeile
/// zusammen; vorher stand der Wert frei rechts und las sich wie ein zweites
/// Etikett. Der Wert spart die Zeile, die er sonst als eigene Reihe bräuchte
/// — bei Apple Health war das genau eine Zeile zu viel.
private func caption(
    _ title: LocalizedStringKey,
    value: String? = nil,
    marker: Bool? = nil
) -> some View {
    HStack(spacing: 0) {
        Text(title)
            .scaledFont(12)
            .tracking(0.4)
            .foregroundStyle(Palette.ink2)
            .fixedSize()
            .padding(.trailing, 8)

        Rectangle()
            .fill(Palette.ink2)
            .frame(height: 1)

        if value != nil || marker != nil {
            HStack(spacing: 8) {
                if let value {
                    Text(value)
                        .scaledFont(12)
                        .tracking(0.4)
                        .foregroundStyle(Palette.ink)
                        .fixedSize()
                }
                if let marker { Marke(filled: marker) }
            }
            .padding(.leading, 8)
        }
    }
    // 4 oben, 4 unten um eine 14 pt hohe Zeile — die 22 pt aus dem Entwurf.
    .padding(.vertical, 4)
}

/// Das kleine Quadrat neben einem Wert: leer heisst nein, gefüllt heisst ja.
/// Dieselbe Kodierung wie im Anbieterverzeichnis, wo eine eingerichtete
/// Verbindung ein gefülltes Quadrat trägt.
private struct Marke: View {
    let filled: Bool

    var body: some View {
        Rectangle()
            .fill(filled ? Palette.ink : .clear)
            .frame(width: 8, height: 8)
            .overlay(Rectangle().strokeBorder(Palette.ink, lineWidth: 1))
    }
}

/// Schalter im Satz der App.
///
/// Der eingebaute nimmt nur die Farbe der **Bahn** an und setzt darauf immer
/// einen weissen Knopf. Im Dunkelmodus ist die Bahn dann Ink — also fast
/// weiss — und der Knopf verschwindet darin: „an" las sich als leere Kapsel.
///
/// Hier ist der Knopf **immer Papier**, also stets das Gegenteil des Grundes,
/// und die Bahn sagt den Zustand: Ink für an, Ink2 für aus. Das stimmt in
/// beiden Modi, ohne dass eine Farbe eine Ausnahme braucht.
struct InkToggle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            withAnimation(.spring(duration: 0.25, bounce: 0.3)) {
                configuration.isOn.toggle()
            }
        } label: {
            ZStack {
                Capsule()
                    .fill(configuration.isOn ? Palette.ink : Palette.ink2)
                    .frame(width: 51, height: 31)
                Circle()
                    .fill(Palette.paper)
                    .frame(width: 27, height: 27)
                    .offset(x: configuration.isOn ? 10 : -10)
            }
            // 31 pt hohe Kapsel in einer 44 pt hohen Trefferflaeche.
            .frame(height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // Ein Schalter rastet ein — genau dort gehoert Haptik hin.
        .haptic(.selection, trigger: configuration.isOn)
        // Sonst meldet VoiceOver einen Knopf statt eines Schalters.
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
        }
    }
}

/// Eine Gruppe: Kopf, dann Inhalt. Der Abstand dazwischen ist je Gruppe
/// verschieden — die Punktfelder rücken näher an ihren Kopf als die
/// Zeilenlisten, weil sie sonst zu frei stünden.
private func group<Content: View>(
    spacing: CGFloat,
    @ViewBuilder content: () -> Content
) -> some View {
    VStack(alignment: .leading, spacing: spacing, content: content)
}

/// Zeile mit Wert oder Schalter. **Fira Sans Condensed Light** — schmaler als
/// der normale Schnitt, damit „Kalorien · Koffein · Makros" neben seiner
/// Beschriftung Platz hat, ohne dass eine der beiden abbricht.
private func row<Value: View>(_ label: LocalizedStringKey, @ViewBuilder value: () -> Value) -> some View {
    HStack {
        Text(label)
            .scaledFont(16, condensed: true)
            .textCase(.lowercase)
            .foregroundStyle(Palette.ink)
        Spacer(minLength: 8)
        value()
    }
    .frame(minHeight: 48)
    .overlay(alignment: .bottom) {
        Rectangle().fill(Palette.rule).frame(height: 1)
    }
}

/// Zeile, die etwas öffnet. Höher als eine Wertzeile (56 statt 48) und im
/// normalen Schnitt gesetzt: sie ist eine Handlung, keine Angabe.
private func actionRow(
    _ label: LocalizedStringKey,
    value: String? = nil,
    action: @escaping () -> Void
) -> some View {
    Button(action: action) {
        HStack {
            Text(label)
                .scaledFont(16)
                .textCase(.lowercase)
                .foregroundStyle(Palette.ink)
            Spacer(minLength: 8)
            // Der Wert wird gelesen, nicht gestellt — er steht deshalb im
            // ruhigeren Ton, wie die Angaben in den Gruppenkoepfen.
            if let value {
                Text(value)
                    .scaledFont(16, condensed: true)
                    .foregroundStyle(Palette.ink2)
            }
        }
        .frame(minHeight: 56)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .overlay(alignment: .bottom) {
        Rectangle().fill(Palette.rule).frame(height: 1)
    }
}
/// Untere linke Hälfte — die Diagonale, an der Auto seine beiden Modi teilt.
private struct LowerLeft: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Das Erscheinungsbild als Punktfeld: **12 Spalten, 11 Reihen**, in der Mitte
/// ein A aus Punkten.
///
/// Der Grund sagt den Modus — hell trägt ein dunkles A auf hellem Feld, dunkel
/// das Gegenteil, und Auto teilt die zwölf Spalten in der Mitte und dreht die
/// rechte Hälfte um. Damit ist die Auswahl im selben Raster gezeichnet wie
/// alles andere; die alten Farbkacheln mit ihrer Diagonale waren das einzige
/// Element der App, das aus dieser Systematik ausbrach.
struct AppearanceBlock: View {
    let option: Appearance

    static let columns = 12
    static let rows = 11

    /// Das A, Spalte für Spalte. Direkt aus dem Entwurf abgelesen.
    private static let glyph: [String] = [
        "000000000000",
        "000000000000",
        "000011110000",
        "000100001000",
        "000100001000",
        "000111111000",
        "000100001000",
        "000100001000",
        "000100001000",
        "000000000000",
        "000000000000"
    ]

    /// Auf der linken Hälfte gilt Hell, auf der rechten Dunkel — ausser der
    /// Modus schreibt beides vor.
    private func lightGround(column: Int) -> Bool {
        switch option {
        case .light: true
        case .dark: false
        case .auto: column < Self.columns / 2
        }
    }

    var body: some View {
        Canvas { ctx, size in
            let s = size.width / (Grid.x(Self.columns - 1) + Grid.dot)
            for row in 0..<Self.rows {
                let line = Array(Self.glyph[row])
                for column in 0..<Self.columns {
                    let light = lightGround(column: column)
                    let onGlyph = line[column] == "1"
                    // Auf dem Glyphen kippt die Farbe gegen den Grund.
                    let color = onGlyph
                        ? (light ? Palette.dotDark : Palette.dotLight)
                        : (light ? Palette.dotLight : Palette.dotDark)
                    let rect = CGRect(
                        x: Grid.x(column) * s,
                        y: CGFloat(row) * Grid.pitch * s,
                        width: Grid.dot * s,
                        height: Grid.dot * s
                    )
                    ctx.fill(Path(rect), with: .color(color))
                }
            }
        }
        .aspectRatio(
            (Grid.x(Self.columns - 1) + Grid.dot) / (CGFloat(Self.rows - 1) * Grid.pitch + Grid.dot),
            contentMode: .fit
        )
    }
}
