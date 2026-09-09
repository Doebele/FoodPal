import SwiftUI
import SwiftData

/// Die Erfassung ist ein Bottom Sheet, kein Tab-Ziel: sie kommt von unten,
/// erledigt eine Sache und verschwindet wieder. Der Modus vom Startscreen
/// bestimmt, womit sie öffnet — bei mg die Getränkeauswahl, bei kcal die
/// Kamera. Der Umschalter unten wechselt zwischen beidem.
struct CaptureSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Preference.captureMode) private var captureMode = Entry.Kind.coffee.rawValue
    @AppStorage(Preference.roast) private var roastRaw = Roast.hell.rawValue

    private var roast: Roast { Roast(rawValue: roastRaw) ?? .hell }

    private var mode: DisplayMode {
        #if DEBUG
        // Erlaubt einen Screenshot der Mahlzeit-Erfassung, ohne den
        // gespeicherten Modus des Geraets anzufassen.
        if ProcessInfo.processInfo.environment["START_MEAL"] == "1" { return .kcal }
        #endif
        return captureMode == Entry.Kind.coffee.rawValue ? .mg : .kcal
    }

    var body: some View {
        VStack(spacing: 0) {
            // Der Kopf bleibt stehen: „Schließen" muss erreichbar sein, auch
            // wenn der Rest bei grosser Schrift unter den Rand laeuft.
            SheetHeader(title: mode == .mg ? "Kaffee" : "Neue Mahlzeit")

            if mode == .mg {
                // Die Getränkeauswahl **scrollt selbst**: ihre Legende bleibt
                // oben stehen, der Umschalter unten. Ein Scrollbereich um
                // alles herum nähme beides mit.
                CoffeeCapture(roast: roast) { dismiss() }
                switcher
            } else {
                ScrollsWhenNeeded {
                    VStack(spacing: 0) {
                        PhotoCapture { dismiss() }
                        switcher
                    }
                }
            }
        }
        .background(Palette.paper)
    }

    private var switcher: some View {
        VStack(spacing: 0) {
            ModeToggle(mode: mode, roast: roast) { new in
                captureMode = new == .kcal
                    ? Entry.Kind.meal.rawValue
                    : Entry.Kind.coffee.rawValue
            }
            .padding(.top, 16)

            Text(mode == .mg
                 ? "Für Mahlzeiten auf kcal wechseln"
                 : "Für Kaffee auf mg wechseln")
                .scaledFont(11)
                .foregroundStyle(Palette.ink2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Metric.margin)
                .padding(.top, 10)
                .padding(.bottom, 12)
        }
    }
}

/// Getränkeauswahl. **Ein Tap genügt** — tippen sichert sofort mit
/// Standardportion und schließt das Sheet.
///
/// Vierzig Sorten in **drei Stufen**, gefüllt von **unten rechts**: dort liegt
/// der Daumen, und dort steht, was am häufigsten getippt wird. Zwei grosse
/// Kacheln unten tragen ihre Zahlen ausgeschrieben, sechs mittlere darüber
/// zeigen dieselben Werte nur noch als Punktfeld, alle übrigen stehen klein
/// darüber und laufen beim Scrollen hinter der Legende durch.
///
/// Die Stufen sind nicht gesetzt, sie werden gelernt: gezählt wird über den
/// ganzen Bestand, bei Gleichstand entscheidet, was zuletzt getrunken wurde.
struct CoffeeCapture: View {
    let roast: Roast
    let onSaved: () -> Void

    @Environment(\.modelContext) private var context
    @Query private var all: [Entry]
    @AppStorage(Preference.healthSync) private var healthSync = true

    @State private var health = HealthKitSync()
    @State private var saves = 0

    private static let bigCount = 2
    private static let midCount = 6
    private static let columns = 4
    private static let gap: CGFloat = 4
    private static let legendHeight: CGFloat = 42

    /// Ein Punkt trägt 20 kcal und 13,3 mg. Der Koffeinwert ist der aus dem
    /// Rest der App (160 mg auf zwölf Punkte); die Kalorienskala ist auf
    /// Kaffee gerechnet — 24 Punkte reichen bis 480 kcal, und dort endet,
    /// was in einer Tasse landen kann.
    private static let kcalPerDot: Double = 20
    private static let mgPerDot: Double = 160 / 12

