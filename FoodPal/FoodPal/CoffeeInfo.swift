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
    case pfluemli, fertig, baileys

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
        case .pfluemli: "Schümli Pflümli"
        case .fertig: "Kafi Fertig"
        case .baileys: "Café Baileys"
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
        case .pfluemli: [.kaffee, .obstbrand, .zucker, .schlagrahm]
        case .fertig: [.kaffee, .obstbrand, .zucker]
        case .baileys: [.kaffee, .irishCream, .schlagrahm]
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
            String(localized: "Ein doppelter Espresso und gleich viel warme Milch — spanisch cortar, „schneiden\u{201C}: die Milch nimmt Säure und Bitterkeit, ohne den Kaffee zu verwässern. Nur leicht aufgeschäumt, feinporig statt luftig.")
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
        case .pfluemli:
            String(localized: "Zucker ins vorgewärmte Stielglas, Pflümli darüber, mit Kaffee auffüllen bis einen Finger unter den Rand, Schlagrahm obenauf.")
        case .fertig:
            String(localized: "Drei Würfelzucker ins Glas, Kaffee darüber, bis man sie nicht mehr sieht — dann Träsch, bis man sie wieder sieht.")
        case .baileys:
            String(localized: "Vier Zentiliter Irish Cream ins vorgewärmte Glas, den heissen Kaffee über den Löffelrücken darübergiessen, halbsteifen Rahm obenauf.")
        }
    }

    /// Woher sie kommt — **optional**. Ristretto, Doppio und Lungo stehen ohne:
    /// es sind Spielarten des Espresso, und „Italien" dreimal zu wiederholen
    /// wäre eine Zeile, die nichts sagt. Ein Feld, das nur erscheint, wo es
    /// etwas zu sagen hat, wird auch gelesen.
    var origin: String? {
        switch self {
        case .ristretto, .doppio, .lungo: nil
        case .espresso:
            String(localized: "Italien, um 1900. Die Maschine war zuerst da — das Getränk ist nach ihr benannt.")
        case .americano:
            String(localized: "Italien, Zweiter Weltkrieg: die Geschichte erzählt von amerikanischen Soldaten, denen der Espresso zu klein war.")
        case .filter:
            String(localized: "Dresden, 1908. Melitta Bentz legte ein Löschblatt in einen durchlöcherten Messingtopf und meldete es zum Patent an.")
        case .mokka:
            String(localized: "Benannt nach Mokka, dem jemenitischen Hafen, über den Kaffee jahrhundertelang nach Europa kam.")
        case .macchiato:
            String(localized: "Italien, aus dem Bar-Jargon: „macchiato\u{201C} sagte der Barista dem Kellner, damit der die Tasse mit Milch von der ohne unterscheiden konnte.")
        case .cortado:
            String(localized: "Spanien, oft dem Baskenland oder Katalonien zugeschrieben; auch in Portugal und Lateinamerika zu Hause. Serviert im kleinen Glas, 60 bis 70 ml.")
        case .cappuccino:
            String(localized: "Italien. Der Name kommt von der Kutte der Kapuziner — nach der Farbe, nicht nach dem Schaum.")
        case .latte:
            String(localized: "Nicht Italien: dort bekommt man auf „un latte\u{201C} ein Glas Milch. Als Getränk mit Namen entstand er in den USA.")
        case .latteMacchiato:
            String(localized: "Italien, ursprünglich die Fassung für Kinder: viel Milch, mit Kaffee nur befleckt.")
        case .flatWhite:
            String(localized: "Australien oder Neuseeland, 1980er-Jahre — welches von beiden, streiten beide bis heute.")
        case .coldBrew:
            String(localized: "Zwei Linien: der langsame Tropfturm aus Kyoto und der Kaltauszug aus New Orleans, dort mit Zichorie.")
        case .pfluemli:
            String(localized: "Schweizer Wintergetränk, nach dem Skitag. „Schümli\u{201C} ist der Kaffee mit seinem Schaum, „Pflümli\u{201C} der Zwetschgenbrand dazu.")
        case .fertig:
            String(localized: "Innerschweiz. In Luzern heisst er Kafi Luz oder Träschkaffee, in Bern Kafi Fertig — dasselbe Getränk. Entstanden aus Sparsamkeit: dünner Kaffee, gestreckt mit Selbstgebranntem. Die Regel dazu lautet, durch einen richtigen müsse man Zeitung lesen können.")
        case .baileys:
            String(localized: "Der jüngste im Feld: Irish Cream gibt es erst seit 1974. Zum Irish Coffee verhält er sich wie Rahm zu Whiskey — süsser, milder, und der Alkohol versteckt sich.")
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
        case zucker, obstbrand, schlagrahm, irishCream

        var label: String {
            switch self {
            case .espresso: String(localized: "Espresso")
            case .kaffee: String(localized: "Kaffee")
            case .wasser: String(localized: "Wasser")
            case .milch: String(localized: "Milch")
            case .milchschaum: String(localized: "Milchschaum")
            case .eis: String(localized: "Eis")
            case .zucker: String(localized: "Zucker")
            case .obstbrand: String(localized: "Obstbrand")
            case .schlagrahm: String(localized: "Schlagrahm")
            case .irishCream: String(localized: "Irish Cream")
            }
        }
    }
}
