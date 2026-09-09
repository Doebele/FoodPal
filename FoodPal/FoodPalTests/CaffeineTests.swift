import Foundation
import Testing
@testable import FoodPal

/// Die Milligramm sind der Grund, warum die App zwei Bänder hat. Bei
/// Energydrinks sind sie öffentlich und exakt bekannt — geraten wird da nicht.
struct CaffeineTests {

    @Test func redBullUndMonsterNachHerstellerangabe() {
        // 80 mg je 250-ml-Dose, 160 mg je 500-ml-Dose.
        #expect(Caffeine.typicalMg(for: "Red Bull") == 80)
        #expect(Caffeine.typicalMg(for: "Monster Energy") == 160)
    }

    /// „Red Bull" enthält kein „energy", „Monster Energy" aber schon — die
    /// Reihenfolge der Tabelle muss die Marke vor die Gattung stellen, sonst
    /// bekäme die 500er Dose die 250 ml des allgemeinen Falls.
    @Test func markeSchlaegtGattung() {
        #expect(Caffeine.known(for: "Monster Energy")?.typicalMl == 500)
        #expect(Caffeine.known(for: "Energydrink")?.typicalMl == 250)
    }

    @Test func schreibweiseIstEgal() {
        #expect(Caffeine.known(for: "REDBULL") != nil)
        #expect(Caffeine.known(for: "Grüntee") != nil)
        #expect(Caffeine.known(for: "Gruentee") != nil)
        #expect(Caffeine.known(for: "grüner Tee mit Ingwer") != nil)
    }

    @Test func ohneKoffeinKeinTreffer() {
        #expect(Caffeine.known(for: "Ofengemüse") == nil)
        #expect(Caffeine.known(for: "Bowl mit Lachs") == nil)
        #expect(Caffeine.known(for: "") == nil)
    }

    /// Deutsche Komposita zwingen zur Teilzeichenkette, und die holt sich
    /// sonst zwei sehr gewöhnliche Zutaten als Getränk.
    @Test func rucolaIstKeineColaUndTomateKeinMate() {
        #expect(Caffeine.known(for: "Rucola-Salat") == nil)
        #expect(Caffeine.known(for: "Tomatensalat") == nil)
        #expect(Caffeine.known(for: "Tomate mit Mozzarella") == nil)
        // Was wirklich Mate ist, wird trotzdem gefunden.
        #expect(Caffeine.typicalMg(for: "Club-Mate") == 100)
    }

    /// Umgekehrt darf das Komposita-Verhalten nicht verlorengehen.
    @Test func kompositaWerdenGefunden() {
        #expect(Caffeine.known(for: "Milchkaffee") != nil)
        #expect(Caffeine.known(for: "Energydrink") != nil)
    }

    @Test func colaUndTeeNachEfsaWerten() {
        // 11 mg/100 ml mal 330 ml, 22 mg/100 ml mal 250 ml.
        #expect(Caffeine.typicalMg(for: "Cola") == 36)
        #expect(Caffeine.typicalMg(for: "Schwarztee") == 55)
    }

    /// Der Rückfall greift nur, wenn das Modell nichts geliefert hat. Steht
    /// eine Menge im Text, ist dessen Rechnung näher dran als eine
    /// Standardportion — „zwei Dosen Red Bull" wären sonst wieder 80 mg.
    @Test func modellwertHatVorrang() {
        let vomModell = MealEstimate(name: "Red Bull", kcal: 230, caffeineMg: 160)
        #expect(vomModell.withKnownCaffeine().caffeineMg == 160)

        let ohne = MealEstimate(name: "Red Bull", kcal: 115)
        #expect(ohne.withKnownCaffeine().caffeineMg == 80)

        let null = MealEstimate(name: "Red Bull", kcal: 115, caffeineMg: 0)
        #expect(null.withKnownCaffeine().caffeineMg == 80)
    }

    @Test func mahlzeitOhneGetraenkBleibtOhneKoffein() {
        let teller = MealEstimate(name: "Ofengemüse", kcal: 741)
        #expect(teller.withKnownCaffeine().caffeineMg == nil)
    }

    /// Der ganze Weg: gesprochener Satz mit Getränk, Modell antwortet mit
    /// Koffeinfeld, es kommt am Eintrag an.
    @Test func koffeinKommtDurchDenParser() {
        let antwort = """
        [{"name":"Burger","kcal":620,"proteinG":30,"carbsG":45,"fatG":32,"caffeineMg":0},
         {"name":"Cola 0,5 l","kcal":210,"proteinG":0,"carbsG":53,"fatG":0,"caffeineMg":55}]
        """
        let items = VisionEstimator.parseList(antwort)
        #expect(items.count == 2)
        #expect(items[0].caffeineMg == 0)
        #expect(items[1].caffeineMg == 55)
    }

    /// Vergisst das Modell das Feld, springt die Tabelle ein.
    @Test func fehlendesFeldWirdNachgetragen() {
        let antwort = #"[{"name":"Red Bull","kcal":115}]"#
        #expect(VisionEstimator.parseList(antwort).first?.caffeineMg == 80)
    }
}
