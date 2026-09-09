import SwiftUI

extension View {
    /// Wie `.font(.custom(_:size:))`, aber **mitwachsend** mit der
    /// Systemschriftgröße — und immer in Fira.
    ///
    /// `Font.custom(_:size:)` skaliert von sich aus mit Dynamic Type. Das
    /// klingt praktisch, wäre hier aber doppelt: die Größe wird unten schon
    /// mit dem Faktor aus `\.dynamicTypeSize` multipliziert. Deshalb
    /// `fixedSize:` — dann skaliert nur die eine Stelle, und der Schalter in
    /// den Einstellungen greift weiterhin.
    ///
    /// Der Umweg über `UIFontMetrics` schied aus demselben Grund aus wie
    /// vorher: der liest die Merkmale des Bildschirms, nicht die
    /// SwiftUI-Umgebung — und wäre damit taub gegen `.dynamicTypeSize()`.
    func scaledFont(
        _ size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default,
        condensed: Bool = false
    ) -> some View {
        modifier(ScaledFont(size: size, weight: weight, design: design, condensed: condensed))
    }
}

/// Die gebündelten Schnitte. Fira Sans für Text, Fira Sans Condensed für die
/// Zeilenbeschriftungen in den Einstellungen — schmaler, damit Label und Wert
/// nebeneinander passen —, Fira Mono für alles, was in Spalten steht.
///
/// Fira ist die Hausschrift der Entwürfe; SF Pro war nur die Vorgabe, solange
/// nichts anderes im Bündel lag. Lizenz: SIL Open Font License 1.1.
enum Fira {
    static func name(_ weight: Font.Weight, _ design: Font.Design, condensed: Bool) -> String {
        if design == .monospaced {
            return heavy(weight) ? "FiraMono-Medium" : "FiraMono-Regular"
        }
        if condensed {
            return heavy(weight) ? "FiraSansCondensed-Regular" : "FiraSansCondensed-Light"
        }
        if heavy(weight) { return "FiraSans-Medium" }
        if weight == .light || weight == .thin || weight == .ultraLight { return "FiraSans-Light" }
        return "FiraSans-Regular"
    }

    /// Fira liegt in drei Schnitten im Bündel. Alles ab Medium fällt auf
    /// Medium, alles darunter auf Regular — mehr Gewichte wären mehr Megabyte
    /// für Unterschiede, die in dieser Oberfläche niemand sieht.
    private static func heavy(_ weight: Font.Weight) -> Bool {
        [.medium, .semibold, .bold, .heavy, .black].contains(weight)
    }
}

private struct ScaledFont: ViewModifier {
    @Environment(\.dynamicTypeSize) private var typeSize

    let size: CGFloat
    let weight: Font.Weight
    let design: Font.Design
    let condensed: Bool

    func body(content: Content) -> some View {
        content.font(
            .custom(
                Fira.name(weight, design, condensed: condensed),
                fixedSize: size * Self.factor(typeSize)
            )
        )
    }

    /// Apples Fließtext geht 14 · 15 · 16 · **17** · 19 · 21 · 23 und in den
    /// Bedienhilfen 28 · 33 · 40 · 47 · 53. Auf 17 normiert ergibt das diese
    /// Faktoren; damit folgt jede Größe derselben Kurve wie der Systemtext.
    private static func factor(_ size: DynamicTypeSize) -> CGFloat {
        switch size {
        case .xSmall: 14 / 17
        case .small: 15 / 17
        case .medium: 16 / 17
        case .large: 1
        case .xLarge: 19 / 17
        case .xxLarge: 21 / 17
        case .xxxLarge: 23 / 17
        case .accessibility1: 28 / 17
        case .accessibility2: 33 / 17
        case .accessibility3: 40 / 17
        case .accessibility4: 47 / 17
        case .accessibility5: 53 / 17
        @unknown default: 1
        }
    }
}
