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
            // `.top`, nicht die Vorgabe `.center`: die untere Haelfte sitzt
            // per `offset` an ihrem Platz, und ein Offset waechst das Layout
            // nicht mit. Der ZStack ist damit nur eine halbe Karte hoch — bei
            // zentrierter Ausrichtung rutschte die ganze Karte um h/4 nach
            // unten und stand 28 pt unter ihrem eigenen Rahmen.
            .frame(width: w, height: h, alignment: .top)
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

/// Alle Stellen rollen **gleichzeitig** aufwärts durch die Zwischenwerte,
/// wie ein Zählwerk, das man von Hand hochdreht: von 4 auf 8 über 5, 6 und 7.
/// Wer weniger Schritte vor sich hat, steht früher still — genau dieses
/// ungleiche Auslaufen macht den Eindruck, und deshalb laufen die Stellen
/// nicht mehr nacheinander von links nach rechts.
///
/// Zwei Anlässe, zwei Verhalten:
///
/// - **Wertänderung** — die Stellen rollen auf den neuen Wert. Wächst die
///   Stellenzahl dabei, kommt vorn still eine Karte dazu, die dann mitrollt.
/// - **Moduswechsel** (`resetKey`, etwa kcal ↔ mg) — die Anzeige wird erst
///   auf null zurückgesetzt, eine Klappe je Stelle; von dort wird auf den
///   neuen Wert **hochgezählt** wie bei jeder anderen Änderung.
///
/// Die Untergrenze setzt nicht die Animation, sondern die Haptik: iOS fasst
/// Impulse unter rund 50 ms zusammen. Deshalb **ein Impuls je Welle** und
/// nicht je Stelle — vier gleichzeitige Karten wären ein Brummen.
struct FlipDisplay: View {
    let value: Int
    var tint: Color = Palette.ink
    /// Wechselt dieser Schlüssel, wird genullt statt gezählt.
    var resetKey: String = ""

    /// Zwischenschritt im Durchrollen.
    static let step: Double = 0.14
    /// Aufsetzen auf den Zielwert.
    static let landing: Double = 0.26
    /// Klappe beim stummen Nullen und beim Setzen nach dem Moduswechsel.
    private static let reset: Double = 0.16
    /// Ein- und Ausblenden einer Stelle.
    private static let shift: Double = 0.22
    /// Vorlauf vor dem Rollen. Der Wert ändert sich in dem Moment, in dem
    /// gesichert wird — das Bottom Sheet fährt danach erst heraus und läge
    /// sonst über den ersten Klappen. Nur bei Wertänderungen, nicht beim
    /// Moduswechsel: dort ist nichts im Weg.
    private static let leadIn: Double = 0.4

    /// Wer „Bewegung reduzieren" eingeschaltet hat, will kein Zaehlwerk
    /// durchlaufen sehen. Der Wert wird dann gesetzt, mit **einem** Impuls
    /// statt einer Kaskade — die Rueckmeldung bleibt, die Bewegung geht.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var shown: [Int] = []
    /// Je Stelle die Dauer ihrer **nächsten** Klappe. Seit alle gleichzeitig
    /// rollen, braucht jede ihre eigene: die letzte Klappe einer Stelle setzt
    /// langsamer auf, während die Nachbarn noch weiterzählen.
    @State private var durations: [Double] = []
    @State private var shownKey = ""
    @State private var flap = 0

    var body: some View {
        HStack(spacing: 7) {
            ForEach(Array(shown.enumerated()), id: \.offset) { index, digit in
                FlipCard(digit: digit, tint: tint, duration: duration(at: index))
                    .transition(.opacity)
            }
        }
        .task(id: "\(resetKey)|\(value)") {
            await update(to: Digits.of(value), key: resetKey)
        }
        // Kraeftiger als der Standardimpuls: eine Karte, die aufsetzt, ist
        // ein mechanischer Anschlag und kein Antippen.
        .haptic(.impact(weight: .medium, intensity: 0.9), trigger: flap)
        .accessibilityElement()
        .accessibilityLabel("\(value)")
    }

    private func update(to target: [Int], key: String) async {
        let previous = shownKey
        shownKey = key

        guard !shown.isEmpty else {
            // Erster Aufbau und jeder Tageswechsel: hinstellen, nicht zählen.
            show(target, each: Self.landing)
            return
        }

        if reduceMotion {
            guard shown != target else { return }
            withAnimation(.easeInOut(duration: 0.2)) { show(target, each: 0.2) }
            if previous == key { flap += 1 }
            return
        }

        if !previous.isEmpty && previous != key {
            // Moduswechsel: erst auf null. Das Zurücksetzen ist kein Zählen,
            // sondern ein Handgriff — eine Klappe je Stelle, spürbar.
            await flipEach(to: Array(repeating: 0, count: shown.count))
        } else {
            guard await Self.pause(Self.leadIn) else { return }
        }

        await resize(to: target.count)
        await roll(to: target)
    }

