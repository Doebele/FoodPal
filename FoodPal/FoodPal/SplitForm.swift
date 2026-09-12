import SwiftUI

/// Der zweispaltige Satzspiegel der beiden Formulare.
///
/// Links die Zahlen, rechts Bild, Zeitpunkt und Bezeichnung — die linke
/// Spalte 124 breit, aus dem Entwurf abgemessen (124,4 auf 345).
/// Die Aufteilung ist keine Laune: Zahlen sind kurz und brauchen wenig
/// Breite, ein Gerichtsname ist lang und braucht viel. Nebeneinander gesetzt
/// steht beides auf einem Blick da, wo es untereinander zwei Bildschirme
/// wären.
///
/// **Ab den Bedienhilfen-Grössen fallen die Spalten untereinander.** Bei
/// 37 % von 345 sind das 124 pt, und „kohlenhydrate · g" braucht schon bei
/// normaler Schrift 103 davon; zwei Stufen höher passt es nicht mehr neben
/// einen Wert. Dieselbe Regel wie in der Eintragsliste und im Getränkeraster.
/// Die Masse des Satzspiegels. Eigener Typ, weil ein generischer Typ keine
/// gespeicherten statischen Eigenschaften tragen darf — und weil das Bild im
/// Eintrag sie ebenfalls braucht.
enum FormGrid {
    static let leftWidth: CGFloat = 124
    /// **Der Steg ist der Seitenrand.** Im Entwurf waren es acht Punkte, und
    /// damit standen die beiden Spalten enger beieinander als jede von ihnen
    /// am Blattrand — der Satzspiegel hatte innen eine feinere Fuge als
    /// aussen. Derselbe Wert wie `Metric.margin` macht aus zwei Spalten ein
    /// Raster: aussen 24, innen 24.
    static let gap: CGFloat = Metric.margin
    /// Wo die rechte Spalte beginnt, vom Seitenrand aus gerechnet.
    static var rightInset: CGFloat { leftWidth + gap }
}

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
            HStack(alignment: .top, spacing: FormGrid.gap) {
                VStack(alignment: .leading, spacing: 0) {
                    Color.clear.frame(height: leftOffset)
                    left
                }
                .frame(maxWidth: FormGrid.leftWidth, alignment: .leading)
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
    /// **Rechtsbündig in der Zahlenspalte.** Die Werte dort sind kurz und
    /// verschieden lang; an der linken Kante ausgerichtet flattert ihr Ende,
    /// an der rechten stehen Einer über Einern — und die Haarlinie darunter
    /// endet dort, wo die Zahl endet. Die Beschriftung folgt dem Wert, sonst
    /// zöge sie die Spalte nach zwei Seiten.
    var alignment: HorizontalAlignment = .leading
    @ViewBuilder let value: Value

    @Environment(\.dynamicTypeSize) private var typeSize

    /// Ab den Bedienhilfen-Grössen fallen die Spalten untereinander, und die
    /// Zahlen stehen über die ganze Breite. Rechtsbündig wären sie dann am
    /// Bildschirmrand statt neben ihrer Beschriftung.
    private var effective: HorizontalAlignment {
        typeSize.isAccessibilitySize ? .leading : alignment
    }

    private var box: Alignment { effective == .trailing ? .trailing : .leading }

    var body: some View {
        VStack(alignment: effective, spacing: 6) {
            Text(label)
                .scaledFont(11)
                .tracking(0.8)
                .foregroundStyle(Palette.ink2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: box)
            value
            Rectangle().fill(Palette.rule).frame(height: 1)
        }
        // Ueber die Umgebung, nicht am Feld: so folgt auch der Text **in**
        // einem Eingabefeld der Ausrichtung, und die Zahlenfelder brauchen
        // nichts davon zu wissen. Ohne das stand die Beschriftung links und
        // der Wert rechts, sobald die Spalten untereinanderfielen.
        .multilineTextAlignment(effective == .trailing ? .trailing : .leading)
        .padding(.bottom, 18)
    }
}
