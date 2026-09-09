import SwiftUI
import UIKit

/// Warenkunde zu einer Kaffeesorte: was drin ist und wie sie entsteht.
///
/// Sie gehört der **Sorte**, nicht dem Eintrag — deshalb steht sie hier und
/// nicht im Model. Nachgeschlagen wird über die Bezeichnung; die stimmt bei
/// allem, was aus der Getränkeauswahl kommt, und bei einer Schätzung meistens
/// auch. Findet sich nichts, gibt es eben keine Marke im Bild.
enum CoffeeInfo: String, CaseIterable {
    case espresso, ristretto, doppio, lungo, americano, filter, mokka
    case macchiato, cortado, cappuccino, latte, latteMacchiato, flatWhite, coldBrew

    /// Bezeichnung im Bestand — so heisst der Eintrag, der daraus entsteht.
    var preset: String {
        switch self {
        case .espresso: "Espresso"
        case .ristretto: "Ristretto"
        case .doppio: "Doppio"
        case .lungo: "Lungo"
        case .americano: "Americano"
        case .filter: "Filterkaffee"
        case .mokka: "Mokka"
        case .macchiato: "Macchiato"
        case .cortado: "Cortado"
        case .cappuccino: "Cappuccino"
        case .latte: "Caffè Latte"
        case .latteMacchiato: "Latte Macchiato"
        case .flatWhite: "Flat White"
        case .coldBrew: "Cold Brew"
        }
    }

    /// Was in der Tasse steht. Wasser bleibt weg, wo es sich versteht — eine
    /// Liste, die bei jeder Sorte dasselbe sagt, sagt nichts.
    var ingredients: [Ingredient] {
        switch self {
        case .espresso, .ristretto, .doppio, .lungo: [.espresso]
        case .americano: [.espresso, .wasser]
        case .filter, .mokka: [.kaffee, .wasser]
        case .coldBrew: [.kaffee, .wasser, .eis]
        case .macchiato: [.espresso, .milchschaum]
        case .cortado, .flatWhite: [.espresso, .milch]
        case .cappuccino, .latte, .latteMacchiato: [.espresso, .milch, .milchschaum]
        }
    }

    /// **Computed**, nicht gespeichert: eine statische Tabelle löste ihre Texte
    /// einmal beim Start auf, und die Sprache stünde dann fest.
    var preparation: String {
        switch self {
        case .espresso:
            String(localized: "25 ml in 25 Sekunden unter neun bar durch fein gemahlenes Pulver. Die Crema kommt vom Druck, nicht von der Röstung.")
        case .ristretto:
            String(localized: "Dasselbe Pulver, halb so viel Wasser. Dichter im Geschmack und weniger Koffein als der Espresso — die Extraktion bricht früher ab.")
        case .doppio:
            String(localized: "Zwei Espressi aus einem Sieb, in einer Tasse: doppeltes Pulver, doppelte Menge.")
        case .lungo:
            String(localized: "Doppelt so viel Wasser durch dasselbe Pulver. Länger heisst mehr Koffein und mehr Bitterstoffe.")
        case .americano:
            String(localized: "Espresso, mit heissem Wasser auf Tassengrösse verlängert. Nicht dasselbe wie Filterkaffee — der lief nie unter Druck.")
        case .filter:
            String(localized: "Heisses Wasser läuft ohne Druck durch grob gemahlenes Pulver. Keine Crema, dafür klarer.")
        case .mokka:
            String(localized: "Im Herdkännchen presst Dampfdruck das Wasser von unten durch das Pulver.")
        case .macchiato:
            String(localized: "Espresso, „befleckt\u{201C} mit einem Löffel Milchschaum. Der Name ist die Zubereitung.")
        case .cortado:
            String(localized: "Espresso, mit derselben Menge warmer Milch geschnitten — spanisch cortar. Milch, kein Schaum.")
        case .cappuccino:
            String(localized: "Je ein Drittel Espresso, warme Milch und Schaum.")
        case .latte:
            String(localized: "Espresso in viel warmer Milch, obenauf ein dünner Schaum.")
        case .latteMacchiato:
            String(localized: "Umgekehrte Reihenfolge: der Espresso kommt in die Milch, nicht die Milch in den Espresso. Daher die drei Schichten.")
        case .flatWhite:
            String(localized: "Doppelter Ristretto mit feinporigem Mikroschaum, flach eingegossen. Stärker als der Cappuccino und ohne Schaumhaube.")
        case .coldBrew:
            String(localized: "Zwölf bis zwanzig Stunden kalt gezogen statt heiss gebrüht. Wenig Säure, viel Koffein.")
        }
    }

    /// Mitgeliefertes Bild der Sorte, falls es im Katalog liegt. Solange keins
    /// da ist, bleibt der Platz oben leer — wie bei einer Mahlzeit ohne Foto.
    var image: UIImage? { UIImage(named: "coffee/" + rawValue) }

    /// Schreibweise egal, Akzente egal: „Caffè Latte" und „caffe latte" führen
    /// zur selben Karte.
    static func of(_ name: String) -> CoffeeInfo? {
        let wanted = fold(name)
        return allCases.first { fold($0.preset) == wanted }
    }

    private static func fold(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .replacingOccurrences(of: " ", with: "")
    }

    enum Ingredient {
        case espresso, kaffee, wasser, milch, milchschaum, eis

        var label: String {
            switch self {
            case .espresso: String(localized: "Espresso")
            case .kaffee: String(localized: "Kaffee")
            case .wasser: String(localized: "Wasser")
            case .milch: String(localized: "Milch")
            case .milchschaum: String(localized: "Milchschaum")
            case .eis: String(localized: "Eis")
            }
        }
    }
}
