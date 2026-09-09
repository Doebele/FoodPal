import SwiftUI

/// Der zweispaltige Satzspiegel der beiden Formulare.
///
/// Links die Zahlen, rechts Bild, Zeitpunkt und Bezeichnung — **37 zu 63**
/// mit 8 pt Steg, aus dem Entwurf abgemessen (124,4 / 8 / 212,6 auf 345).
/// Die Aufteilung ist keine Laune: Zahlen sind kurz und brauchen wenig
/// Breite, ein Gerichtsname ist lang und braucht viel. Nebeneinander gesetzt
/// steht beides auf einem Blick da, wo es untereinander zwei Bildschirme
/// wären.
///
/// **Ab den Bedienhilfen-Grössen fallen die Spalten untereinander.** Bei
/// 37 % von 345 sind das 124 pt, und „kohlenhydrate · g" braucht schon bei
/// normaler Schrift 103 davon; zwei Stufen höher passt es nicht mehr neben
/// einen Wert. Dieselbe Regel wie in der Eintragsliste und im Getränkeraster.
struct SplitForm<Left: View, Right: View>: View {
    /// Um wie viel die linke Spalte tiefer beginnt als die rechte.
    ///
    /// Der Versatz ist die halbe Miete des Entwurfs: oben links bleibt es
    /// leer, und was man anfassen und eintippen muss, rückt nach unten, wo
    /// der Daumen ist. Er steht als Mass da, weil er sich nicht ableiten
    /// lässt — die Höhe der rechten Spalte zu messen hiesse `GeometryReader`,
    /// und der bringt dieses Sheet zum Absturz.
    var leftOffset: CGFloat = 0
    @ViewBuilder let left: Left
    @ViewBuilder let right: Right

    @Environment(\.dynamicTypeSize) private var typeSize

    /// Breite der linken Spalte, aus dem Entwurf: 124,4 auf 345.
    ///
    /// Als **Höchstmass**, nicht als feste Breite — und damit ohne
    /// `GeometryReader`. Ein `HStack` teilt die Breite unter seinen
    /// dehnbaren Kindern auf und gibt zurück, was eines nicht braucht: die
    /// linke Spalte nimmt ihre 124, die rechte den Rest. Auf schmalen Geräten
    /// behalten die Zahlen ihre Breite und der Name bricht öfter um — genau
    /// die richtige Reihenfolge, denn eine Zahl kann nicht umbrechen.
    ///
    /// Der Weg über eine gemessene Breite war der erste Versuch und ist
    /// **abgestürzt**: `GeometryReader` in diesem Sheet lässt SwiftUI in
    /// `GeometryReaderLayout.placeSubviews` mit einer Zusicherung anhalten,
    /// gleich ob im `background` der Spalten oder als eigene Zeile darüber.
    private static var leftWidth: CGFloat { 124 }
    private static var gap: CGFloat { 8 }

    var body: some View {
        if typeSize.isAccessibilitySize {
            // Untereinander in Lesereihenfolge: erst worum es geht, dann die
            // Zahlen dazu.
            VStack(alignment: .leading, spacing: 0) {
                right
                left
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            // Beide Seiten in einen `VStack`: ein `@ViewBuilder` mit mehreren
            // Ansichten ist ein TupleView, und der wird im `HStack` zu ebenso
            // vielen Geschwistern — die fuenf Zahlenfelder standen
            // nebeneinander statt untereinander.
            HStack(alignment: .top, spacing: Self.gap) {
                VStack(alignment: .leading, spacing: 0) {
                    Color.clear.frame(height: leftOffset)
                    left
                }
                .frame(maxWidth: Self.leftWidth, alignment: .leading)
                VStack(alignment: .leading, spacing: 0) { right }
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

/// Ein Feld im Formular: Beschriftung, Wert, Haarlinie.
///
/// Beschriftung 11 pt in Ink2, darunter der Wert, darunter die Linie und
/// 18 pt Luft — die Masse aus dem Entwurf. Die Beschriftung darf umbrechen:
/// in der schmalen linken Spalte passt „kohlenhydrate · g" sonst schon eine
/// Schriftstufe über der Vorgabe nicht mehr in eine Zeile.
struct FormField<Value: View>: View {
    let label: LocalizedStringKey
    @ViewBuilder let value: Value

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .scaledFont(11)
                .tracking(0.8)
                .foregroundStyle(Palette.ink2)
                .fixedSize(horizontal: false, vertical: true)
            value
            Rectangle().fill(Palette.rule).frame(height: 1)
        }
        .padding(.bottom, 18)
    }
}