    /// Läuft den Plan aus `waves` ab: je Welle eine Klappe, ein Impuls.
    private func roll(to target: [Int]) async {
        let plan = Self.waves(from: shown, to: target)
        guard !plan.isEmpty else { return }

        for (index, wheels) in plan.enumerated() {
            for place in wheels.indices where wheels[place] != shown[place] {
                // Die letzte Klappe einer Stelle setzt langsamer auf — das ist
                // die, mit der sie ihr Ziel erreicht. Die Nachbarn zählen
                // unterdessen im schnelleren Takt weiter.
                durations[place] = wheels[place] == target[place] ? Self.landing : Self.step
            }
            shown = wheels
            flap += 1

            let last = index == plan.count - 1
            guard await Self.pause(last ? Self.landing : Self.step) else { return }
        }
    }

    /// Die Ziffernstände nach jeder Welle: alle Stellen rücken **gleichzeitig**
    /// eine Ziffer aufwärts, wer sein Ziel erreicht hat, bleibt stehen.
    ///
    /// Die Zahl der Wellen ist damit der größte Einzelweg und nie mehr als
    /// neun — egal wie weit der Wert springt. Solange die Stellen nacheinander
    /// liefen, addierten sich ihre Schritte und es brauchte eine Deckelung;
    /// gleichzeitig ist die längste Bewegung gut eine Sekunde lang.
    ///
    /// Als reine Rechnung ausgelagert: so lässt sie sich ohne View prüfen.
    static func waves(from start: [Int], to target: [Int]) -> [[Int]] {
        // Ungleich lange Stände gibt es nach `resize` nicht; käme es doch
        // dazu, wird gesetzt statt gerollt.
        guard start.count == target.count else { return start == target ? [] : [target] }

        var left = target.indices.map { rollSteps(from: start[$0], to: target[$0]) }
        var digits = start
        var plan: [[Int]] = []

        while let longest = left.max(), longest > 0 {
            for index in left.indices where left[index] > 0 {
                digits[index] = (digits[index] + 1) % 10
                left[index] -= 1
            }
            plan.append(digits)
        }
        return plan
    }

    /// Setzt jede Stelle mit genau einer Klappe, je Stelle ein Impuls.
    ///
    /// Nur Stellen, die sich wirklich ändern: eine 0, die 0 bleibt, klappt
    /// nicht und darf sich deshalb auch nicht melden.
    private func flipEach(to target: [Int]) async {
        for index in target.indices where shown[index] != target[index] {
            durations[index] = Self.reset
            shown[index] = target[index]
            guard await Self.pause(Self.reset) else { return }
            flap += 1
        }
    }

    /// Blendet vorn eine Stelle ein oder aus — still, es ist kein Zählschritt.
    private func resize(to count: Int) async {
        guard shown.count != count else { return }
        let digits = count > shown.count
            ? Array(repeating: 0, count: count - shown.count) + shown
            : Array(shown.suffix(count))
        withAnimation(.easeInOut(duration: Self.shift)) { show(digits, each: Self.step) }
        guard await Self.pause(Self.shift + 0.04) else { return }
    }

    /// `shown` und `durations` müssen immer gleich lang sein — deshalb nur
    /// hier gemeinsam setzen.
    private func show(_ digits: [Int], each duration: Double) {
        shown = digits
        durations = Array(repeating: duration, count: digits.count)
    }

    private func duration(at index: Int) -> Double {
        durations.indices.contains(index) ? durations[index] : Self.landing
    }

    /// Pause, die ein Abbruch auch wirklich beendet. `try?` allein schluckt
    /// den Abbruch, und die Restschleife ratterte ohne jede Pause durch —
    /// bei zwei Einträgen kurz hintereinander gut zu sehen.
    private static func pause(_ seconds: Double) async -> Bool {
        (try? await Task.sleep(for: .seconds(seconds))) != nil
    }

    /// Ein Zählwerk rollt nur vorwärts: von 8 auf 1 sind es drei Schritte
    /// über 9 und 0, nicht sieben rückwärts.
    private static func rollSteps(from: Int, to: Int) -> Int {
        (to - from + 10) % 10
    }

}

#Preview {
    @Previewable @State var value = 1849
    @Previewable @State var key = "kcal"
    return VStack(spacing: 32) {
        FlipDisplay(value: value, resetKey: key).frame(height: 112)
        Button("Wert ändern") { value += Int.random(in: 3...80) }
        Button("Modus wechseln") {
            key = key == "kcal" ? "mg" : "kcal"
            value = key == "kcal" ? 1849 : 189
        }
    }
    .padding(Metric.margin)
    .background(Palette.paper)
}
