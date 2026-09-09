import Foundation
import SwiftData

extension Date {
    /// Der Beginn der laufenden Viertelstunde — **abgerundet**, wie
    /// `startOfDay` abrundet. 9:00 bis 9:14 werden 9:00, 9:15 bis 9:29 werden
    /// 9:15.
    ///
    /// Dieselbe Auflösung wie der Zeitstrahl, der je Stunde vier Spalten hat —
    /// feiner kann das Diagramm ohnehin nichts zeigen. Und genauer muss es
    /// nicht sein: ob der Kaffee um 10:28 oder 10:15 stand, ändert an einem
    /// Ernährungstagebuch nichts, macht das Eintragen aber umständlicher.
    ///
    /// Abrunden statt zur nächsten runden hat zwei Vorteile, die man erst beim
    /// Nachdenken sieht: kein Eintrag wandert in die **Zukunft**, und 23:58
    /// kann nicht auf morgen rollen und damit zum falschen Tag zählen.
    var startOfQuarterHour: Date {
        let calendar = Calendar.current
        var parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        parts.minute = (parts.minute ?? 0) / 15 * 15
        parts.second = 0
        return calendar.date(from: parts) ?? self
    }
}

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

    /// Ob das Bild aufgenommen oder erzeugt wurde. Ein erzeugtes Bild ist kein
    /// Beleg, sondern eine Merkhilfe — im Tagebuch muss der Unterschied
    /// nachlesbar bleiben, nicht nur am Stil erkennbar sein.
    var generatedImage: Bool = false

    init(
        date: Date = .now,
        name: String,
        kind: Kind,
        kcal: Double,
        caffeineMg: Double = 0,
        proteinG: Double? = nil,
        carbsG: Double? = nil,
        fatG: Double? = nil,
        photo: Data? = nil,
        generatedImage: Bool = false
    ) {
        // Hier und nicht beim Aufrufer: sonst haette die Regel vier Wohnorte —
        // Foto, Kaffee, Beschreibung, Nachtrag — und einer vergaesse sie.
        self.date = date.startOfQuarterHour
        self.name = name
        self.kindRaw = kind.rawValue
        self.kcal = kcal
        self.caffeineMg = caffeineMg
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.hkIDs = []
        self.photo = photo
        self.generatedImage = generatedImage
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
        // Doppio, nicht einfacher Shot: die Quellen nennen 30–40 ml Espresso
        // auf gleich viel Milch im 60–70-ml-Glas. Damit 126 mg statt 63, und
        // die Kalorien folgen derselben Rechnung — 4 fuer den Doppio, 26 fuer
        // 40 ml Vollmilch.
        .init(name: "Cortado", kcal: 30, caffeineMg: 126),
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
