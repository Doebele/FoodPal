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
    case creme, schale, melange, auLait
    case espressoTonic, icedLatte, icedAmericano, nitro, suessrahm
    case caramelMacchiato, vanillaLatte, mocha, whiteMocha, pumpkinSpice
    case frappe, freddoEspresso, freddoCappuccino
    case tuerkisch, barraquito, bombon, marocchino, einspaenner
    case carajillo, irish, affogato, suaDa

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
        case .creme: "Kaffee Crème"
        case .schale: "Schale"
        case .melange: "Wiener Melange"
        case .auLait: "Café au Lait"
        case .espressoTonic: "Espresso Tonic"
        case .icedLatte: "Iced Latte"
        case .icedAmericano: "Iced Americano"
        case .nitro: "Nitro Cold Brew"
        case .suessrahm: "Cold Brew Süssrahm"
        case .caramelMacchiato: "Caramel Macchiato"
        case .vanillaLatte: "Vanilla Latte"
        case .mocha: "Caffè Mocha"
        case .whiteMocha: "White Chocolate Mocha"
        case .pumpkinSpice: "Pumpkin Spice Latte"
        case .frappe: "Frappé"
        case .freddoEspresso: "Freddo Espresso"
        case .freddoCappuccino: "Freddo Cappuccino"
        case .tuerkisch: "Türkischer Mokka"
        case .barraquito: "Barraquito"
        case .bombon: "Café Bombón"
        case .marocchino: "Marocchino"
        case .einspaenner: "Einspänner"
        case .carajillo: "Carajillo"
        case .irish: "Irish Coffee"
        case .affogato: "Affogato"
        case .suaDa: "Cà phê sữa đá"
        }
    }

    /// Was in der Tasse steht. Wasser bleibt weg, wo es sich versteht — eine
    /// Liste, die bei jeder Sorte dasselbe sagt, sagt nichts.
    var ingredients: [Ingredient] {
        switch self {
        case .espresso, .ristretto, .doppio, .lungo: [.espresso]
        case .americano: [.espresso, .wasser]
        case .filter, .mokka, .creme: [.kaffee, .wasser]
        case .coldBrew: [.kaffee, .wasser, .eis]
        case .macchiato: [.espresso, .milchschaum]
        case .cortado, .flatWhite: [.espresso, .milch]
        case .cappuccino, .latte, .latteMacchiato: [.espresso, .milch, .milchschaum]
        case .pfluemli: [.kaffee, .obstbrand, .zucker, .schlagrahm]
        case .fertig: [.kaffee, .obstbrand, .zucker]
        case .baileys: [.kaffee, .irishCream, .schlagrahm]
        case .schale, .auLait: [.kaffee, .milch]
        case .melange: [.espresso, .milch, .milchschaum]
        case .espressoTonic: [.espresso, .tonic, .eis]
        case .icedLatte: [.espresso, .milch, .eis]
        case .icedAmericano: [.espresso, .wasser, .eis]
        case .nitro: [.kaffee, .wasser, .stickstoff]
        case .suessrahm: [.kaffee, .wasser, .eis, .suessrahm, .vanille]
        case .caramelMacchiato: [.espresso, .milch, .milchschaum, .vanille, .karamell]
        case .vanillaLatte: [.espresso, .milch, .vanille]
        case .mocha: [.espresso, .milch, .schokolade]
        case .whiteMocha: [.espresso, .milch, .weisseSchokolade]
        case .pumpkinSpice: [.espresso, .milch, .kuerbisgewuerz]
        case .frappe: [.instant, .wasser, .eis, .zucker]
        case .freddoEspresso: [.espresso, .eis]
        case .freddoCappuccino: [.espresso, .eis, .kaltschaum]
        case .tuerkisch: [.kaffee, .wasser, .zucker]
        case .barraquito: [.kondensmilch, .likoer, .espresso, .milchschaum, .zimt, .zitrone]
        case .bombon: [.espresso, .kondensmilch]
        case .marocchino: [.espresso, .schokolade, .milchschaum]
        case .einspaenner: [.espresso, .schlagrahm]
        case .carajillo: [.espresso, .weinbrand]
        case .irish: [.kaffee, .whiskey, .zucker, .schlagrahm]
        case .affogato: [.vanilleeis, .espresso]
        case .suaDa: [.kaffee, .kondensmilch, .eis]
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
        case .creme:
            String(localized: "Rund 120 ml in 25 bis 30 Sekunden durch 17 g gröber gemahlenes Pulver — ein einziger Durchlauf und kein verlängerter Espresso. Rahm und Zucker kommen daneben, nicht hinein.")
        case .schale:
            String(localized: "Kaffee und heisse Milch zu gleichen Teilen. Wer sie heller mag, bestellt eine Schale Gold — benannt nach der Farbe, nicht nach der Menge.")
        case .melange:
            String(localized: "Ein verlängerter Espresso und gleich viel warme Milch, obenauf eine feine Schaumhaube. Der Unterschied zum Cappuccino ist das Verhältnis: dort mehr Schaum als Kaffee, hier eins zu eins.")
        case .auLait:
            String(localized: "Filterkaffee und heisse Milch zu gleichen Teilen, beides zugleich in die Schale gegossen. Kein Schaum, keine Haube.")
        case .espressoTonic:
            String(localized: "Eis ins Glas, Tonic darüber, zuletzt der Espresso über den Löffelrücken. Umgekehrt reisst die Kohlensäure die Schichten sofort auseinander.")
        case .icedLatte:
            String(localized: "Espresso auf kalte Milch und Eis. Heiss auf kalt bleibt geschichtet, bis man rührt — das ist kein Fehler, sondern die Reihenfolge.")
        case .icedAmericano:
            String(localized: "Espresso, kaltes Wasser, Eis. Ohne Milch steht die Säure vorn, deshalb schmeckt er kalt schärfer als heiss.")
        case .nitro:
            String(localized: "Cold Brew mit Stickstoff versetzt und über einen Zapfhahn gezogen. Die feinen Bläschen ergeben eine Schaumkrone und den Eindruck von Süsse, ohne dass Zucker drin wäre. Eis kommt keins dazu: es würde ihn verwässern und den Schaum töten.")
        case .suessrahm:
            String(localized: "Cold Brew über Eis, darauf kalt geschlagener Süssrahm mit Vanille. Er sinkt langsam durch den Kaffee — das Muster gehört zum Getränk.")
        case .caramelMacchiato:
            String(localized: "Vanillesirup, warme Milch, Schaum — und der Espresso zuletzt obendrauf statt zuerst hinein. Darüber ein Gitter aus Karamell.")
        case .vanillaLatte:
            String(localized: "Caffè Latte mit Vanillesirup, eingerührt statt aufgesetzt.")
        case .mocha:
            String(localized: "Espresso auf Schokoladensauce, mit warmer Milch aufgefüllt, meist mit Schlagrahm obenauf.")
        case .whiteMocha:
            String(localized: "Wie der Mocha, aber mit weisser Schokolade: die enthält keine Kakaomasse, sondern Kakaobutter, Zucker und Milch. Deshalb süsser und ohne jede Bitterkeit.")
        case .pumpkinSpice:
            String(localized: "Caffè Latte mit Kürbisgewürz — Zimt, Muskat, Ingwer, Nelke. Der Kürbis selbst ist optional und kam erst Jahre nach dem Getränk hinein.")
        case .frappe:
            String(localized: "Instantkaffee, wenig Wasser und Zucker im Shaker schaumig schütteln, dann Eis und kaltes Wasser dazu. Der Schaum hält, weil Instantpulver anders schäumt als gebrühter Kaffee.")
        case .freddoEspresso:
            String(localized: "Doppelter Espresso, mit Eis im Shaker kalt geschüttelt und über frisches Eis abgegossen. Das Schütteln kühlt ihn und macht ihn cremig.")
        case .freddoCappuccino:
            String(localized: "Freddo Espresso, darauf kalt geschäumte Milch — auf Griechisch afrogala. Sie darf nicht warm werden, sonst fällt sie zusammen.")
        case .tuerkisch:
            String(localized: "Staubfein gemahlen, mit Wasser und Zucker im Cezve langsam aufgeschäumt und nicht gekocht. Ungefiltert eingeschenkt: der Satz bleibt in der Tasse stehen.")
        case .barraquito:
            String(localized: "Sechs Schichten von unten: gezuckerte Kondensmilch, Licor 43, Espresso über den Löffelrücken, Milchschaum, Zimt, Zitronenschale. Gerührt wird erst am Tisch.")
        case .bombon:
            String(localized: "Gezuckerte Kondensmilch ins Glas, Espresso vorsichtig darüber. Gleiche Teile, zwei Schichten — man sieht die Grenze.")
        case .marocchino:
            String(localized: "Geschmolzene Schokolade im kleinen Glas verstrichen, Espresso darauf, Milchschaum darüber, Kakao obenauf.")
        case .einspaenner:
            String(localized: "Ein kleiner Mokka im Henkelglas, darauf eine dicke Haube Schlagobers. Der Rahm hält den Kaffee warm und hält ihn beim Fahren im Glas.")
        case .carajillo:
            String(localized: "Espresso mit einem Schuss Weinbrand. In Mexiko stattdessen Licor 43, kalt über Eis geschüttelt — dasselbe Wort, ein anderes Getränk.")
        case .irish:
            String(localized: "Zucker im heissen Kaffee auflösen, Whiskey dazu, halbsteifen Rahm über den Löffelrücken aufschwimmen lassen. Getrunken wird durch den Rahm hindurch, nicht gerührt.")
        case .affogato:
            String(localized: "Eine Kugel Vanilleeis, ein heisser Espresso darüber. „Affogato\u{201C} heisst ertränkt.")
        case .suaDa:
            String(localized: "Der Phin-Filter steht auf dem Glas und tropft langsam auf gezuckerte Kondensmilch. Umrühren, auf Eis giessen.")
        }
    }

    /// Woher sie kommt — **optional**. Ristretto, Doppio und Lungo stehen ohne:
    /// es sind Spielarten des Espresso, und „Italien" dreimal zu wiederholen
    /// wäre eine Zeile, die nichts sagt. Ein Feld, das nur erscheint, wo es
    /// etwas zu sagen hat, wird auch gelesen.
    var origin: String? {
        switch self {
        case .ristretto, .doppio, .lungo: nil
        case .icedLatte, .icedAmericano, .vanillaLatte, .whiteMocha: nil
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
        case .creme:
            String(localized: "Der Standardkaffee der Schweiz. „Schümli\u{201C} heisst er nach seiner Crema, und das Crème im Namen meint den Kaffeerahm, der danebensteht — nicht die Krone.")
        case .schale:
            String(localized: "Schweiz, benannt nach dem Gefäss: früher stand er in einer Schale auf dem Tisch, heute in der Tasse mit Henkel. Die Steigerung lautet Espresso, Café Crème, Doppel-Crème, Schale.")
        case .melange:
            String(localized: "Wien. Im klassischen Kaffeehaus steht kein Cappuccino auf der Karte — wer einen will, bestellt eine Melange. Die Basis ist heller geröstet als der italienische Espresso.")
        case .auLait:
            String(localized: "Frankreich, zum Frühstück, in der Schale ohne Henkel — gross genug, um das Croissant hineinzutauchen.")
        case .espressoTonic:
            String(localized: "Skandinavien, 2000er-Jahre, dem schwedischen Röster Koppi zugeschrieben. Die Bitterkeit des Chinins und die Säure des Kaffees ziehen in dieselbe Richtung.")
        case .nitro:
            String(localized: "USA, um 2013. Die Idee kommt vom Stout: Zapfhahn, Stickstoff und der Schaum, der nach dem Einschenken langsam absinkt.")
        case .suessrahm:
            String(localized: "Eine Starbucks-Erfindung von 2016, inzwischen überall auf der Karte.")
        case .caramelMacchiato:
            String(localized: "Starbucks, 1996. Mit dem Macchiato aus der italienischen Bar teilt er nur den Namen: dort wird die Milch in den Espresso gegeben, hier der Espresso auf die Milch.")
        case .mocha:
            String(localized: "Der Name führt in die Irre: gemeint ist der jemenitische Hafen Mokka und der schokoladige Ton seines Kaffees — nicht die Schokolade, die heute drin ist.")
        case .pumpkinSpice:
            String(localized: "Starbucks, 2003. In den USA läutet er den Herbst ein, ungefähr so verlässlich wie der Kalender.")
        case .frappe:
            String(localized: "Thessaloniki, Messe 1957: ein Nestlé-Mitarbeiter fand kein heisses Wasser, griff zum Shaker vom Nachbarstand und schüttelte seinen Nescafé kalt.")
        case .freddoEspresso:
            String(localized: "Griechenland, frühe 1990er. Anders als der Frappé aus echtem Espresso — das ist der ganze Unterschied und der ganze Streit.")
        case .freddoCappuccino:
            String(localized: "Griechenland, und heute das meistgetrunkene kalte Kaffeegetränk des Landes.")
        case .tuerkisch:
            String(localized: "Osmanisch, seit dem 16. Jahrhundert. Die Zubereitung steht seit 2013 auf der Unesco-Liste des immateriellen Kulturerbes.")
        case .barraquito:
            String(localized: "Teneriffa, benannt nach einem Stammgast: Sebastián, genannt „el Barraco\u{201C}, bestellte ihn immer genau so.")
        case .bombon:
            String(localized: "Valencia, von dort über ganz Spanien. Die Verwandtschaft mit dem vietnamesischen Eiskaffee liegt auf der Hand, die Verwandtschaftslinie nicht.")
        case .marocchino:
            String(localized: "Alessandria im Piemont. Der Name meint nicht Marokko, sondern eine Farbe: das hellbraune Ziegenleder, aus dem die Hutfabrik Borsalino am Ort ihre Bänder schnitt.")
        case .einspaenner:
            String(localized: "Wien, benannt nach dem einspännigen Fuhrwerk. Der Kutscher hielt die Zügel in der einen Hand und das Henkelglas in der anderen.")
        case .carajillo:
            String(localized: "Kuba unter spanischer Herrschaft: die Truppe mischte Rum in den Kaffee, für den Mut — spanisch coraje. Aus corajillo wurde carajillo.")
        case .irish:
            String(localized: "Foynes, Irland, 1943. Der Küchenchef Joe Sheridan wärmte damit gestrandete Flugpassagiere auf; auf die Frage, ob das brasilianischer Kaffee sei, soll er geantwortet haben, es sei irischer.")
        case .affogato:
            String(localized: "Italien — und dort kein Kaffee, sondern ein Dessert. Er steht bei den Süssspeisen auf der Karte.")
        case .suaDa:
            String(localized: "Vietnam. Robusta statt Arabica, Kondensmilch statt frischer: beides kam aus der Not und ist geblieben, weil es zusammenpasst.")
        }
    }

    /// Mitgeliefertes Bild der Sorte, falls es im Katalog liegt. Solange keins
    /// da ist, bleibt der Platz oben leer — wie bei einer Mahlzeit ohne Foto.
    /// Das Bild haengt am **Namen**, nicht an dieser Aufzaehlung — auch wenn
    /// beide inzwischen alle Sorten kennen.
    static func image(for name: String) -> UIImage? {
        UIImage(named: "coffee/" + fold(name))
    }

    /// Schreibweise egal, Akzente egal: „Caffè Latte" und „caffe latte" führen
    /// zur selben Karte.
    static func of(_ name: String) -> CoffeeInfo? {
        let wanted = fold(name)
        return allCases.first { fold($0.preset) == wanted }
    }

    /// Das `đ` aus „Cà phê sữa đá" ist ein eigener Buchstabe und kein d mit
    /// Zeichen darauf — die Faltung laesst es stehen. Alles, was danach noch
    /// nicht ASCII ist, faellt weg: das Ergebnis benennt auch die Bilddatei.
    private static func fold(_ text: String) -> String {
        text.replacingOccurrences(of: "đ", with: "d")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .filter { $0.isASCII && ($0.isLetter || $0.isNumber) }
    }

    enum Ingredient {
        case espresso, kaffee, wasser, milch, milchschaum, eis
        case zucker, obstbrand, schlagrahm, irishCream
        case kondensmilch, kaltschaum, suessrahm, stickstoff, instant
        case schokolade, weisseSchokolade, vanilleeis, tonic
        case vanille, karamell, kuerbisgewuerz, zimt, zitrone
        case likoer, weinbrand, whiskey

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
            case .kondensmilch: String(localized: "gezuckerte Kondensmilch")
            case .kaltschaum: String(localized: "kalter Milchschaum")
            case .suessrahm: String(localized: "Süssrahm")
            case .stickstoff: String(localized: "Stickstoff")
            case .instant: String(localized: "Instantkaffee")
            case .schokolade: String(localized: "Schokolade")
            case .weisseSchokolade: String(localized: "weisse Schokolade")
            case .vanilleeis: String(localized: "Vanilleeis")
            case .tonic: String(localized: "Tonic Water")
            case .vanille: String(localized: "Vanillesirup")
            case .karamell: String(localized: "Karamell")
            case .kuerbisgewuerz: String(localized: "Kürbisgewürz")
            case .zimt: String(localized: "Zimt")
            case .zitrone: String(localized: "Zitronenschale")
            case .likoer: String(localized: "Likör")
            case .weinbrand: String(localized: "Weinbrand")
            case .whiskey: String(localized: "Whiskey")
            }
        }
    }
}
