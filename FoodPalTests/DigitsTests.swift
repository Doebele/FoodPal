import Testing
@testable import FoodPal

/// Die Anzeige hat feste Stellen wie ein Zählwerk Räder. Leere Räder zeigen
/// die Null, sie verschwinden nicht — sonst tauchten beim Wechsel von 1849 auf
/// 74 zwei Karten auf und wieder ab.
struct DigitsTests {

    @Test func immerVierStellen() {
        #expect(Digits.of(0) == [0, 0, 0, 0])
        #expect(Digits.of(7) == [0, 0, 0, 7])
        #expect(Digits.of(189) == [0, 1, 8, 9])
        #expect(Digits.of(1849) == [1, 8, 4, 9])
    }

    /// Über vier Stellen wird nicht abgeschnitten — lieber eine Karte mehr als
    /// eine falsche Zahl.
    @Test func groessereWerteBekommenIhreStelle() {
        #expect(Digits.of(12345) == [1, 2, 3, 4, 5])
    }

    @Test func negativesGiltAlsNull() {
        #expect(Digits.of(-5) == [0, 0, 0, 0])
    }
}
