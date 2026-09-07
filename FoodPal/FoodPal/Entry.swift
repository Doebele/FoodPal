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

/// Feste Getränkedaten. Bewusst ein statisches Array und kein `@Model`:
/// die Werte ändern sich nie. Editierbar ist der **Eintrag**, wenn er mit
/// Milch oder Zucker abweicht — nicht die Vorlage.
///
/// Die Reihenfolge hier ist die Voreinstellung bei Gleichstand; im Screen
/// sortiert die tatsächliche Nutzung, häufigste unten im Daumenbereich.
struct CoffeePreset: Identifiable, Hashable {
    let name: String
    let kcal: Double
    let caffeineMg: Double

    var id: String { name }

    static let all: [CoffeePreset] = [
        .init(name: "Macchiato", kcal: 13, caffeineMg: 63),
        .init(name: "Cold Brew", kcal: 6, caffeineMg: 155),
        .init(name: "Mokka", kcal: 5, caffeineMg: 95),
        .init(name: "Filterkaffee", kcal: 4, caffeineMg: 95),
        .init(name: "Lungo", kcal: 3, caffeineMg: 75),
        .init(name: "Americano", kcal: 3, caffeineMg: 77),
        .init(name: "Caffè Latte", kcal: 135, caffeineMg: 63),
        .init(name: "Latte Macchiato", kcal: 120, caffeineMg: 63),
        .init(name: "Cortado", kcal: 45, caffeineMg: 63),
        .init(name: "Flat White", kcal: 155, caffeineMg: 130),
        .init(name: "Ristretto", kcal: 1, caffeineMg: 53),
        .init(name: "Doppio", kcal: 4, caffeineMg: 126),
        .init(name: "Cappuccino", kcal: 74, caffeineMg: 63),
        .init(name: "Espresso", kcal: 2, caffeineMg: 63)
    ]

    func entry(at date: Date = .now) -> Entry {
        Entry(date: date, name: name, kind: .coffee, kcal: kcal, caffeineMg: caffeineMg)
    }
}
