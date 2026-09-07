import Foundation
import SwiftData

/// Ein Eintrag — Mahlzeit oder Kaffee. Bewusst ein Modell für beides:
/// die Tagesübersicht braucht ohnehin eine gemischte Chronologie.
@Model
final class Entry {
    var date: Date
    var name: String
    var kindRaw: String
    var kcal: Double
    var caffeineMg: Double
    var proteinG: Double?
    var carbsG: Double?
    var fatG: Double?

    /// UUIDs der in HealthKit abgelegten Objekte. Ohne sie bleiben beim
    /// Löschen Leichen in Health zurück, die sich nur von Hand entfernen lassen.
    var hkIDs: [UUID]

    @Attribute(.externalStorage) var photo: Data?

    init(
        date: Date = .now,
        name: String,
        kind: Kind,
        kcal: Double,
        caffeineMg: Double = 0,
        proteinG: Double? = nil,
        carbsG: Double? = nil,
        fatG: Double? = nil,
        photo: Data? = nil
    ) {
        self.date = date
        self.name = name
        self.kindRaw = kind.rawValue
        self.kcal = kcal
        self.caffeineMg = caffeineMg
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.hkIDs = []
        self.photo = photo
    }

    var kind: Kind { Kind(rawValue: kindRaw) ?? .meal }

    enum Kind: String, CaseIterable, Sendable {
        case meal, coffee
    }
}
