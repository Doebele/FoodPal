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

    private var roast: Roast { Roast(rawValue: roastRaw) ?? .hell }
    private var style: NumberStyle { NumberStyle(rawValue: styleRaw) ?? .flip }
    private var appearance: Appearance { Appearance(rawValue: appearanceRaw) ?? .auto }
    private var provider: Provider { Provider(rawValue: providerRaw) ?? .claude }

    var body: some View {
        ScrollView {
            // Sortiert nach Häufigkeit, nicht nach Bedeutung: oben, woran man
            // öfter dreht, unten, was einmal eingerichtet wird und dann steht.
            VStack(alignment: .leading, spacing: 0) {
                caption("akzent · röstung", trailing: roast.label, topPadding: 16)
                roastPicker.padding(.top, 12)

                caption("erscheinungsbild", trailing: appearance.label, topPadding: 28)
                appearancePicker.padding(.top, 12)

                caption("anzeige · ziffern", trailing: style.label, topPadding: 28)
                stylePicker.padding(.top, 12)

                section("bedienung", topPadding: 28) {
                    row("Haptik") {
                        Toggle("", isOn: $haptics)
                            .labelsHidden()
                            .tint(Palette.ink)
                    }
                }

                // Anbieter, Schlüssel, Modell und Adresse sind vier Felder, die
                // nur beim Einrichten gebraucht werden. Sie stehen deshalb hinter
                // einer Zeile statt dauerhaft zwischen den Schaltern.
                section("bildanalyse", trailing: provider.label, topPadding: 28) {
                    actionRow("Anbieter und Modell") { showVision = true }
                }

                // Zuletzt: einmal verbunden, nie wieder angefasst.
                section("apple health", topPadding: 28) {
                    row("Verbindung") {
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(health.status == .authorized ? Palette.ink : Palette.ink2)
                                .frame(width: 9, height: 9)
                            Text(health.status.rawValue)
                                .font(.system(size: 16))
                                .foregroundStyle(Palette.ink)
                        }
                    }
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
                            .labelsHidden()
                            .tint(Palette.ink)
                    }
                    row("Schreibt") {
                        Text("Kalorien · Koffein · Makros")
                            .font(.system(size: 16))
                            .foregroundStyle(Palette.ink2)
                    }
                }

                if let authError {
                    Text(authError)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.ink2)
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, Metric.margin)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
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

    /// Auch hier gilt: man wählt, was man sieht. Die Felder zeigen die
    /// Farben des jeweiligen Modus — Auto stellt beide nebeneinander.
    private var appearancePicker: some View {
        HStack(spacing: 0) {
            ForEach(Array(Appearance.allCases.enumerated()), id: \.element.id) { index, option in
                if index > 0 {
                    Rectangle().fill(Palette.rule).frame(width: 1, height: 44)
                }
                Button { appearanceRaw = option.rawValue } label: {
                    VStack(spacing: 10) {
                        swatch(option)
                        Text(option.label)
                            .font(.system(size: 11, weight: option == appearance ? .medium : .regular))
                            .foregroundStyle(option == appearance ? Palette.ink : Palette.ink2)
                        Rectangle()
                            .fill(option == appearance ? Palette.ink : .clear)
                            .frame(height: 3)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Auto zeigt **beide** Modi, diagonal geteilt. Zwei nebeneinander
    /// gelegte Papiertöne taugen dafür nicht: dunkles Papier ist genauso
    /// schwarz wie helle Tinte, damit sähe Auto aus wie Hell.
    private func swatch(_ option: Appearance) -> some View {
        let size = CGSize(width: 54, height: 34)
        return ZStack {
            pair(light: option != .dark)
            if option == .auto {
                pair(light: false).clipShape(LowerLeft())
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Palette.rule, lineWidth: 1))
    }

    private func pair(light: Bool) -> some View {
        HStack(spacing: 0) {
            Palette.fixed(light ? Palette.lightPaper : Palette.darkPaper)
            Palette.fixed(light ? Palette.lightInk : Palette.darkInk)
        }
    }

    // MARK: - Ziffernstil

    /// Die Auswahl zeigt die **echte Darstellung**, kein Text-Etikett —
    /// man wählt, was man sieht.
    private var stylePicker: some View {
        HStack(spacing: 0) {
            // Optischer Ausgleich: die massive Segment-Acht traegt schwerer
            // als die kleine Ziffer auf der Karte, deshalb kleiner gesetzt.
            styleCell(.flip) {
                FlipCard(digit: 8).frame(height: 64)
            }
            Rectangle().fill(Palette.rule).frame(width: 1, height: 64)
            styleCell(.sevenSegment) {
                SevenSegmentDigit(digit: 8).frame(height: 50)
            }
            Rectangle().fill(Palette.rule).frame(width: 1, height: 64)
            styleCell(.dotMatrix) {
                DotMatrixDigit(digit: 8).frame(height: 64)
            }
        }
    }

    private func styleCell<Content: View>(
        _ target: NumberStyle,
        @ViewBuilder preview: () -> Content
    ) -> some View {
        let active = style == target
        return Button { styleRaw = target.rawValue } label: {
            VStack(spacing: 10) {
                preview()
                Text(target.label)
                    .font(.system(size: 11, weight: active ? .medium : .regular))
                    .foregroundStyle(active ? Palette.ink : Palette.ink2)
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
        VStack(spacing: 8) {
            HStack(spacing: Grid.pitch) {
                ForEach(Roast.allCases) { candidate in
                    Button { roastRaw = candidate.rawValue } label: {
                        DotBlock(color: candidate.color)
                            .overlay(alignment: .bottom) {
                                Rectangle()
                                    .fill(candidate == roast ? Palette.ink : .clear)
                                    .frame(height: 3)
                                    .offset(y: 11)
                            }
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(candidate.label)
                }
            }
            .padding(.bottom, 11)
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

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "Bildanalyse")

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Der aktive Dienst zuerst: Schluessel einsetzen und testen
                    // ist das Haeufige, den Anbieter wechseln das Seltene.
                    caption("aktiv", trailing: provider.label, topPadding: 8)
                    providerFields

                    Text(hint)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.ink2)
                        .padding(.top, 20)

                    // Drei Gruppen statt einer langen Reihe: was es kostet und
                    // wohin das Bild geht, ist die Frage beim Einrichten.
                    ForEach(Array(Provider.Group.allCases.enumerated()), id: \.element) { index, group in
                        caption(group.rawValue, topPadding: index == 0 ? 32 : 28)
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
                            .font(.system(size: 16, weight: option == provider ? .medium : .regular))
                            .foregroundStyle(option == provider ? Palette.ink : Palette.ink2)
                        Spacer()
                        marker(option)
                    }
                    .frame(height: 48)
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
                    .font(.system(size: 12))
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
                    .font(.system(size: 12))
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
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(active ? Palette.ink : Palette.ink2)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 12)
                Rectangle()
                    .fill(active ? Palette.ink : .clear)
                    .frame(width: 9, height: 9)
            }
            .frame(height: 44)
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
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundStyle(Palette.ink)
                }
            }

            if provider.hasModelChoice {
                row("API-Schlüssel") {
                    SecureField(provider.needsKey ? "nicht hinterlegt" : "optional", text: $apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundStyle(Palette.ink)
                    .onSubmit { storeKey() }
                        .onChange(of: apiKey) { _, _ in storeKey() }
                }

                row("Modell") {
                    TextField(provider.defaultModel.isEmpty ? "eintragen" : provider.defaultModel, text: modelField)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 15, design: .monospaced))
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
                    .font(.system(size: 12))
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

private func caption(_ title: String, trailing: String? = nil, topPadding: CGFloat = 0) -> some View {
    HStack {
        Text(title)
            .font(.system(size: 11))
            .tracking(0.8)
            .foregroundStyle(Palette.ink2)
        Spacer()
        if let trailing {
            Text(trailing)
                .font(.system(size: 11))
                .tracking(0.8)
                .foregroundStyle(Palette.ink2)
        }
    }
    .padding(.top, topPadding)
    .overlay(alignment: .bottom) {
        Rectangle().fill(Palette.ink).frame(height: 1).offset(y: 12)
    }
    .padding(.bottom, 12)
}

private func section<Content: View>(
    _ title: String,
    trailing: String? = nil,
    topPadding: CGFloat = 0,
    @ViewBuilder content: () -> Content
) -> some View {
    VStack(alignment: .leading, spacing: 0) {
        caption(title, trailing: trailing, topPadding: topPadding)
        content()
    }
}

private func row<Value: View>(_ label: String, @ViewBuilder value: () -> Value) -> some View {
    HStack {
        Text(label)
            .font(.system(size: 16))
            .foregroundStyle(Palette.ink)
        Spacer()
        value()
    }
    .frame(height: 48)
    .overlay(alignment: .bottom) {
        Rectangle().fill(Palette.rule).frame(height: 1)
    }
}

private func actionRow(_ label: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Palette.ink)
            Spacer()
        }
        .frame(height: 48)
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
