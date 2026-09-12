import Testing
import UIKit
@testable import FoodPal

/// Bild und Warenkunde haengen beide an der Bezeichnung. Beim Bild entsteht der
/// Name zweimal — in `tools/kaffeebilder_auswahl.py` beim Ablegen und in
/// `CoffeeInfo.fold` beim Suchen. Laufen die Faltungen auseinander, findet die
/// App nichts und sagt nichts: sie zeigt einfach leer. Deshalb dieser Test.
struct CoffeeInfoTests {

    @Test func jedeSorteHatIhrBild() {
        for preset in CoffeePreset.all {
            #expect(CoffeeInfo.image(for: preset.name) != nil, "kein Bild: \(preset.name)")
        }
    }

    @Test func jedeSorteHatIhreWarenkunde() {
        for preset in CoffeePreset.all {
            #expect(CoffeeInfo.of(preset.name) != nil, "keine Warenkunde: \(preset.name)")
        }
    }

    /// Die Texte kommen aus dem Katalog. Ein Schluessel, der dort fehlt, faellt
    /// nicht auf — `String(localized:)` gibt dann den Schluessel selbst zurueck.
    /// Leer ist er nie, deshalb prueft das hier nur die grobe Form.
    @Test func jedeWarenkundeHatEinenSatz() {
        for sorte in CoffeeInfo.allCases {
            #expect(sorte.preparation.count > 20, "zu kurz: \(sorte.preset)")
            #expect(!sorte.ingredients.isEmpty, "keine Zutaten: \(sorte.preset)")
        }
    }

    @Test func schreibweiseIstEgal() {
        #expect(CoffeeInfo.image(for: "caffe latte") != nil)
        #expect(CoffeeInfo.of("CAFFÈ LATTE") == .latte)
    }

    @Test func unbekanntesBleibtLeer() {
        #expect(CoffeeInfo.image(for: "Bratwurst") == nil)
        #expect(CoffeeInfo.of("Bratwurst") == nil)
    }
}

/// Kalorien und Makros stehen in derselben Zeile und muessen zueinander
/// passen: Protein und Kohlenhydrate tragen 4 kcal je Gramm, Fett 9. Wer eine
/// der Zahlen aendert, ohne die anderen nachzuziehen, faellt hier auf.
struct CoffeeMacroTests {

    /// Alkohol traegt 7 kcal je Gramm und ist weder Eiweiss noch Kohlenhydrat
    /// noch Fett — bei einem Irish Coffee bleiben zwei Drittel der Kalorien
    /// deshalb ausserhalb der Makros. Welche Sorten das betrifft, weiss die
    /// Warenkunde; genau dafuer steht sie da.
    private static let geistig: Set<CoffeeInfo.Ingredient> =
        [.obstbrand, .whiskey, .weinbrand, .irishCream, .likoer]

    private func ausMakros(_ p: CoffeePreset) -> Double {
        (p.proteinG ?? 0) * 4 + (p.carbsG ?? 0) * 4 + (p.fatG ?? 0) * 9
    }

    @Test func keineSorteTraegtMehrMakrosAlsKalorien() {
        for preset in CoffeePreset.all {
            #expect(ausMakros(preset) <= preset.kcal + 12,
                    "\(preset.name): \(Int(ausMakros(preset))) aus Makros, \(Int(preset.kcal)) kcal")
        }
    }

    @Test func wasKeinenAlkoholHatIstDurchMakrosErklaert() {
        for preset in CoffeePreset.all where preset.kcal > 40 {
            let geistreich = CoffeeInfo.of(preset.name)?.ingredients
                .contains { Self.geistig.contains($0) } ?? false
            guard !geistreich else { continue }
            #expect(ausMakros(preset) >= preset.kcal * 0.85,
                    "\(preset.name): nur \(Int(ausMakros(preset))) von \(Int(preset.kcal)) kcal erklärt")
        }
    }
}
