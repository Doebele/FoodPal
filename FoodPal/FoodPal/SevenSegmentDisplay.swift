import SwiftUI

/// Ein Segment als Sechseck mit 6 pt Fase, im 74 × 116-Entwurfsraster.
///
/// Die Neigung wird **beim Bauen des Pfades** eingerechnet, nicht über
/// `transformEffect`: SwiftUI lässt das Layout dabei nicht mitwachsen, die
/// Anzeige liefe aus ihrem Rahmen, und die Scherung träfe auch Konturen.
/// So bleiben die Maße stimmig und `slant` ist animierbar.
struct Segment: Shape {
    let seg: CGRect
    var slant: CGFloat
    var chamfer: CGFloat = 6

    static let boxHeight: CGFloat = 116

    var animatableData: CGFloat {
        get { slant }
        set { slant = newValue }
    }

    func path(in bounds: CGRect) -> Path {
        let k = bounds.height / Self.boxHeight
        let c = chamfer
        let r = seg
        let points: [CGPoint] = r.width > r.height
            ? [.init(x: r.minX + c, y: r.minY), .init(x: r.maxX - c, y: r.minY),
               .init(x: r.maxX, y: r.midY),     .init(x: r.maxX - c, y: r.maxY),
               .init(x: r.minX + c, y: r.maxY), .init(x: r.minX, y: r.midY)]
            : [.init(x: r.midX, y: r.minY),     .init(x: r.maxX, y: r.minY + c),
               .init(x: r.maxX, y: r.maxY - c), .init(x: r.midX, y: r.maxY),
               .init(x: r.minX, y: r.maxY - c), .init(x: r.minX, y: r.minY + c)]

        var path = Path()
        for (i, q) in points.enumerated() {
            let p = CGPoint(x: (q.x + slant * (Self.boxHeight - q.y)) * k, y: q.y * k)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }
}

struct SevenSegmentDigit: View {
    let digit: Int
    var slant: CGFloat = SevenSegmentDisplay.slant
    var lit: Color = Palette.ink
    var unlit: Color = Palette.ink3

    /// Reihenfolge a, b, c, d, e, f, g — Maße aus dem Entwurf.
    static let segments: [CGRect] = [
        .init(x: 7, y: 0, width: 60, height: 12),    // a  oben
        .init(x: 62, y: 7, width: 12, height: 50),   // b  rechts oben
        .init(x: 62, y: 59, width: 12, height: 50),  // c  rechts unten
        .init(x: 7, y: 104, width: 60, height: 12),  // d  unten
        .init(x: 0, y: 59, width: 12, height: 50),   // e  links unten
        .init(x: 0, y: 7, width: 12, height: 50),    // f  links oben
        .init(x: 7, y: 52, width: 60, height: 12)    // g  Mitte
    ]

    private static let masks = [
        0b1111110, 0b0110000, 0b1101101, 0b1111001, 0b0110011,
        0b1011011, 0b1011111, 0b1110000, 0b1111111, 0b1111011
    ]

    private func isOn(_ index: Int) -> Bool {
        let mask = Self.masks[min(9, max(0, digit))]
        return mask & (1 << (6 - index)) != 0
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<7, id: \.self) { i in
                let on = isOn(i)
                Segment(seg: Self.segments[i], slant: slant)
                    .foregroundStyle(on ? lit : unlit)
                    // Angehende Segmente blenden schneller auf als ausgehende
                    // abklingen — das Nachleuchten echter Anzeigen.
                    .animation(
                        .easeInOut(duration: on ? 0.12 : 0.22)
                        .delay(Double(i) * 0.012),
                        value: digit
                    )
            }
        }
        .aspectRatio((74 + slant * 116) / 116, contentMode: .fit)
    }
}

/// Beim Wechsel der Stellenzahl — etwa von kcal auf mg — läuft die Anzeige
/// wie ein echtes Gerät: erst **auf null**, dann blendet die vierte Stelle
/// ein oder aus, dann steht der neue Wert. Ohne das schiebt SwiftUI die
/// Ziffern seitlich um, was nach Textlayout aussieht und nicht nach Anzeige.
///
/// Bleibt die Stellenzahl gleich, wird direkt übergeblendet — ein Zaehlwerk
/// nullt nicht, nur weil sich ein Wert ändert.
struct SevenSegmentDisplay: View {
    let value: Int
    var tint: Color = Palette.ink
    var slant: CGFloat = SevenSegmentDisplay.slant

    /// 0,0385 entspricht 2,2° — gemessen am Entwurf. LCD-Schriften liegen
    /// meist bei 5–8°, was schnell nach Taschenrechner wirkt.
    static let slant: CGFloat = 0.0385

    private static let blank: Double = 0.14
    private static let shift: Double = 0.20

    @State private var shown: [Int] = []

    var body: some View {
        // Eng gesetzt: die Ziffern sind schmal und lesen sich als Zahl besser,
        // wenn sie zusammenrücken. Die Neigung frisst ohnehin schon Abstand.
        HStack(spacing: 4) {
            ForEach(Array(shown.enumerated()), id: \.offset) { _, digit in
                SevenSegmentDigit(digit: digit, slant: slant, lit: tint)
                    .transition(.opacity)
            }
        }
        .task(id: value) { await run(to: Self.digits(of: value)) }
        .accessibilityElement()
        .accessibilityLabel("\(value)")
    }

    private func run(to target: [Int]) async {
        guard !shown.isEmpty else {
            shown = target
            return
        }
        guard shown.count != target.count else {
            withAnimation(.easeInOut(duration: Self.blank)) { shown = target }
            return
        }

        withAnimation(.easeInOut(duration: Self.blank)) {
            shown = Array(repeating: 0, count: shown.count)
        }
        try? await Task.sleep(for: .seconds(Self.blank + 0.04))

        withAnimation(.easeInOut(duration: Self.shift)) {
            shown = Array(repeating: 0, count: target.count)
        }
        try? await Task.sleep(for: .seconds(Self.shift + 0.04))

        withAnimation(.easeInOut(duration: Self.blank)) { shown = target }
    }

    private static func digits(of value: Int) -> [Int] {
        String(max(0, value)).compactMap(\.wholeNumberValue)
    }
}

#Preview {
    @Previewable @State var value = 1849
    return VStack(spacing: 32) {
        SevenSegmentDisplay(value: value).frame(height: 116)
        Button("kcal / mg") { value = value > 1000 ? 189 : 1849 }
    }
    .padding(Metric.margin)
    .background(Palette.paper)
}
