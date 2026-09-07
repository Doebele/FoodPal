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
    private var mode: DisplayMode { captureMode == Entry.Kind.coffee.rawValue ? .mg : .kcal }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: mode == .mg ? "Kaffee" : "Neue Mahlzeit")

            if mode == .mg {
                CoffeeCapture(roast: roast) { dismiss() }
            } else {
                PhotoCapture { dismiss() }
            }

            ModeToggle(mode: mode, roast: roast) { new in
                captureMode = new == .kcal ? Entry.Kind.meal.rawValue : Entry.Kind.coffee.rawValue
            }
            .padding(.top, 16)

            Text(mode == .mg ? "Auf kcal wechseln für Foto" : "Auf mg wechseln für Kaffee")
                .font(.system(size: 11))
                .foregroundStyle(Palette.ink2)
                .padding(.top, 10)
                .padding(.bottom, 12)
        }
        .background(Palette.paper)
    }
}

/// Getränkeauswahl. **Ein Tap genügt** — tippen sichert sofort mit
/// Standardportion und schließt das Sheet.
///
/// Die häufigsten Sorten stehen **unten**, entgegen der Leserichtung: dort
/// liegt der Daumen bei einhändiger Bedienung.
struct CoffeeCapture: View {
    let roast: Roast
    let onSaved: () -> Void

    @Environment(\.modelContext) private var context
    @Query private var all: [Entry]
    @AppStorage(Preference.healthSync) private var healthSync = true

    @State private var health = HealthKitSync()
    @State private var saves = 0

    private static let columns = 2
    private static let dots = 12
    private static let mgPerDot: Double = 160 / 12

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            caption
            // Das Raster hängt unten: die häufigsten Sorten sollen im
            // Daumenbereich liegen, nicht in der Mitte des Sheets.
            Spacer(minLength: 0)
            grid
        }
        .padding(.horizontal, Metric.margin)
        .haptic(trigger: saves)
    }

    /// Die Legende zeigt die Kodierung, statt sie zu beschreiben:
    /// kcal in Ink, Koffein im Akzent — genau wie in den Zellen.
    private var caption: some View {
        HStack(spacing: 0) {
            Text("häufigste unten")
                .foregroundStyle(Palette.ink2)
            Spacer()
            Text("kcal")
                .foregroundStyle(Palette.ink)
            Text(" · ")
                .foregroundStyle(Palette.ink2)
            Text("koffein")
                .foregroundStyle(roast.color)
        }
        .font(.system(size: 11))
        .tracking(0.8)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var grid: some View {
        let rows = ordered.chunked(into: Self.columns)
        return VStack(spacing: 0) {
            Rectangle().fill(Palette.rule).frame(height: 1)
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 0) {
                    ForEach(Array(row.enumerated()), id: \.element.id) { index, preset in
                        if index > 0 {
                            Rectangle().fill(Palette.rule).frame(width: 1)
                        }
                        cell(preset)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Palette.rule).frame(height: 1)
                }
            }
        }
    }

    private func cell(_ preset: CoffeePreset) -> some View {
        Button {
            save(preset)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(preset.name)
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    DotBar(lit: lit(for: preset), total: Self.dots, color: roast.color)
                        .frame(width: 52)
                    Spacer(minLength: 0)
                    Text("\(Int(preset.kcal))")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Palette.ink)
                    Text("\(Int(preset.caffeineMg))")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(roast.color)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(preset.name), \(Int(preset.caffeineMg)) Milligramm Koffein")
    }

    private func lit(for preset: CoffeePreset) -> Int {
        min(Self.dots, Int((preset.caffeineMg / Self.mgPerDot).rounded()))
    }

    /// Aufsteigend nach Nutzung der letzten 30 Tage — selten oben,
    /// häufig unten. Bei Gleichstand gilt die Reihenfolge der Vorlage.
    private var ordered: [CoffeePreset] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .distantPast
        var counts: [String: Int] = [:]
        for entry in all where entry.kind == .coffee && entry.date >= cutoff {
            counts[entry.name, default: 0] += 1
        }
        let fallback = Dictionary(
            uniqueKeysWithValues: CoffeePreset.all.enumerated().map { ($0.element.name, $0.offset) }
        )
        return CoffeePreset.all.sorted {
            let a = counts[$0.name] ?? 0
            let b = counts[$1.name] ?? 0
            if a != b { return a < b }
            return (fallback[$0.name] ?? 0) < (fallback[$1.name] ?? 0)
        }
    }

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

/// Balken aus Punkten des gemeinsamen Rasters — leuchtende zeigen die Menge.
struct DotBar: View {
    let lit: Int
    let total: Int
    let color: Color

    var body: some View {
        Canvas { ctx, size in
            let s = size.width / (Grid.x(total - 1) + Grid.dot)
            for index in 0..<total {
                let rect = CGRect(
                    x: Grid.x(index) * s, y: 0,
                    width: Grid.dot * s, height: Grid.dot * s
                )
                ctx.fill(Path(rect), with: .color(index < lit ? color : Palette.ink3))
            }
        }
        .aspectRatio((Grid.x(total - 1) + Grid.dot) / Grid.dot, contentMode: .fit)
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}