    var body: some View {
        ScrollView {
            VStack(spacing: Self.gap) {
                ForEach(Array(smallGrid.enumerated()), id: \.offset) { _, line in
                    tileRow(line, tile: .small)
                }
                ForEach(Array(midGrid.enumerated()), id: \.offset) { _, line in
                    tileRow(line, tile: .medium)
                }
                tileRow(bigRow, tile: .large)
            }
            .padding(.horizontal, Metric.margin)
            .padding(.bottom, Self.gap)
        }
        .scrollIndicators(.hidden)
        // Beim Öffnen steht die häufigste Sorte unten und damit im Daumen.
        .defaultScrollAnchor(.bottom)
        // Der Inhalt beginnt unter der Legende und läuft beim Scrollen
        // dahinter durch — deshalb Rand statt Abstand.
        .contentMargins(.top, Self.legendHeight, for: .scrollContent)
        .overlay(alignment: .top) { legend }
        // **Dynamic Type endet hier bei `large`.** Der Entwurf steht auf
        // festen Kachelmassen — 83 auf 80 für die kleinen —, und bei den
        // Bedienhilfen-Grössen bliebe davon nur Abschneiden übrig. Kleiner
        // gestellt wird weiterhin mitgemacht; gedeckelt ist nur nach oben.
        .dynamicTypeSize(...DynamicTypeSize.large)
        .haptic(trigger: saves)
    }

    /// Die Legende steht fest und trägt Glas: die Kacheln laufen darunter
    /// durch, statt an ihr abgeschnitten zu werden.
    private var legend: some View {
        HStack(spacing: 0) {
            Text("häufigste unten")
                .foregroundStyle(Palette.ink2)
            Spacer(minLength: 8)
            Text("kcal")
                .foregroundStyle(Palette.ink)
            Text(" · ")
                .foregroundStyle(Palette.ink2)
            Text("koffein")
                .foregroundStyle(roast.color)
        }
        .scaledFont(12)
        .textCase(.lowercase)
        .padding(.horizontal, Metric.margin)
        .frame(maxWidth: .infinity)
        .frame(height: Self.legendHeight)
        // **Papier, nicht Systemgrau.** `ultraThinMaterial` allein bringt
        // seinen eigenen kühlen Ton mit — die Zeile stand dann grau neben der
        // Kopfzeile darüber. Eine Papierwäsche darauf nimmt ihn heraus; das
        // Glas darunter bleibt und lässt die Kacheln verschwimmen, die
        // hindurchlaufen.
        .background {
            Palette.paper.opacity(0.86)
                .background(.ultraThinMaterial)
        }
    }

    // MARK: - Kacheln

    private enum Tile {
        case small, medium, large

        var height: CGFloat { self == .large ? 160 : 80 }
        var nameSize: CGFloat {
            switch self {
            case .small: 12
            case .medium: 20
            case .large: 32
            }
        }
        /// Reihen je Band: die grosse Kachel hat Platz für fünf, die anderen
        /// für zwei.
        var rows: Int { self == .large ? 5 : 2 }
    }

    private func tileRow(_ line: [CoffeePreset?], tile: Tile) -> some View {
        HStack(spacing: Self.gap) {
            ForEach(Array(line.enumerated()), id: \.offset) { _, preset in
                if let preset {
                    cell(preset, tile: tile)
                } else {
                    // Die oberste Zeile bleibt links leer: gefüllt wird von
                    // unten rechts, also fehlt oben links das Letzte.
                    Color.clear.frame(maxWidth: .infinity)
                }
            }
        }
        .frame(height: tile.height)
    }

    private func cell(_ preset: CoffeePreset, tile: Tile) -> some View {
        Button {
            save(preset)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                values(preset, tile: tile)
                Spacer(minLength: 4)
                Text(preset.name)
                    .scaledFont(tile.nameSize, weight: .light)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(tile == .small ? 3 : 2)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Palette.tile)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(preset.name), \(Int(preset.kcal)) Kilokalorien, \(Int(preset.caffeineMg)) Milligramm Koffein")
    }

    /// Die Werte: auf der grossen Kachel ausgeschrieben, sonst nur als Feld.
    @ViewBuilder private func values(_ preset: CoffeePreset, tile: Tile) -> some View {
        VStack(alignment: .leading, spacing: Self.gap) {
            if tile == .large {
                HStack(spacing: Self.gap) {
                    dots(preset.kcal, per: Self.kcalPerDot, rows: tile.rows, color: Palette.ink)
                    Text("\(Int(preset.kcal))")
                        .scaledFont(20, design: .monospaced)
                        .foregroundStyle(Palette.ink)
                }
                HStack(spacing: Self.gap) {
                    dots(preset.caffeineMg, per: Self.mgPerDot, rows: tile.rows, color: roast.color)
                    Text("\(Int(preset.caffeineMg))")
                        .scaledFont(20, design: .monospaced)
                        .foregroundStyle(roast.color)
                }
            } else {
                dots(preset.kcal, per: Self.kcalPerDot, rows: tile.rows, color: Palette.ink)
                dots(preset.caffeineMg, per: Self.mgPerDot, rows: tile.rows, color: roast.color)
            }
        }
    }

