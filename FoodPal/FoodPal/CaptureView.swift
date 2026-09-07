import SwiftUI
import SwiftData

/// Die Erfassung folgt dem Modus, der auf dem Startscreen gesetzt wurde:
/// bei mg die Getränkeauswahl, bei kcal die Kamera. Der Umschalter unten
/// wechselt zwischen beidem.
struct CaptureView: View {
    @AppStorage(Preference.captureMode) private var captureMode = Entry.Kind.coffee.rawValue
    @AppStorage(Preference.roast) private var roastRaw = Roast.hell.rawValue

    private var roast: Roast { Roast(rawValue: roastRaw) ?? .hell }
    private var mode: DisplayMode { captureMode == Entry.Kind.coffee.rawValue ? .mg : .kcal }

    var body: some View {
        VStack(spacing: 0) {
            if mode == .mg {
                CoffeeCapture(roast: roast)
            } else {
                PlaceholderScreen(title: "Foto")
            }

            ModeToggle(mode: mode, roast: roast) { new in
                captureMode = new == .kcal ? Entry.Kind.meal.rawValue : Entry.Kind.coffee.rawValue
            }
            .padding(.top, 16)

            Text(mode == .mg ? "Auf kcal wechseln für Foto" : "Auf mg wechseln für Kaffee")
                .font(.system(size: 11))
                .foregroundStyle(Palette.ink2)
                .padding(.top, 10)
                .padding(.bottom, 8)
        }
        .background(Palette.paper)
    }
}

/// Getränkeauswahl. **Ein Tap genügt** — tippen sichert sofort mit
/// Standardportion; darunter erscheint eine schmale Zeile zum Zurücknehmen.
///
/// Die häufigsten Sorten stehen **unten**, entgegen der Leserichtung: dort
/// liegt der Daumen bei einhändiger Bedienung.
struct CoffeeCapture: View {
    let roast: Roast

    @Environment(\.modelContext) private var context
    @Query private var all: [Entry]
    @AppStorage(Preference.healthSync) private var healthSync = true

    @State private var health = HealthKitSync()
    @State private var last: Entry?
    @State private var saves = 0
    @State private var failure: String?

    private static let columns = 2

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            caption
            // Das Raster haengt unten: die haeufigsten Sorten sollen im
            // Daumenbereich liegen, nicht in der Bildschirmmitte.
            Spacer(minLength: 0)
            grid
            confirmation
        }
        .padding(.horizontal, Metric.margin)
        .haptic(trigger: saves)
        .task(id: saves) {
            guard saves > 0 else { return }
            try? await Task.sleep(for: .seconds(6))
            withAnimation { last = nil }
        }
    }

    private var caption: some View {
        HStack {
            Text("häufigste unten")
            Spacer()
            Text("punkte = koffein · zahl = kcal")
        }
        .font(.system(size: 11))
        .tracking(0.8)
        .foregroundStyle(Palette.ink2)
        .padding(.top, 12)
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
                        .frame(width: 58)
                    Spacer(minLength: 0)
                    Text("\(Int(preset.kcal))")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Palette.ink2)
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

    /// Statt „Bearbeiten": unmittelbar nach einem Fehltipp hilft
    /// Zurücknehmen, nicht ein Formular. Geändert wird der Eintrag später
    /// über die Tagesliste.
    @ViewBuilder private var confirmation: some View {
        if let entry = last {
            VStack(spacing: 0) {
                Rectangle().fill(Palette.ink).frame(height: 1)
                HStack {
                    Text("\(entry.name) gesichert")
                        .foregroundStyle(Palette.ink2)
                    Spacer()
                    Button("Rückgängig") { undo(entry) }
                        .buttonStyle(.plain)
                        .foregroundStyle(Palette.ink)
                        .font(.system(size: 13, weight: .medium))
                }
                .font(.system(size: 13))
                .padding(.top, 12)
            }
            .transition(.opacity)
        } else if let failure {
            Text(failure)
                .font(.system(size: 12))
                .foregroundStyle(Palette.ink2)
        }
    }

    // MARK: - Reihenfolge

    private static let dots = 12
    private static let mgPerDot: Double = 160 / 12

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

    // MARK: - Sichern

    private func save(_ preset: CoffeePreset) {
        let entry = preset.entry()
        context.insert(entry)
        withAnimation { last = entry }
        failure = nil
        saves += 1

        guard healthSync else { return }
        Task {
            do { entry.hkIDs = try await health.save(entry) }
            catch { failure = "Lokal gesichert, Health: \(error.localizedDescription)" }
        }
    }

    private func undo(_ entry: Entry) {
        let ids = entry.hkIDs
        context.delete(entry)
        withAnimation { last = nil }
        Task { try? await health.delete(ids: ids) }
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
