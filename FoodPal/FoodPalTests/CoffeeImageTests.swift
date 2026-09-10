import Testing
import UIKit
@testable import FoodPal

/// Der Bildname entsteht zweimal: in `tools/kaffeebilder_auswahl.py`, das den
/// Asset-Katalog fuellt, und in `CoffeeInfo.fold`, das ihn zur Laufzeit sucht.
/// Beide muessen dasselbe ergeben. Geprueft werden die vier Namen, an denen
/// die Faltungen auseinanderlaufen koennten — Akzent, eigener Buchstabe,
/// Umlaut, scharfes s.
struct CoffeeImageTests {

    @Test func gefalteteNamenFindenIhrBild() {
        #expect(CoffeeInfo.image(for: "Caffè Latte") != nil)          // è
        #expect(CoffeeInfo.image(for: "Café Bombón") != nil)          // é, ó
        #expect(CoffeeInfo.image(for: "Cold Brew Süssrahm") != nil)   // ü, ss
        #expect(CoffeeInfo.image(for: "Cà phê sữa đá") != nil)        // đ
    }

    @Test func schreibweiseIstEgal() {
        #expect(CoffeeInfo.image(for: "caffe latte") != nil)
        #expect(CoffeeInfo.image(for: "CAFFÈ LATTE") != nil)
    }

    @Test func unbekanntesBleibtLeer() {
        #expect(CoffeeInfo.image(for: "Bratwurst") == nil)
    }
}
