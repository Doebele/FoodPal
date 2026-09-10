import SwiftUI

/// Farben als dynamische UIColors statt Asset-Katalog: die Werte stehen damit
/// im Code, wo sie sich mit den Figma-Variablen abgleichen lassen.
enum Palette {
    static let paper = dynamic(light: 0xFAFAF8, dark: 0x121211)
    static let ink   = dynamic(light: 0x161614, dark: 0xF0F0EA)
    /// Hell abgedunkelt von `8A8A82` auf `727269`: der alte Ton kam auf
    /// 3,33 : 1 gegen Papier und fiel damit fuer die 11-pt-Ueberschriften
    /// durch (WCAG AA verlangt 4,5 : 1 unter 18 pt). Jetzt 4,64 : 1 — knapp
    /// darueber, damit moeglichst wenig von der Ruhe verlorengeht. Dunkel lag
    /// mit 5,04 : 1 schon richtig und bleibt.
    static let ink2  = dynamic(light: 0x72726A, dark: 0x85857D)
    /// Erloschene Punkte im Diagramm — etwas kräftiger als `rule`.
    static let ink3  = dynamic(light: 0xC9C9BD, dark: 0x33332E)
    static let rule  = dynamic(light: 0xE2E2DA, dark: 0x2A2A27)
    /// Erloschene **Segmente** — eigener Ton, weil sie ein anderes Problem
    /// haben als die Punkte im Diagramm. Ein Segment ist gross und flaechig;
    /// in `ink3` steht die ganze Acht als Schatten hinter jeder Ziffer und
    /// nimmt ihr die Kontur. Gegen Papier faellt der Ton damit von 1,60 : 1
    /// auf 1,15 : 1 — genug, um die Bauart der Anzeige zu zeigen, zu wenig,
    /// um mitgelesen zu werden.
    ///
    /// Keine Frage der Zugaenglichkeit: die erloschenen Segmente tragen
    /// keine Information. Die leuchtenden stehen unveraendert bei 17 : 1.
    ///
    /// Figma-Variable `segment` (Node `1:8445`).
    static let segment = dynamic(light: 0xEBEBE2, dark: 0x1F1F1C)
    /// Die Kachel der Getränkeauswahl: Papier, eine Spur zurückgenommen.
    /// Im Entwurf ist es ein radialer Verlauf von Papier nach `rule` bei 20 %
    /// Deckkraft — sichtbar davon ist nur, dass die Kachel nicht ganz Papier
    /// ist. Eine Fläche sagt dasselbe mit einer Zeile.
    static let tile  = dynamic(light: 0xF4F4EF, dark: 0x1B1B19)

    /// Fester Farbwert, unabhängig vom aktuellen Modus — für Vorschauen,
    /// die zeigen sollen, wie der *andere* Modus aussieht.
    static func fixed(_ hex: UInt32) -> Color { Color(uiColor: UIColor(hex: hex)) }

    /// Feste Punktfarben der Erscheinungsbild-Auswahl. Fest, nicht dynamisch:
    /// sonst zeigte „dunkel" im Dunkelmodus ein helles Feld und die Auswahl
    /// widerspräche sich selbst.
    static let dotLight = fixed(0xE2E2DA)
    static let dotDark = fixed(0x161614)

    static let lightPaper: UInt32 = 0xFAFAF8
    static let lightInk: UInt32 = 0x161614
    static let darkPaper: UInt32 = 0x121211
    static let darkInk: UInt32 = 0xF0F0EA

    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
}

/// Der Akzent gehört ausschließlich dem Koffein. Wählbar als Röstung.
enum Roast: String, CaseIterable, Identifiable, Codable {
    case zimt, hell, mittel, wien, franzoesisch, italienisch

    var id: String { rawValue }

