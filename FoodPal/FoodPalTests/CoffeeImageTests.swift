import Testing
import UIKit
@testable import FoodPal

/// Der Bildname entsteht zweimal: in `tools/kaffeebilder_auswahl.py`, das den
/// Asset-Katalog fuellt, und in `CoffeeInfo.fold`, das ihn zur Laufzeit sucht.
/// Laufen die beiden Faltungen auseinander, findet die App nichts — und sagt
/// nichts, sie zeigt einfach kein Bild. Deshalb dieser Test.
struct CoffeeImageTests {

    @Test func jedeSorteHatIhrBild() {
        for preset in CoffeePreset.all {
            #expect(CoffeeInfo.image(for: preset.name) != nil, "kein Bild: \(preset.name)")
        }
    }

    @Test func schreibweiseIstEgal() {
        #expect(CoffeeInfo.image(for: "caffe latte") != nil)
        #expect(CoffeeInfo.image(for: "CAFFÈ LATTE") != nil)
    }

    @Test func unbekanntesBleibtLeer() {
        #expect(CoffeeInfo.image(for: "Bratwurst") == nil)
    }
}
