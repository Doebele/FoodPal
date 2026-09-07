import SwiftUI

/// Flipkarte nach dem Vorbild der Braun-Klappuhr: helle Karte, dunkle Ziffer,
/// Fuge auf halber Höhe, Achsnocken an den Flanken.
///
/// Der Klappschritt läuft in zwei Hälften: das Blatt mit der **alten** oberen
/// Hälfte fällt von 0° auf −90°, ab der Mitte steigt das Blatt mit der
/// **neuen** unteren Hälfte von +90° auf 0°. Beides hängt an einem einzigen
/// Fortschrittswert, damit die Übergabe exakt in der Mitte sitzt.
struct FlipCard: View {
    let digit: Int
    var tint: Color = Palette.ink

    @State private var shown: Int
    @State private var incoming: Int
    @State private var progress: Double = 0

    init(digit: Int, tint: Color = Palette.ink) {
        self.digit = digit
        self.tint = tint
        _shown = State(initialValue: digit)
        _incoming = State(initialValue: digit)
    }

    static let boxWidth: CGFloat = 80
    static let boxHeight: CGFloat = 112
    private static let gap: CGFloat = 2
    private static let radius: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = h * (Self.boxWidth / Self.boxHeight)
            let k = h / Self.boxHeight

            ZStack(alignment: .top) {
                // Ruhende Karte: oben schon die neue, unten noch die alte Ziffer
                half(incoming, top: true, size: CGSize(width: w, height: h), k: k)
                half(shown, top: false, size: CGSize(width: w, height: h), k: k)
                    .offset(y: h / 2)

                // Fallendes Blatt mit der alten oberen Hälfte
                if progress < 0.5 {
                    half(shown, top: true, size: CGSize(width: w, height: h), k: k)
                        .rotation3DEffect(
                            .degrees(-180 * progress),
                            axis: (x: 1, y: 0, z: 0),
                            anchor: .bottom,
                            perspective: 0.45
                        )
                }

                // Aufsteigendes Blatt mit der neuen unteren Hälfte
                if progress >= 0.5 {
                    half(incoming, top: false, size: CGSize(width: w, height: h), k: k)
                        .offset(y: h / 2)
                        .rotation3DEffect(
                            .degrees(90 - 180 * (progress - 0.5)),
                            axis: (x: 1, y: 0, z: 0),
                            anchor: .top,
                            perspective: 0.45
                        )
                }
            }
            .frame(width: w, height: h)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .aspectRatio(Self.boxWidth / Self.boxHeight, contentMode: .fit)
        .onChange(of: digit) { _, new in
            guard new != shown else { return }
            incoming = new
            progress = 0
            withAnimation(.easeInOut(duration: 0.18)) { progress = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                shown = new
                progress = 0
            }
        }
        .accessibilityHidden(true)
    }

    /// Eine Kartenhälfte: die volle Karte, verschoben und auf halbe Höhe beschnitten.
    private func half(_ value: Int, top: Bool, size: CGSize, k: CGFloat) -> some View {
        face(value, size: size, k: k)
            .offset(y: top ? 0 : -size.height / 2)
            .frame(width: size.width, height: size.height / 2 - (top ? Self.gap / 2 * k : -Self.gap / 2 * k), alignment: .top)
            .clipped()
    }

    private func face(_ value: Int, size: CGSize, k: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: Self.radius * k)
                .fill(Palette.rule)
            Text("\(value)")
                .font(.system(size: 66 * k, weight: .regular, design: .monospaced))
                .foregroundStyle(tint)
                .monospacedDigit()
            // Achsnocken an den Flanken, in Papierfarbe als Aussparung
            HStack {
                Capsule().fill(Palette.paper).frame(width: 2 * k, height: 10 * k)
                Spacer()
                Capsule().fill(Palette.paper).frame(width: 2 * k, height: 10 * k)
            }
            .frame(width: size.width - 14 * k)
            .offset(y: -0.5 * k)
        }
        .frame(width: size.width, height: size.height)
    }
}

struct FlipDisplay: View {
    let value: Int
    var tint: Color = Palette.ink

    var body: some View {
        HStack(spacing: 7) {
            ForEach(Array(digits.enumerated()), id: \.offset) { _, digit in
                FlipCard(digit: digit, tint: tint)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(value)")
    }

    private var digits: [Int] {
        String(max(0, value)).compactMap { $0.wholeNumberValue }
    }
}

#Preview {
    @Previewable @State var value = 1849
    return VStack(spacing: 32) {
        FlipDisplay(value: value).frame(height: 112)
        FlipDisplay(value: 206, tint: Roast.hell.color).frame(height: 112)
        Button("Wert ändern") { value = Int.random(in: 1000...2999) }
    }
    .padding(Metric.margin)
    .background(Palette.paper)
}
