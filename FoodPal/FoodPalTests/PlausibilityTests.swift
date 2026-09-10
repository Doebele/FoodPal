import Testing
@testable import FoodPal

/// Der Hinweis ist ein Hinweis. Er darf nicht bei normalen Werten anspringen,
/// er darf beim Tippen nicht flackern, und er darf an keiner Zahl scheitern.
struct PlausibilityTests {

    @Test func plausiblesBleibtStumm() {
        #expect(Plausibility.note(kcal: 850, caffeineMg: 63) == nil)
        #expect(Plausibility.note(kcal: nil, caffeineMg: nil) == nil)
        #expect(Plausibility.note(kcal: 2400, caffeineMg: 400) == nil)
        // Die Schwelle selbst loest noch nicht aus — nur was darueber liegt.
        #expect(Plausibility.note(kcal: Plausibility.mealKcal, caffeineMg: nil) == nil)
        #expect(Plausibility.note(kcal: nil, caffeineMg: Plausibility.drinkCaffeineMg) == nil)
    }

    @Test func unsinnBekommtSeinenSatz() {
        #expect(Plausibility.note(kcal: 62_000, caffeineMg: nil) != nil)
        #expect(Plausibility.note(kcal: nil, caffeineMg: 5_000) != nil)
    }

    /// Der Satz haengt an der Zahl und nicht am Zufall: beim Tippen aendert
    /// sich der Wert bei jedem Anschlag, und ein gewuerfelter Satz spraenge
    /// mit. Zweimal dieselbe Zahl muss zweimal denselben Satz geben.
    @Test func derselbeWertGibtDenselbenSatz() {
        for wert in [4_001.0, 12_345.0, 999_999.0] {
            #expect(Plausibility.note(kcal: wert, caffeineMg: nil)
                    == Plausibility.note(kcal: wert, caffeineMg: nil))
        }
    }

    /// Der Satz wird ueber den Rest einer Ganzzahl gewaehlt. Ohne Deckel
    /// liefe die Umwandlung bei sehr grossen Werten ueber und riss die App
    /// mit — genau die Eingabe also, fuer die der Hinweis gedacht ist.
    @Test func riesigeZahlenBringenNichtsZumAbsturz() {
        #expect(Plausibility.note(kcal: .greatestFiniteMagnitude, caffeineMg: nil) != nil)
        #expect(Plausibility.note(kcal: nil, caffeineMg: 1e300) != nil)
    }
}
