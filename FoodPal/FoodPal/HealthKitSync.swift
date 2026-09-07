import Foundation
import HealthKit

/// Schreibt Einträge nach Apple Health und entfernt sie wieder.
/// Kein Protokoll — eine Implementierung, kein Erweiterungspunkt.
@MainActor
@Observable
final class HealthKitSync {

    enum Status: String {
        case unavailable = "nicht verfügbar"
        case notDetermined = "nicht verbunden"
        case denied = "abgelehnt"
        case authorized = "verbunden"
    }

    private let store = HKHealthStore()

    /// Nährwert-Typen und ihre Einheiten. Reihenfolge egal, der Schlüssel zählt.
    private static let quantities: [(HKQuantityTypeIdentifier, HKUnit)] = [
        (.dietaryEnergyConsumed, .kilocalorie()),
        (.dietaryCaffeine, .gramUnit(with: .milli)),
        (.dietaryProtein, .gram()),
        (.dietaryCarbohydrates, .gram()),
        (.dietaryFatTotal, .gram())
    ]

    private static var foodType: HKCorrelationType { HKCorrelationType(.food) }

    /// Nur die Einzeltypen. HealthKit weist Korrelationstypen in der
    /// Autorisierung ausdrücklich zurück ("Authorization to share the
    /// following types is disallowed: HKCorrelationTypeIdentifierFood").
    /// Die Korrelation lässt sich dennoch speichern, solange ihre
    /// enthaltenen Werte freigegeben sind.
    private static var shareTypes: Set<HKSampleType> {
        Set(quantities.map { HKQuantityType($0.0) })
    }

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// Für Schreib-Typen liefert HealthKit den Status verlässlich —
    /// bei Lese-Typen wäre er absichtlich blind.
    var status: Status {
        guard isAvailable else { return .unavailable }
        switch store.authorizationStatus(for: HKQuantityType(.dietaryEnergyConsumed)) {
        case .sharingAuthorized: return .authorized
        case .sharingDenied: return .denied
        default: return .notDetermined
        }
    }

    func requestAuthorization() async throws {
        guard isAvailable else { throw Failure.unavailable }
        try await store.requestAuthorization(toShare: Self.shareTypes, read: [])
    }

    /// Legt den Eintrag als `HKCorrelation` vom Typ `.food` ab, nicht als lose
    /// Einzelwerte — nur so zeigt die Health-App einen benannten Eintrag mit
    /// aufklappbaren Nährwerten. Gibt die UUIDs zum späteren Löschen zurück.
    @discardableResult
    func save(_ entry: Entry) async throws -> [UUID] {
        guard isAvailable else { throw Failure.unavailable }

        let values: [(HKQuantityTypeIdentifier, HKUnit, Double)] = [
            (.dietaryEnergyConsumed, .kilocalorie(), entry.kcal),
            (.dietaryCaffeine, .gramUnit(with: .milli), entry.caffeineMg),
            (.dietaryProtein, .gram(), entry.proteinG ?? 0),
            (.dietaryCarbohydrates, .gram(), entry.carbsG ?? 0),
            (.dietaryFatTotal, .gram(), entry.fatG ?? 0)
        ]

        let metadata: [String: Any] = [HKMetadataKeyFoodType: entry.name]

        var samples = Set<HKSample>()
        for (id, unit, value) in values where value > 0 {
            samples.insert(HKQuantitySample(
                type: HKQuantityType(id),
                quantity: HKQuantity(unit: unit, doubleValue: value),
                start: entry.date,
                end: entry.date,
                metadata: metadata
            ))
        }
        guard !samples.isEmpty else { throw Failure.nothingToWrite }

        let correlation = HKCorrelation(
            type: Self.foodType,
            start: entry.date,
            end: entry.date,
            objects: samples,
            metadata: metadata
        )

        try await store.save(correlation)

        var ids = [correlation.uuid]
        ids.append(contentsOf: samples.map(\.uuid))
        return ids
    }

    /// Löscht über alle infrage kommenden Typen — ein Prädikat, das nicht
    /// trifft, löscht schlicht nichts. Spart das Mitführen des Typs je UUID.
    func delete(ids: [UUID]) async throws {
        guard isAvailable, !ids.isEmpty else { return }

        let predicate = NSCompoundPredicate(
            orPredicateWithSubpredicates: ids.map { HKQuery.predicateForObject(with: $0) }
        )

        // Der Korrelationstyp bleibt außen vor — ohne Autorisierung dafür
        // kein Löschen. Sind alle enthaltenen Einzelwerte fort, verschwindet
        // der Eintrag in Health ohnehin.
        for (id, _) in Self.quantities {
            _ = try? await store.deleteObjects(of: HKQuantityType(id), predicate: predicate)
        }
    }

    enum Failure: LocalizedError {
        case unavailable
        case nothingToWrite

        var errorDescription: String? {
            switch self {
            case .unavailable: "Health ist auf diesem Gerät nicht verfügbar."
            case .nothingToWrite: "Der Eintrag enthält keine Werte."
            }
        }
    }
}
