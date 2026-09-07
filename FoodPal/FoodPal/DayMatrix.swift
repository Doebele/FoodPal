import SwiftUI

/// Der Tag als Punktraster: 24 Stundenspalten zu je drei Punkten Breite.
///
/// Oben zehn Reihen Kalorien zu je 200 kcal, unten drei Reihen Koffein zu
/// je 100 mg. Beide Bänder wachsen von der gemeinsamen Trennlinie aus
/// auseinander — Kalorien nach oben, Koffein nach unten.
///
/// Ein `Canvas` statt 936 Views: die Punkte sind eine Zeichnung, keine
/// Hierarchie.
struct DayMatrix: View {
    let entries: [Entry]
    var roast: Roast = .hell

    private static let calorieRows = 10
    private static let coffeeRows = 3
    private static let kcalPerRow: Double = 200
    private static let mgPerRow: Double = 100
    /// Beginn des Koffeinbandes in natürlichen Einheiten (10 Reihen + Abstand).
    private static let coffeeTop: CGFloat = 52
    private static let naturalHeight: CGFloat = 65

    var body: some View {
        Canvas { ctx, size in
            let s = Grid.scale(forWidth: size.width)
            let d = Grid.dot * s
            let lit = hourly

            func dot(column: Int, y: CGFloat, color: Color) {
                let rect = CGRect(x: Grid.x(column) * s, y: y * s, width: d, height: d)
                ctx.fill(Path(rect), with: .color(color))
            }

            for hour in 0..<24 {
                let calDots = Int((lit[hour].kcal / (Self.kcalPerRow / 3)).rounded())
                let cofDots = Int((lit[hour].mg / (Self.mgPerRow / 3)).rounded())

                // Kalorien: von der untersten Reihe nach oben
                for i in 0..<(Self.calorieRows * 3) {
                    let row = Self.calorieRows - 1 - i / 3
                    let col = hour * 3 + i % 3
                    dot(column: col,
                        y: CGFloat(row) * Grid.pitch,
                        color: i < calDots ? Palette.ink : Palette.ink3)
                }

                // Koffein: von der obersten Reihe nach unten
                for i in 0..<(Self.coffeeRows * 3) {
                    let row = i / 3
                    let col = hour * 3 + i % 3
                    dot(column: col,
                        y: Self.coffeeTop + CGFloat(row) * Grid.pitch,
                        color: i < cofDots ? roast.color : Palette.ink3)
                }
            }
        }
        .aspectRatio(Grid.naturalWidth / Self.naturalHeight, contentMode: .fit)
        .accessibilityLabel("Tagesverlauf als Punktraster")
    }

    private var hourly: [(kcal: Double, mg: Double)] {
        var out = Array(repeating: (kcal: 0.0, mg: 0.0), count: 24)
        let calendar = Calendar.current
        for entry in entries {
            let hour = min(23, max(0, calendar.component(.hour, from: entry.date)))
            out[hour].kcal += entry.kcal
            out[hour].mg += entry.caffeineMg
        }
        return out
    }
}

/// Gepunktete Trennlinie zwischen Diagramm und Anzeige — ein Punkt je
/// Stundengruppe, damit sie im selben Raster bleibt.
struct DottedRule: View {
    var body: some View {
        Canvas { ctx, size in
            let s = Grid.scale(forWidth: size.width)
            let d = Grid.dot * s
            for column in stride(from: 0, to: Grid.columns, by: 3) {
                let rect = CGRect(x: Grid.x(column) * s, y: 0, width: d, height: d)
                ctx.fill(Path(rect), with: .color(Palette.ink2))
            }
        }
        .aspectRatio(Grid.naturalWidth / Grid.dot, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

#Preview {
    let day = Calendar.current.startOfDay(for: .now)
    func at(_ hour: Int) -> Date { day.addingTimeInterval(TimeInterval(hour * 3600)) }
    return VStack(spacing: 16) {
        DayMatrix(entries: [
            Entry(date: at(7), name: "Espresso", kind: .coffee, kcal: 2, caffeineMg: 63),
            Entry(date: at(8), name: "Porridge", kind: .meal, kcal: 410),
            Entry(date: at(10), name: "Cappuccino", kind: .coffee, kcal: 74, caffeineMg: 63),
            Entry(date: at(12), name: "Bowl", kind: .meal, kcal: 620),
            Entry(date: at(15), name: "Espresso", kind: .coffee, kcal: 2, caffeineMg: 63),
            Entry(date: at(19), name: "Ofengemüse", kind: .meal, kcal: 741)
        ])
        DottedRule()
    }
    .padding(Metric.margin)
    .background(Palette.paper)
}
