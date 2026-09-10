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
