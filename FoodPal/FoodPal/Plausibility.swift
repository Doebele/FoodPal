import SwiftUI

/// Wo eine Zahl nicht stimmen kann, sagt die App es — und speichert sie
/// trotzdem.
///
/// **Geprüft wird der einzelne Eintrag, nicht die Tagessumme.** Eine
/// Tagessumme über zehntausend Kilokalorien ist selten, aber sie kommt vor,
/// und wer sie erreicht, hat keinen Kommentar von einer App verdient — schon
/// gar keinen witzigen. Eine einzelne *Mahlzeit* über 4000 kcal dagegen ist
/// fast immer eine verrutschte Stelle beim Tippen oder eine Halluzination des
/// Modells. Dort verdient sich eine Rückfrage ihr Geld, und dort hilft sie.
///
/// Es ist ein **Hinweis, kein Riegel.** Der Sichern-Knopf bleibt, wie er ist.
/// Ein Tagebuch, das sich weigert aufzuschreiben, was passiert ist, ist keins
/// — und in Apple Health bliebe eine Lücke, die niemand mehr füllt.
enum Plausibility {
    /// Ein sehr grosses Restaurantessen liegt bei 2000 bis 2500 kcal. Was
    /// darüber hinausgeht, passt auf keinen Teller.
    static let mealKcal: Double = 4000
    /// Das stärkste Getränk im Bestand trägt 280 mg. Tausend in **einem** Glas
    /// ist keine Portion mehr, sondern ein Tippfehler.
    static let drinkCaffeineMg: Double = 1000

    /// Der Satz zu einem Wert, oder `nil`, wenn beide plausibel sind.
    static func note(kcal: Double?, caffeineMg: Double?) -> String? {
        if let kcal, kcal > mealKcal { return pick(kcalNotes, by: kcal) }
        if let caffeineMg, caffeineMg > drinkCaffeineMg { return pick(caffeineNotes, by: caffeineMg) }
        return nil
    }

    /// **Aus der Zahl gewählt, nicht gewürfelt.** Beim Tippen ändert sich der
    /// Wert bei jedem Anschlag; ein zufälliger Satz spränge bei jedem mit und
    /// wäre nicht zu lesen. So gehört zu jeder Zahl derselbe Satz, und
    /// verschiedene Zahlen bekommen verschiedene.
    private static func pick(_ lines: [String], by value: Double) -> String {
        lines[Int(min(value, 1e9).rounded()) % lines.count]
    }

    /// Der Witz zielt auf die **Zahl**, nie auf den, der sie eingegeben hat.
    /// „Ein Blauwal schafft das" lacht über eine Menge; „du isst wie ein Wal"
    /// lacht über einen Menschen. Der Unterschied ist der ganze Punkt.
    private static var kcalNotes: [String] {
        [
            String(localized: "Ein Blauwal schafft das. Der frisst allerdings Krill, und zwar den ganzen Tag."),
            String(localized: "Zwei Tagesbedarfe auf einem Teller — ist da eine Null zu viel?"),
            String(localized: "So viel passt in eine Mahlzeit nur, wenn beim Tippen eine Stelle verrutscht ist.")
        ]
    }

    private static var caffeineNotes: [String] {
        [
            String(localized: "Über tausend Milligramm wären eine Kanne, keine Tasse."),
            String(localized: "So viel Koffein steckt in rund zwanzig Espressi.")
        ]
    }
}

/// Der Satz unter den Zahlen. Ruhig gesetzt und in `ink2` — es ist eine
/// Bemerkung, kein Fehler. Rot wäre eine Warnung, und gewarnt wird hier nicht.
struct PlausibilityNote: View {
    let kcal: String
    let caffeine: String

    var body: some View {
        if let satz = Plausibility.note(kcal: Double(kcal), caffeineMg: Double(caffeine)) {
            Text(satz)
                .scaledFont(12)
                .foregroundStyle(Palette.ink2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 20)
        }
    }
}
