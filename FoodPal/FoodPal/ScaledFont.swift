import SwiftUI

extension View {
    /// Wie `.font(.system(size:))`, aber **mitwachsend** mit der
    /// Systemschriftgröße.
    ///
    /// `Font.system(size:)` ist fest — wer die Schrift größer stellt, sieht in
    /// der App keinen Unterschied. Das schließt sehbehinderte Nutzer aus, und
    /// bei 71 festen Größen wäre jede einzeln umzustellen gewesen.
    ///
    /// Der Umweg über `UIFontMetrics` schied aus: der liest die Merkmale des
    /// Bildschirms, nicht die SwiftUI-Umgebung — und wäre damit taub gegen
    /// `.dynamicTypeSize()`, also gegen den Schalter in den Einstellungen.
    /// Deshalb der Faktor aus `\.dynamicTypeSize`, gemessen an Apples eigener
    /// Staffelung für Fließtext.
    func scaledFont(
        _ size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) -> some View {
        modifier(ScaledFont(size: size, weight: weight, design: design))
    }
}

private struct ScaledFont: ViewModifier {
    @Environment(\.dynamicTypeSize) private var typeSize

    let size: CGFloat
    let weight: Font.Weight
    let design: Font.Design

    func body(content: Content) -> some View {
        content.font(.system(size: size * Self.factor(typeSize), weight: weight, design: design))
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
