import Foundation
import HealthKit

/// Schreibt Einträge nach Apple Health und entfernt sie wieder.
/// Kein Protokoll — eine Implementierung, kein Erweiterungspunkt.
@MainActor
@Observable
final class HealthKitSync {

    /// Der Rohwert ist ein Bezeichner, kein Anzeigetext — sonst waere die
    /// Uebersetzung an die Datenhaltung gekettet.
    enum Status: String {
        case unavailable, notDetermined, denied, authorized

        var label: String {
            switch self {
            case .unavailable: String(localized: "nicht verfügbar")
            case .notDetermined: String(localized: "nicht verbunden")
            case .denied: String(localized: "abgelehnt")
            case .authorized: String(localized: "verbunden")
            }
        }
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

    /// Legt die Nährwerte als einzelne Samples ab und gibt ihre UUIDs zum
    /// späteren Löschen zurück. Bewusst ohne `HKCorrelation`: Apples Health-App
    /// zeigt daraus keine gruppierte Mahlzeit, der Name reist ohnehin als
    /// Metadatum mit — und eine Korrelation ließe sich nie wieder löschen,
    /// weil HealthKit für Korrelationstypen keine Autorisierung erteilt.
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

        // Der Name reist als HKMetadataKeyFoodType an jedem Einzelwert mit —
        // die Health-App zeigt ihn im Detail als "Nahrungsmittel".
        let metadata: [String: Any] = [HKMetadataKeyFoodType: entry.name]

        var samples: [HKQuantitySample] = []
        for (id, unit, value) in values where value > 0 {
            samples.append(HKQuantitySample(
                type: HKQuantityType(id),
                quantity: HKQuantity(unit: unit, doubleValue: value),
                start: entry.date,
                end: entry.date,
                metadata: metadata
            ))
        }
        guard !samples.isEmpty else { throw Failure.nothingToWrite }

        try await store.save(samples)
        return samples.map(\.uuid)
    }

    /// Löscht über alle infrage kommenden Typen — ein Prädikat, das nicht
    /// trifft, löscht schlicht nichts. Spart das Mitführen des Typs je UUID.
    func delete(ids: [UUID]) async throws {
        guard isAvailable, !ids.isEmpty else { return }

        let predicate = NSCompoundPredicate(
            orPredicateWithSubpredicates: ids.map { HKQuery.predicateForObject(with: $0) }
        )

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
