import SwiftUI

/// Einstellungen als Sheet — mit Kopfzeile und Schliessen, wie die Erfassung.
struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Einstellungen")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(0.9)
                    .foregroundStyle(Palette.ink2)
                Spacer()
                Button("Schließen") { dismiss() }
                    .buttonStyle(.plain)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Palette.ink)
            }
            .padding(.horizontal, Metric.margin)
            .padding(.top, 20)
            .padding(.bottom, 8)

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
    @AppStorage(Preference.model) private var model = ""
    @AppStorage(Preference.localURL) private var localURL = ""

    @State private var health = HealthKitSync()
    @State private var authError: String?
    @State private var apiKey = ""
    @State private var probeResult: String?
    @State private var probing = false

    private var roast: Roast { Roast(rawValue: roastRaw) ?? .hell }
    private var style: NumberStyle { NumberStyle(rawValue: styleRaw) ?? .flip }
    private var appearance: Appearance { Appearance(rawValue: appearanceRaw) ?? .auto }
    private var provider: Provider { Provider(rawValue: providerRaw) ?? .claude }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                section("apple health", topPadding: 16) {
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

                section("bedienung", topPadding: 28) {
                    row("Haptik") {
                        Toggle("", isOn: $haptics)
                            .labelsHidden()
                            .tint(Palette.ink)
                    }
                }

                caption("bildanalyse", trailing: provider.label, topPadding: 28)
                providerPicker.padding(.top, 12)
                providerFields.padding(.top, 16)

                caption("erscheinungsbild", trailing: appearance.label, topPadding: 28)
                appearancePicker.padding(.top, 12)

                caption("anzeige · ziffern", trailing: style.label, topPadding: 28)
                stylePicker.padding(.top, 12)

                caption("akzent · röstung", trailing: roast.label, topPadding: 28)
                roastPicker.padding(.top, 12)
            }
            .padding(.horizontal, Metric.margin)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(Palette.paper)
        .haptic(.selection, trigger: roastRaw)
    }

    // MARK: - Bildanalyse

    private var providerPicker: some View {
        HStack(spacing: 0) {
            ForEach(Array(Provider.allCases.enumerated()), id: \.element.id) { index, option in
                if index > 0 {
                    Rectangle().fill(Palette.rule).frame(width: 1, height: 20)
                }
                Button {
                    providerRaw = option.rawValue
                    model = ""
                    apiKey = option.keychainAccount.flatMap(Keychain.get) ?? ""
                    probeResult = nil
                } label: {
                    VStack(spacing: 10) {
                        Text(option.label)
                            .font(.system(size: 13, weight: option == provider ? .medium : .regular))
                            .foregroundStyle(option == provider ? Palette.ink : Palette.ink2)
                        Rectangle()
                            .fill(option == provider ? Palette.ink : .clear)
                            .frame(height: 3)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder private var providerFields: some View {
        VStack(alignment: .leading, spacing: 0) {
            if provider.needsKey {
                row("API-Schlüssel") {
                    SecureField("nicht hinterlegt", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundStyle(Palette.ink)
                        .onSubmit { storeKey() }
                        .onChange(of: apiKey) { _, _ in storeKey() }
                }
            } else {
                row("Adresse") {
                    TextField("http://…:1234/v1", text: $localURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundStyle(Palette.ink)
                }
            }

            row("Modell") {
                TextField(provider.defaultModel, text: $model)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundStyle(Palette.ink)
            }

            actionRow(probing ? "Prüfe …" : "Verbindung testen") {
                Task {
                    probing = true
                    probeResult = await VisionEstimator.probe(provider: provider, baseURL: localURL)
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
            apiKey = provider.keychainAccount.flatMap(Keychain.get) ?? ""
        }
    }

    /// Der Schlüssel geht in die Keychain, nicht in UserDefaults — und er
    /// verlässt das Gerät nur als Kopfzeile der Anfrage an den Anbieter.
    private func storeKey() {
        guard let account = provider.keychainAccount else { return }
        Keychain.set(apiKey, for: account)
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

    // MARK: - Bausteine

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
        topPadding: CGFloat = 0,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            caption(title, topPadding: topPadding)
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
