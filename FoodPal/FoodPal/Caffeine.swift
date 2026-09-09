import Foundation

/// Belegte Koffeinwerte für Getränke, die keine Kaffeesorte sind.
///
/// Die Kaffeeauswahl hat ihre eigenen Werte je Sorte (`CoffeePreset`). Was
/// hier steht, ist für den anderen Weg: eine Mahlzeit, in der ein Energydrink,
/// eine Cola oder ein Tee **vorkommt**. Ohne diese Tabelle schätzt das Modell
/// die Milligramm frei — und schätzt sie bei genau den Getränken daneben, bei
/// denen der Wert öffentlich und exakt bekannt ist.
///
/// Quellen (geprüft am 9. September 2026):
///
/// - Red Bull: 80 mg je 250-ml-Dose, laut Hersteller — 32 mg/100 ml
/// - Monster: 160 mg je 500-ml-Dose — 32 mg/100 ml, derselbe Wert
/// - alles Übrige: EUFIC nach EFSA, „Caffeine levels in different foods and
///   drinks" — Filterkaffee 90 mg/200 ml, Espresso 80 mg/60 ml, Schwarztee
///   55 mg/250 ml, Grüntee 38 mg/250 ml, Cola 37 mg/355 ml, Energydrink
///   80 mg/250 ml, Schokoladenmilch 34 mg/200 ml
///
/// 32 mg/100 ml ist in der EU faktisch die Obergrenze für Energydrinks; dass
/// Red Bull und Monster denselben Wert tragen, ist deshalb kein Zufall.
enum Caffeine {
    /// Ein bekanntes Getränk: Milligramm je 100 ml (bei Schokolade je 100 g)
    /// und die übliche Portion, falls keine Menge genannt wurde.
    struct Known {
        let mgPer100: Double
        let typicalMl: Double
    }

    /// Reihenfolge zählt: „red bull" muss vor „energy" stehen, sonst greift
    /// der allgemeine Fall zuerst und die 500er Dose bekäme 250 ml.
    ///
    /// `nicht` fängt die Wörter ab, in denen ein Schlüssel zufällig steckt.
    /// Deutsche Komposita zwingen zur Teilzeichenkette — „Milchkaffee" und
    /// „Energydrink" wären mit Wortgrenzen nicht zu finden —, und die holt
    /// sich sonst **Rucola** als Cola und **Tomate** als Mate.
    private static let table: [(keys: [String], nicht: [String], value: Known)] = [
        (["red bull", "redbull"], [],       .init(mgPer100: 32, typicalMl: 250)),
        (["monster"], [],                   .init(mgPer100: 32, typicalMl: 500)),
        (["rockstar", "energy", "energie-drink", "energiedrink"], [],
                                            .init(mgPer100: 32, typicalMl: 250)),
        (["club-mate", "club mate", "clubmate", "matetee", "mate-tee"], [],
                                            .init(mgPer100: 20, typicalMl: 500)),
        (["cola", "pepsi", "coke"], ["rucola"],
                                            .init(mgPer100: 11, typicalMl: 330)),
        (["espresso", "ristretto"], [],     .init(mgPer100: 134, typicalMl: 60)),
        (["entkoffeiniert", "koffeinfrei", "decaf"], [],
                                            .init(mgPer100: 2, typicalMl: 200)),
        (["filterkaffee", "kaffee", "coffee", "americano", "lungo"], [],
                                            .init(mgPer100: 45, typicalMl: 200)),
        (["schwarztee", "schwarzer tee", "black tea", "earl grey", "assam"], [],
                                            .init(mgPer100: 22, typicalMl: 250)),
        (["gruentee", "gruener tee", "green tea", "sencha"], [],
                                            .init(mgPer100: 15, typicalMl: 250)),
        (["kakao", "schokoladenmilch", "chocolate milk"], [],
                                            .init(mgPer100: 17, typicalMl: 200))
    ]

    /// Findet das Getränk in einer Bezeichnung. Ohne Rücksicht auf Gross- und
    /// Kleinschreibung und auf Umlaute — „Grüntee" und „Gruentee" sind
    /// dasselbe Getränk.
    static func known(for name: String) -> Known? {
        let needle = fold(name)
        guard !needle.isEmpty else { return nil }
        return table.first { entry in
            entry.keys.contains { needle.contains(fold($0)) }
                && !entry.nicht.contains { needle.contains(fold($0)) }
        }?.value
    }

    /// Der Rückfall: Milligramm für die übliche Portion. Greift nur, wenn das
    /// Modell gar keinen Wert geliefert hat — steht eine Menge im Text, hat
    /// seine eigene Rechnung Vorrang.
    static func typicalMg(for name: String) -> Double? {
        known(for: name).map { ($0.mgPer100 * $0.typicalMl / 100).rounded() }
    }

    /// Die Werte für den Prompt, damit das Modell nicht raten muss.
    static let hint = "Red Bull und Monster 32, Cola 11, Club-Mate 20, "
        + "Filterkaffee 45, Espresso 134, Schwarztee 22, Grüntee 15, Kakao 17"

    /// Umlaute **deutsch** aufgelöst, nicht bloss entkleidet: `folding` macht
    /// aus „ü" ein „u", damit fände „Gruentee" das „Grüntee" nie. Erst ä→ae,
    /// dann der Rest.
    private static func fold(_ text: String) -> String {
        var out = text.lowercased(with: Locale(identifier: "de"))
        for (umlaut, plain) in [("ä", "ae"), ("ö", "oe"), ("ü", "ue"), ("ß", "ss")] {
            out = out.replacingOccurrences(of: umlaut, with: plain)
        }
        return out.folding(options: [.diacriticInsensitive, .caseInsensitive],
                           locale: Locale(identifier: "de"))
    }
}
