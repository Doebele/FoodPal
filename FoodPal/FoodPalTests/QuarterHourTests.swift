import Foundation
import Testing
@testable import FoodPal

/// Einträge rasten in Viertelstunden — dieselbe Auflösung wie der Zeitstrahl
/// mit seinen vier Spalten je Stunde. Geschnitten wird in `Entry.init`, damit
/// keine der vier Erfassungsarten es vergessen kann.
struct QuarterHourTests {

    private func at(_ day: Int, _ hour: Int, _ minute: Int) -> Date {
        Calendar.current.date(from: DateComponents(
            year: 2026, month: 9, day: day, hour: hour, minute: minute, second: 37
        ))!
    }

    /// **Abgerundet**, wie `startOfDay` abrundet: 9:00 bis 9:14 werden 9:00,
    /// 9:15 bis 9:29 werden 9:15.
    @Test(arguments: [(0, 0), (7, 0), (14, 0), (15, 15), (29, 15), (30, 30), (44, 30), (59, 45)])
    func schneidetAufDieLaufendeViertelstunde(_ input: Int, _ expected: Int) {
        let parts = Calendar.current.dateComponents(
            [.hour, .minute], from: at(8, 9, input).startOfQuarterHour
        )
        #expect(parts.hour == 9)
        #expect(parts.minute == expected)
    }

    @Test func sekundenFallenWeg() {
        #expect(Calendar.current.component(.second, from: at(8, 10, 30).startOfQuarterHour) == 0)
    }

    /// Abrunden kann die Stunde nicht überschreiten — und damit auch nicht den
    /// Tag. 23:58 bleibt bei 23:45, statt auf morgen zu rollen und den späten
    /// Snack zum falschen Tag zu zählen.
    @Test func nieVorwaertsUndNieUeberMitternacht() {
        let late = at(8, 23, 58)
        let floored = late.startOfQuarterHour
        #expect(floored <= late)
        #expect(Calendar.current.isDate(floored, inSameDayAs: late))
        let parts = Calendar.current.dateComponents([.hour, .minute], from: floored)
        #expect(parts.hour == 23)
        #expect(parts.minute == 45)
    }

    @Test func eintragSchneidetBeimAnlegen() {
        let entry = Entry(date: at(8, 12, 41), name: "Bowl", kind: .meal, kcal: 620)
        let parts = Calendar.current.dateComponents([.hour, .minute, .second], from: entry.date)
        #expect(parts.hour == 12)
        #expect(parts.minute == 30)
        #expect(parts.second == 0)
    }
}
