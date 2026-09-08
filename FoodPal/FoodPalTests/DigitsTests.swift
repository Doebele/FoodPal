import Foundation
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

/// Die Jetzt-Kerbe sitzt in der Spalte der laufenden Viertelstunde — dieselbe
/// Auflösung, in der auch die Einträge rasten.
struct NowColumnTests {

    private func at(_ hour: Int, _ minute: Int) -> Date {
        Calendar.current.date(from: DateComponents(
            year: 2026, month: 9, day: 8, hour: hour, minute: minute
        ))!
    }

    @Test(arguments: [(0, 0, 0), (0, 14, 0), (0, 15, 1), (0, 59, 3), (12, 30, 50), (23, 59, 95)])
    func spalteFolgtDerViertelstunde(_ hour: Int, _ minute: Int, _ expected: Int) {
        #expect(DayMatrix.column(for: at(hour, minute)) == expected)
    }

    /// Vergangene Tage bekommen keine Kerbe — ein Jetzt gibt es dort nicht.
    @Test func ohneDatumKeineSpalte() {
        #expect(DayMatrix.column(for: nil) == nil)
    }

    @Test func spalteBleibtImRaster() {
        for hour in 0..<24 {
            for minute in stride(from: 0, to: 60, by: 7) {
                let column = DayMatrix.column(for: at(hour, minute))
                #expect(column != nil && column! >= 0 && column! < Grid.columns)
            }
        }
    }
}