    /// `String(localized:)` und nicht `Text`, weil die Bezeichnung auch in
    /// Ueberschriften interpoliert wird. Der deutsche Text ist zugleich der
    /// Schluessel — die Quellsprache des Katalogs ist Deutsch.
    var label: String {
        switch self {
        case .zimt: String(localized: "Zimt")
        case .hell: String(localized: "Hell")
        case .mittel: String(localized: "Mittel")
        case .wien: String(localized: "Wien")
        case .franzoesisch: String(localized: "Französisch")
        case .italienisch: String(localized: "Italienisch")
        }
    }

    var color: Color {
        switch self {
        case .zimt: Palette.dynamic(light: 0xC9793A, dark: 0xE3A876)
        case .hell: Palette.dynamic(light: 0xB4531F, dark: 0xE08A4E)
        case .mittel: Palette.dynamic(light: 0x9A4A22, dark: 0xCE7B45)
        case .wien: Palette.dynamic(light: 0x7A3A1B, dark: 0xBC6D3C)
        case .franzoesisch: Palette.dynamic(light: 0x5A2A14, dark: 0xA75E33)
        case .italienisch: Palette.dynamic(light: 0x3D1C0E, dark: 0x91502B)
        }
    }
}

/// Das Punktraster, auf dem Tagesdiagramm und Ziffernanzeige gemeinsam sitzen.
///
/// Ein Tag hat immer 24 Stunden, also hat das Raster **immer 72 Spalten** —
/// je Stunde drei Punkte, zwischen den Stunden eine zusätzliche Lücke.
/// Die Teilung ergibt sich aus der verfügbaren Breite und gilt für **beide**
/// Achsen; nur so bleiben die Punkte quadratisch und nichts wird gestaucht.
enum Grid {
    /// Vier Punkte je Stunde statt drei — eine Viertelstunde je Spalte.
    static let perHour = 4
    static let columns = 24 * perHour
    static let dot: CGFloat = 3
    static let gap: CGFloat = 1
    /// **Gleichmässig.** Früher sass zwischen den Stunden eine breitere Lücke;
    /// die ist weg. Ohne Gruppierung läuft das Raster bis an den Rand, und
    /// beim Wischen von Tag zu Tag geht die Fläche fliessend ineinander über.
    static let pitch: CGFloat = dot + gap
    /// x(95) + dot.
    static let naturalWidth: CGFloat = CGFloat(columns) * pitch - gap

    static func x(_ column: Int) -> CGFloat { CGFloat(column) * pitch }

    static func scale(forWidth width: CGFloat) -> CGFloat {
        width / naturalWidth
    }
}

enum Metric {
    static let margin: CGFloat = 24
    static let rowHeight: CGFloat = 56
}

/// Die grosse Anzeige zeigt **immer vier Stellen**, führende Nullen bleiben
/// stehen. Das ist die Machart eines Zählwerks: das Feld hat so viele Räder,
/// wie es hat, und leere Räder zeigen die Null statt zu verschwinden.
///
/// Praktisch heisst das, dass beim Wechsel von 1849 auf 74 keine Karten mehr
/// auftauchen und verschwinden — es klappen nur Ziffern um. Werte über 9999
/// bekommen trotzdem ihre Stelle; abgeschnitten wird nichts.
enum Digits {
    static let places = 4

    static func of(_ value: Int) -> [Int] {
        let text = String(max(0, value))
        return Array(repeating: 0, count: max(0, places - text.count))
            + text.compactMap(\.wholeNumberValue)
    }
}

/// Scrollt erst, wenn der Inhalt nicht mehr passt.
///
/// Bei den Bedienhilfen-Groessen ist Fliesstext 53 statt 17 pt — dann passt
/// kein Sheet mehr auf den Schirm, und SwiftUI staucht die erste Zeile zu
/// „Foto aufneh…". Ein gewoehnlicher `ScrollView` waere der Preis dafuer,
/// dass ein `Spacer` darin nichts mehr haelt: die Getraenkeliste haengt aber
/// absichtlich unten, im Daumenbereich. `minHeight` aus der Container-Hoehe
/// loest beides — unter der Schwelle steht alles wie entworfen, darueber
/// wird gescrollt.
struct ScrollsWhenNeeded<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                content.frame(minHeight: geo.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
