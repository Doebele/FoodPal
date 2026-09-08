import SwiftUI

/// Farben als dynamische UIColors statt Asset-Katalog: die Werte stehen damit
/// im Code, wo sie sich mit den Figma-Variablen abgleichen lassen.
enum Palette {
    static let paper = dynamic(light: 0xFAFAF8, dark: 0x121211)
    static let ink   = dynamic(light: 0x161614, dark: 0xF0F0EA)
    static let ink2  = dynamic(light: 0x8A8A82, dark: 0x85857D)
    /// Erloschene Punkte im Diagramm — etwas kräftiger als `rule`.
    static let ink3  = dynamic(light: 0xC9C9BD, dark: 0x33332E)
    static let rule  = dynamic(light: 0xE2E2DA, dark: 0x2A2A27)

    /// Fester Farbwert, unabhängig vom aktuellen Modus — für Vorschauen,
    /// die zeigen sollen, wie der *andere* Modus aussieht.
    static func fixed(_ hex: UInt32) -> Color { Color(uiColor: UIColor(hex: hex)) }

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

    var label: String {
        switch self {
        case .zimt: "Zimt"
        case .hell: "Hell"
        case .mittel: "Mittel"
        case .wien: "Wien"
        case .franzoesisch: "Französisch"
        case .italienisch: "Italienisch"
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
