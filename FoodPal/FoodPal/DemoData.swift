#if DEBUG
import SwiftData
import Foundation

/// Beispieltag für die Sichtprüfung, solange es keinen Erfassungs-Screen gibt.
/// Läuft nur im Debug-Build und nur, wenn der Speicher leer ist.
enum DemoData {
    static func seedIfEmpty(_ context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<Entry>())) ?? 0
        guard existing == 0 else { return }

        let day = Calendar.current.startOfDay(for: .now)
        func at(_ hour: Int, _ minute: Int) -> Date {
            day.addingTimeInterval(TimeInterval(hour * 3600 + minute * 60))
        }

        let samples = [
            Entry(date: at(7, 10), name: "Espresso", kind: .coffee, kcal: 2, caffeineMg: 63),
            Entry(date: at(8, 25), name: "Porridge mit Beeren", kind: .meal, kcal: 410,
                  proteinG: 12, carbsG: 62, fatG: 9),
            Entry(date: at(10, 30), name: "Cappuccino", kind: .coffee, kcal: 74, caffeineMg: 63),
            Entry(date: at(12, 40), name: "Bowl mit Lachs", kind: .meal, kcal: 620,
                  proteinG: 34, carbsG: 52, fatG: 21),
            Entry(date: at(15, 5), name: "Espresso", kind: .coffee, kcal: 2, caffeineMg: 63),
            Entry(date: at(19, 15), name: "Ofengemüse", kind: .meal, kcal: 741,
                  proteinG: 18, carbsG: 74, fatG: 33)
        ]
        for entry in samples { context.insert(entry) }
    }
}
#endif