    /// Zwölf Spalten im Raster des Tagesdiagramms: Punkt 3 pt, Teilung 4 und
    /// 4,33. Gefüllt wird zeilenweise von links.
    private func dots(_ value: Double, per: Double, rows: Int, color: Color) -> some View {
        let total = rows * 12
        let lit = min(total, Int((value / per).rounded(.up)))
        return Canvas { ctx, _ in
            for index in 0..<total {
                let rect = CGRect(
                    x: CGFloat(index % 12) * 4, y: CGFloat(index / 12) * 4.33,
                    width: 3, height: 3
                )
                ctx.fill(Path(rect), with: .color(index < lit ? color : Palette.ink3))
            }
        }
        .frame(width: 47, height: CGFloat(rows) * 4.33 - 1.33)
        .accessibilityHidden(true)
    }

    // MARK: - Reihenfolge

    /// Häufigste zuerst. Gezählt wird über den **ganzen** Bestand, nicht über
    /// dreissig Tage: die Stufen sollen stehen und nicht wöchentlich tauschen.
    /// Bei Gleichstand zählt, was zuletzt getrunken wurde, danach die
    /// Reihenfolge der Vorlage.
    private var ranked: [CoffeePreset] {
        var counts: [String: Int] = [:]
        var last: [String: Date] = [:]
        for entry in all where entry.kind == .coffee {
            counts[entry.name, default: 0] += 1
            if entry.date > (last[entry.name] ?? .distantPast) { last[entry.name] = entry.date }
        }
        let fallback = Dictionary(
            uniqueKeysWithValues: CoffeePreset.all.enumerated().map { ($0.element.name, $0.offset) }
        )
        return CoffeePreset.all.sorted { a, b in
            let ca = counts[a.name] ?? 0, cb = counts[b.name] ?? 0
            if ca != cb { return ca > cb }
            let la = last[a.name] ?? .distantPast, lb = last[b.name] ?? .distantPast
            if la != lb { return la > lb }
            return (fallback[a.name] ?? 0) < (fallback[b.name] ?? 0)
        }
    }

    /// Zwei grosse: die häufigste **rechts**.
    private var bigRow: [CoffeePreset?] {
        let two = Array(ranked.prefix(Self.bigCount))
        return [two.count > 1 ? two[1] : nil, two.first]
    }

    private var midGrid: [[CoffeePreset?]] {
        grid(Array(ranked.dropFirst(Self.bigCount).prefix(Self.midCount)), columns: 2, rows: 3)
    }

    private var smallGrid: [[CoffeePreset?]] {
        let rest = Array(ranked.dropFirst(Self.bigCount + Self.midCount))
        let rows = max(1, Int((Double(rest.count) / Double(Self.columns)).rounded(.up)))
        return grid(rest, columns: Self.columns, rows: rows)
    }

    /// Füllt von **unten rechts** nach oben links — die Reihenfolge, in der
    /// die Liste gelesen wird, wenn der Daumen unten liegt.
    private func grid(_ items: [CoffeePreset], columns: Int, rows: Int) -> [[CoffeePreset?]] {
        var field = Array(
            repeating: [CoffeePreset?](repeating: nil, count: columns),
            count: rows
        )
        var index = 0
        for row in stride(from: rows - 1, through: 0, by: -1) {
            for column in stride(from: columns - 1, through: 0, by: -1) where index < items.count {
                field[row][column] = items[index]
                index += 1
            }
        }
        return field
    }

    // MARK: - Sichern

    private func save(_ preset: CoffeePreset) {
        let entry = preset.entry()
        context.insert(entry)
        saves += 1

        if healthSync {
            Task { entry.hkIDs = (try? await health.save(entry)) ?? [] }
        }

        // Kurz warten, damit der Impuls noch ankommt, bevor das Sheet geht —
        // ein sofortiges Schließen fühlt sich abgeschnitten an.
        Task {
            try? await Task.sleep(for: .milliseconds(120))
            onSaved()
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}
