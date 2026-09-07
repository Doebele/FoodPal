import SwiftUI
import SwiftData

/// Walking Skeleton — beantwortet genau eine Frage: kommen Werte in Health an?
/// Wird durch das eigentliche UI ersetzt, sobald das bewiesen ist.
struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Entry.date, order: .reverse) private var entries: [Entry]
    @State private var health = HealthKitSync()
    @State private var message = ""

    var body: some View {
        NavigationStack {
            List {
                Section("HealthKit") {
                    LabeledContent("Status", value: health.status.rawValue)
                    Button("Berechtigung anfragen") {
                        Task {
                            do {
                                try await health.requestAuthorization()
                                message = "Berechtigung abgefragt — Status: \(health.status.rawValue)"
                            } catch {
                                message = "Fehler: \(error.localizedDescription)"
                            }
                        }
                    }
                }

                Section("Testeinträge") {
                    Button("Mahlzeit · 500 kcal") {
                        add(Entry(
                            name: "Testmahlzeit",
                            kind: .meal,
                            kcal: 500,
                            proteinG: 30,
                            carbsG: 45,
                            fatG: 18
                        ))
                    }
                    Button("Espresso · 2 kcal / 63 mg") {
                        add(Entry(
                            name: "Espresso",
                            kind: .coffee,
                            kcal: 2,
                            caffeineMg: 63
                        ))
                    }
                }

                if !message.isEmpty {
                    Section("Meldung") {
                        Text(message).font(.footnote)
                    }
                }

                Section("Gespeichert (\(entries.count))") {
                    ForEach(entries) { entry in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.name)
                            Text(detail(for: entry))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete(perform: remove)
                }
            }
            .navigationTitle("FoodPal · Skeleton")
        }
    }

    private func detail(for entry: Entry) -> String {
        var parts = ["\(Int(entry.kcal)) kcal"]
        if entry.caffeineMg > 0 { parts.append("\(Int(entry.caffeineMg)) mg") }
        parts.append(entry.hkIDs.isEmpty ? "nicht in Health" : "\(entry.hkIDs.count) Objekte in Health")
        return parts.joined(separator: " · ")
    }

    private func add(_ entry: Entry) {
        context.insert(entry)
        Task {
            do {
                entry.hkIDs = try await health.save(entry)
                message = "\(entry.name) gesichert — \(entry.hkIDs.count) Objekte in Health."
            } catch {
                message = "Lokal gesichert, Health fehlgeschlagen: \(error.localizedDescription)"
            }
        }
    }

    private func remove(at offsets: IndexSet) {
        let doomed = offsets.map { entries[$0] }
        let ids = doomed.flatMap(\.hkIDs)
        for entry in doomed { context.delete(entry) }
        Task {
            do {
                try await health.delete(ids: ids)
                message = "Gelöscht — \(ids.count) Objekte aus Health entfernt."
            } catch {
                message = "Lokal gelöscht, Health fehlgeschlagen: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    ContentView().modelContainer(for: Entry.self, inMemory: true)
}
