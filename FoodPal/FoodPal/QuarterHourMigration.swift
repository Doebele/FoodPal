import Foundation
import SwiftData

/// Einmaliges Nachziehen der Viertelstunden-Regel auf bestehende Einträge.
///
/// `Entry.init` schneidet seit jeher nur **neue** Einträge zurecht. Alles, was
/// vorher entstanden ist, steht weiter auf Minuten und Sekunden und liefe im
/// Diagramm in derselben Spalte, aber in der Liste mit krummen Zeiten — zwei
/// Auflösungen nebeneinander.
///
/// Der Lauf ist von sich aus wiederholbar: eine geschnittene Zeit noch einmal
/// zu schneiden ändert nichts. Die Marke spart trotzdem den Durchlauf bei
/// jedem Start.
enum QuarterHourMigration {
    static let mark = "migratedToQuarterHours"

    /// Gibt zurück, wie viele Einträge verschoben wurden — der Aufrufer
    /// entscheidet, ob er sie auch in Health nachzieht.
    @discardableResult
    static func run(_ context: ModelContext) -> [Entry] {
        let store = UserDefaults.standard
        guard !store.bool(forKey: mark) else { return [] }

        let all = (try? context.fetch(FetchDescriptor<Entry>())) ?? []
        var moved: [Entry] = []
        for entry in all {
            let cut = entry.date.startOfQuarterHour
            guard cut != entry.date else { continue }
            entry.date = cut
            moved.append(entry)
        }

        // Die Marke erst nach dem Sichern: bricht das Schreiben ab, läuft es
        // beim nächsten Start erneut, statt die Einträge halb verschoben
        // zurückzulassen.
        do {
            try context.save()
            store.set(true, forKey: mark)
        } catch {
            return []
        }
        return moved
    }

    /// Zieht die verschobenen Einträge in Health nach.
    ///
    /// **Erst schreiben, dann löschen.** Andersherum liesse ein Fehler in der
    /// Mitte ein Loch in der Gesundheitsakte; so bleibt im schlimmsten Fall ein
    /// Doppeleintrag stehen, den man sieht und entfernen kann.
    @MainActor
    static func resync(_ entries: [Entry], with health: HealthKitSync) async {
        guard health.status == .authorized else { return }
        for entry in entries {
            let old = entry.hkIDs
            guard let fresh = try? await health.save(entry) else { continue }
            entry.hkIDs = fresh
            try? await health.delete(ids: old)
        }
    }
}
