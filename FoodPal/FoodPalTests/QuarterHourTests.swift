import Foundation
import Testing
@testable import FoodPal

/// Einträge rasten in Viertelstunden — dieselbe Auflösung wie der Zeitstrahl
/// mit seinen vier Spalten je Stunde. Gerundet wird in `Entry.init`, damit
/// keine der vier Erfassungsarten es vergessen kann.
struct QuarterHourTests {

    private func at(_ day: Int, _ hour: Int, _ minute: Int) -> Date {
        Calendar.current.date(from: DateComponents(
            year: 2026, month: 9, day: day, hour: hour, minute: minute, second: 37
        ))!
    }

    @Test func rundetZurNaechstenViertelstunde() {
        #expect(at(8, 10, 7).roundedToQuarterHour == at(8, 10, 0).roundedToQuarterHour)
        #expect(Calendar.current.component(.minute, from: at(8, 10, 7).roundedToQuarterHour) == 0)
        #expect(Calendar.current.component(.minute, from: at(8, 10, 8).roundedToQuarterHour) == 15)
        #expect(Calendar.current.component(.minute, from: at(8, 10, 28).roundedToQuarterHour) == 30)
    }

    @Test func sekundenFallenWeg() {
        #expect(Calendar.current.component(.second, from: at(8, 10, 30).roundedToQuarterHour) == 0)
    }

    @Test func ueberlaufInDieNaechsteStunde() {
        let rounded = at(8, 10, 53).roundedToQuarterHour
        let parts = Calendar.current.dateComponents([.hour, .minute], from: rounded)
        #expect(parts.hour == 11)
        #expect(parts.minute == 0)
    }

    /// **Der Fall, der wehtut:** 23:58 dürfte nicht auf morgen 00:00 rollen,
    /// sonst zählte der späte Snack zum falschen Tag und verschwände aus der
    /// Ansicht, in der man ihn gerade erfasst hat.
    @Test func mitternachtWirdNichtUeberschritten() {
        let late = at(8, 23, 58)
        let rounded = late.roundedToQuarterHour
        #expect(Calendar.current.isDate(rounded, inSameDayAs: late))
        let parts = Calendar.current.dateComponents([.hour, .minute], from: rounded)
        #expect(parts.hour == 23)
        #expect(parts.minute == 45)
    }

    @Test func eintragRundetBeimAnlegen() {
        let entry = Entry(date: at(8, 12, 41), name: "Bowl", kind: .meal, kcal: 620)
        let parts = Calendar.current.dateComponents([.hour, .minute, .second], from: entry.date)
        #expect(parts.hour == 12)
        #expect(parts.minute == 45)
        #expect(parts.second == 0)
    }
}
