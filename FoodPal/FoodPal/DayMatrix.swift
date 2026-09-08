import SwiftUI

/// Der Tag als Punktraster: 24 Stunden zu je vier Punkten Breite.
///
/// Oben zwölf Reihen Kalorien zu je 150 kcal, unten fünf Reihen Koffein zu
/// je 65 mg. Beide Bänder wachsen von der gemeinsamen Fuge aus auseinander —
/// Kalorien nach oben, Koffein nach unten.
///
/// **Die Koffein-Skala hat einen Anker:** eine Reihe ist ungefähr ein
/// Espresso. Drei Espresso in einer Stunde füllen damit knapp drei Reihen,
/// statt bei 100 mg je Reihe kaum zwei.
///
/// Ein `Canvas` statt 1632 Views: die Punkte sind eine Zeichnung, keine
/// Hierarchie.
struct DayMatrix: View {
    let entries: [Entry]
    var roast: Roast = .hell

    private static let calorieRows = 12
    private static let coffeeRows = 5
    private static let kcalPerRow: Double = 150
    private static let mgPerRow: Double = 65
    /// Beginn des Koffeinbandes: 12 Reihen (47) plus eine Reihe Fuge.
    private static let coffeeTop: CGFloat = 51
    private static let naturalHeight: CGFloat = 70

    var body: some View {
        Canvas { ctx, size in
            let s = Grid.scale(forWidth: size.width)
            let d = Grid.dot * s
            let lit = hourly

            func dot(column: Int, y: CGFloat, color: Color) {
                let rect = CGRect(x: Grid.x(column) * s, y: y * s, width: d, height: d)
                ctx.fill(Path(rect), with: .color(color))
            }

            let perDot = Grid.perHour
            for hour in 0..<24 {
                let calDots = Int((lit[hour].kcal / (Self.kcalPerRow / Double(perDot))).rounded())
                let cofDots = Int((lit[hour].mg / (Self.mgPerRow / Double(perDot))).rounded())

                // Kalorien: von der untersten Reihe nach oben
                for i in 0..<(Self.calorieRows * perDot) {
                    let row = Self.calorieRows - 1 - i / perDot
                    let col = hour * perDot + i % perDot
                    dot(column: col,
                        y: CGFloat(row) * Grid.pitch,
                        color: i < calDots ? Palette.ink : Palette.rule)
                }

                // Koffein: von der obersten Reihe nach unten
                for i in 0..<(Self.coffeeRows * perDot) {
                    let row = i / perDot
                    let col = hour * perDot + i % perDot
                    dot(column: col,
                        y: Self.coffeeTop + CGFloat(row) * Grid.pitch,
                        color: i < cofDots ? roast.color : Palette.rule)
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
    }
    .padding(Metric.margin)
    .background(Palette.paper)
}
