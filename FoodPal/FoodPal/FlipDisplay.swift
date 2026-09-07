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
    var duration: Double = FlipDisplay.landing

    @State private var shown: Int
    @State private var incoming: Int
    @State private var progress: Double = 0

    init(digit: Int, tint: Color = Palette.ink, duration: Double = FlipDisplay.landing) {
        self.digit = digit
        self.tint = tint
        self.duration = duration
        _shown = State(initialValue: digit)
        _incoming = State(initialValue: digit)
    }

    static let boxWidth: CGFloat = 80
    static let boxHeight: CGFloat = 112
    private static let radius: CGFloat = 6
    private static let seam: CGFloat = 1.5

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = h * (Self.boxWidth / Self.boxHeight)
            let k = h / Self.boxHeight
            let size = CGSize(width: w, height: h)

            ZStack(alignment: .top) {
                // Ruhende Karte: oben schon die neue, unten noch die alte Ziffer
                half(incoming, top: true, size: size, k: k)
                half(shown, top: false, size: size, k: k)
                    .offset(y: h / 2)

                // Fallendes Blatt mit der alten oberen Hälfte
                if progress < 0.5 {
                    half(shown, top: true, size: size, k: k)
                        .rotation3DEffect(
                            .degrees(-180 * progress),
                            axis: (x: 1, y: 0, z: 0),
                            anchor: .bottom,
                            perspective: 0.45
                        )
                }

                // Aufsteigendes Blatt mit der neuen unteren Hälfte
                if progress >= 0.5 {
                    half(incoming, top: false, size: size, k: k)
                        .offset(y: h / 2)
                        .rotation3DEffect(
                            .degrees(90 - 180 * (progress - 0.5)),
                            axis: (x: 1, y: 0, z: 0),
                            anchor: .top,
                            perspective: 0.45
                        )
                }

                // Die Fuge liegt über beiden Blättern — sonst verschwindet sie
                // unter dem klappenden Blatt.
                Rectangle()
                    .fill(Palette.paper)
                    .frame(width: w, height: Self.seam * k)
                    .offset(y: h / 2 - Self.seam * k / 2)
            }
            .frame(width: w, height: h)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .aspectRatio(Self.boxWidth / Self.boxHeight, contentMode: .fit)
        .onChange(of: digit) { _, new in
            guard new != shown else { return }
            incoming = new
            progress = 0
            withAnimation(.easeInOut(duration: duration)) { progress = 1 }
            Task {
                try? await Task.sleep(for: .seconds(duration))
                shown = new
                progress = 0
            }
        }
        .accessibilityHidden(true)
    }

    private func half(_ value: Int, top: Bool, size: CGSize, k: CGFloat) -> some View {
        face(value, size: size, k: k)
            .offset(y: top ? 0 : -size.height / 2)
            .frame(width: size.width, height: size.height / 2, alignment: .top)
            .clipped()
    }

    private func face(_ value: Int, size: CGSize, k: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: Self.radius * k)
                .fill(Palette.rule)
            Text("\(value)")
                .font(.system(size: 82 * k, weight: .regular, design: .monospaced))
                .foregroundStyle(tint)
                .monospacedDigit()
                .minimumScaleFactor(0.5)
            // Achsnocken an den Flanken, in Papierfarbe als Aussparung
            HStack {
                Capsule().fill(Palette.paper).frame(width: 2 * k, height: 10 * k)
                Spacer()
                Capsule().fill(Palette.paper).frame(width: 2 * k, height: 10 * k)
            }
            .frame(width: size.width - 14 * k)
        }
        .frame(width: size.width, height: size.height)
    }
}

/// Setzt die Ziffern **nacheinander von links nach rechts** um — und jede
/// Stelle **rollt** durch die Zwischenwerte, wie ein Zählwerk: von 2 auf 5
/// über 3 und 4, nicht im Sprung.
///
/// Zwei Taktungen: Zwischenschritte laufen schnell, das Aufsetzen auf den
/// Zielwert etwas länger — so hat der Lauf ein hörbares Ende.
///
/// Die Untergrenze setzt nicht die Animation, sondern die Haptik: iOS fasst
/// Impulse unter rund 50 ms zusammen. Bei 90 ms je Zwischenschritt bleibt
/// jeder Tick einzeln spürbar.
struct FlipDisplay: View {
    let value: Int
    var tint: Color = Palette.ink

    /// Zwischenschritt im Durchrollen.
    static let step: Double = 0.09
    /// Aufsetzen auf den Zielwert.
    static let landing: Double = 0.15
    /// Sicherheitsventil: darüber wird gesetzt statt gerollt. Greift im
    /// normalen Betrieb nie — ein Eintrag ändert die Summe um wenige Stellen.
    private static let maxFlaps = 20

    @State private var shown: [Int] = []
    @State private var flap = 0
    @State private var stepDuration = FlipDisplay.landing

    var body: some View {
        HStack(spacing: 7) {
            ForEach(Array(shown.enumerated()), id: \.offset) { _, digit in
                FlipCard(digit: digit, tint: tint, duration: stepDuration)
            }
        }
        .task(id: value) { await cascade(to: Self.digits(of: value)) }
        .haptic(trigger: flap)
        .accessibilityElement()
        .accessibilityLabel("\(value)")
    }

    private func cascade(to target: [Int]) async {
        // Stellenzahl geändert: ohne Klappen neu setzen, sonst liefe die
        // Zuordnung Stelle-zu-Karte auseinander.
        guard shown.count == target.count else {
            shown = target
            return
        }

        let plan = target.indices.map { Self.rollSteps(from: shown[$0], to: target[$0]) }
        guard plan.reduce(0, +) <= Self.maxFlaps else {
            shown = target
            return
        }

        for index in target.indices where plan[index] > 0 {
            for remaining in stride(from: plan[index], to: 0, by: -1) {
                let isLast = remaining == 1
                stepDuration = isLast ? Self.landing : Self.step
                shown[index] = (shown[index] + 1) % 10
                try? await Task.sleep(for: .seconds(stepDuration))
                flap += 1
            }
        }
    }

    /// Ein Zählwerk rollt nur vorwärts: von 8 auf 1 sind es drei Schritte
    /// über 9 und 0, nicht sieben rückwärts.
    private static func rollSteps(from: Int, to: Int) -> Int {
        (to - from + 10) % 10
    }

    private static func digits(of value: Int) -> [Int] {
        String(max(0, value)).compactMap(\.wholeNumberValue)
    }
}

#Preview {
    @Previewable @State var value = 1849
    return VStack(spacing: 32) {
        FlipDisplay(value: value).frame(height: 112)
        Button("Wert wechseln") { value = Int.random(in: 1000...2999) }
    }
    .padding(Metric.margin)
    .background(Palette.paper)
}
