import Foundation
import SwiftData
import Testing
@testable import FoodPal

/// Der Altbestand stand auf Minuten und Sekunden — `Entry.init` schneidet nur
/// Neues zurecht. Diese Migration zieht ihn einmalig nach.
@MainActor
struct QuarterHourMigrationTests {

    /// Frischer Speicher je Test, damit sie sich nicht gegenseitig sehen.
    private func context() throws -> ModelContext {
        UserDefaults.standard.removeObject(forKey: QuarterHourMigration.mark)
        let container = try ModelContainer(
            for: Entry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    private func at(_ hour: Int, _ minute: Int, second: Int = 41) -> Date {
        Calendar.current.date(from: DateComponents(
            year: 2026, month: 9, day: 8, hour: hour, minute: minute, second: second
        ))!
    }

    /// `Entry.init` rundet bereits — für den Altbestand muss der Test deshalb
    /// nachträglich eine krumme Zeit setzen, so wie sie in der Datenbank steht.
    private func legacy(_ context: ModelContext, _ date: Date) -> Entry {
        let entry = Entry(name: "Espresso", kind: .coffee, kcal: 2, caffeineMg: 63)
        entry.date = date
        context.insert(entry)
        return entry
    }

    @Test func schneidetDenAltbestand() throws {
        let context = try context()
        let entry = legacy(context, at(12, 41))

        let moved = QuarterHourMigration.run(context)

        #expect(moved.count == 1)
        let parts = Calendar.current.dateComponents([.hour, .minute, .second], from: entry.date)
        #expect(parts.hour == 12)
        #expect(parts.minute == 30)
        #expect(parts.second == 0)
    }

    /// Nur wirklich Verschobenes wird gemeldet — sonst zoege der Aufrufer
    /// unveraenderte Eintraege ohne Grund durch Health. Sauber heisst dabei
    /// auch **ohne Sekunden**: 9:15:41 steht nicht auf der Viertelstunde.
    @Test func meldetNurWasSichBewegt() throws {
        let context = try context()
        _ = legacy(context, at(9, 15, second: 0))
        _ = legacy(context, at(9, 17))

        let moved = QuarterHourMigration.run(context)
        #expect(moved.count == 1)
        #expect(Calendar.current.component(.minute, from: moved[0].date) == 15)
    }

    @Test func laeuftNurEinmal() throws {
        let context = try context()
        _ = legacy(context, at(9, 17))

        #expect(QuarterHourMigration.run(context).count == 1)
        // Ohne Zuruecksetzen: der zweite Lauf muss die Marke sehen.
        #expect(QuarterHourMigration.run(context).isEmpty)
    }
}
