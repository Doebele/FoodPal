import SwiftUI
import SwiftData

/// Eintrag ansehen, ändern, löschen.
///
/// Löschen ist bewusst **nicht rot**: der Akzent gehört dem Koffein, ein
/// zweiter Signalton würde das System aufweichen. Die Sicherung liegt im
/// zweiten Schritt — Nachfrage statt Warnfarbe.
struct EntryDetailView: View {
    let entry: Entry

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(Preference.healthSync) private var healthSync = true
    @AppStorage(Preference.roast) private var roastRaw = Roast.hell.rawValue

    @State private var health = HealthKitSync()
    @State private var name = ""
    @State private var date = Date.now
    @State private var kcal = ""
    @State private var caffeine = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var askDelete = false
    @State private var editingTime = false
    @State private var loaded = false

    private var roast: Roast { Roast(rawValue: roastRaw) ?? .hell }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    field("bezeichnung") {
                        TextField("", text: $name)
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(Palette.ink)
                    }

                    timeField

                    numberField("kcal", text: $kcal, tint: Palette.ink)

                    if entry.kind == .coffee {
                        numberField("koffein · mg", text: $caffeine, tint: roast.color)
                    }

                    numberField("protein · g", text: $protein, tint: Palette.ink)
                    numberField("kohlenhydrate · g", text: $carbs, tint: Palette.ink)
                    numberField("fett · g", text: $fat, tint: Palette.ink)

                    deleteSection
                }
                .padding(.horizontal, Metric.margin)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .background(Palette.paper)
        .task {
            guard !loaded else { return }
            load()
            loaded = true
        }
        .confirmationDialog(
            "Eintrag löschen?",
            isPresented: $askDelete,
            titleVisibility: .visible
        ) {
            Button("Löschen", role: .destructive) { remove() }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text(healthSync
                 ? "Der Eintrag wird auch aus Apple Health entfernt."
                 : "Der Eintrag wird gelöscht.")
        }
    }

    private var header: some View {
        HStack {
            Text("Eintrag")
                .font(.system(size: 13, weight: .medium))
                .tracking(0.9)
                .foregroundStyle(Palette.ink2)
            Spacer()
            Button("Fertig") { finish() }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, Metric.margin)
        .padding(.top, 20)
        .padding(.bottom, 24)
    }

    private var deleteSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle().fill(Palette.ink).frame(height: 1)
                .padding(.top, 40)
            Button {
                askDelete = true
            } label: {
                HStack {
                    Text("Eintrag löschen")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Palette.ink)
                    Spacer()
                }
                .frame(height: 56)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if healthSync {
                Text("Wird auch aus Apple Health entfernt.")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.ink2)
            }
        }
    }

    /// Zeitpunkt statt nur Uhrzeit: so lassen sich Einträge nachtragen,
    /// die schon vorbei sind. Nach vorn ist bei jetzt Schluss — ein Eintrag
    /// in der Zukunft wäre unsichtbar, weil die Tagesansicht bei heute endet.
    ///
    /// Der Wert steht als schlichter Text wie jeder andere; erst beim
    /// Antippen klappt das Rad aus. Apples kompakter DatePicker bringt sonst
    /// eine graue Kastenpille mit, die es sonst nirgends gibt.
    private var timeField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { editingTime.toggle() }
            } label: {
                HStack {
                    Text("zeitpunkt")
                        .font(.system(size: 11))
                        .tracking(0.8)
                        .foregroundStyle(Palette.ink2)
                    Spacer()
                    Text(stamp)
                        .font(.system(size: 22, weight: .light, design: .monospaced))
                        .foregroundStyle(Palette.ink)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if editingTime {
                DatePicker(
                    "",
                    selection: $date,
                    in: ...Date.now,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }

            Rectangle().fill(Palette.rule).frame(height: 1)
        }
        .padding(.bottom, 20)
    }

    private var stamp: String {
        let calendar = Calendar.current
        let day: String
        if calendar.isDateInToday(date) {
            day = "Heute"
        } else if calendar.isDateInYesterday(date) {
            day = "Gestern"
        } else {
            day = date.formatted(.dateTime.day().month(.abbreviated))
        }
        return day + " · " + date.formatted(date: .omitted, time: .shortened)
    }

    // MARK: - Bausteine

    private func field<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11))
                .tracking(0.8)
                .foregroundStyle(Palette.ink2)
            content()
            Rectangle().fill(Palette.rule).frame(height: 1)
        }
        .padding(.bottom, 20)
    }

    private func numberField(_ label: String, text: Binding<String>, tint: Color) -> some View {
        field(label) {
            TextField("", text: text)
                .keyboardType(.decimalPad)
                .font(.system(size: 22, weight: .light, design: .monospaced))
                .foregroundStyle(tint)
        }
    }

    private func row<Value: View>(_ label: String, @ViewBuilder value: () -> Value) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .tracking(0.8)
                .foregroundStyle(Palette.ink2)
            Spacer()
            value()
        }
        .frame(height: 48)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Palette.rule).frame(height: 1)
        }
        .padding(.bottom, 20)
    }

    // MARK: - Daten

    private func load() {
        name = entry.name
        date = entry.date
        kcal = format(entry.kcal)
        caffeine = format(entry.caffeineMg)
        protein = entry.proteinG.map(format) ?? ""
        carbs = entry.carbsG.map(format) ?? ""
        fat = entry.fatG.map(format) ?? ""
    }

    private func format(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(value)
    }

    private func parse(_ text: String) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: "."))
    }

    /// Übernimmt die Änderungen und schreibt sie **auch nach Health** —
    /// alte Samples löschen, neue anlegen. Sonst driftet Health von der
    /// App weg und niemand merkt es.
    private func finish() {
        let changed = name != entry.name
            || date != entry.date
            || parse(kcal) != entry.kcal
            || parse(caffeine) != entry.caffeineMg
            || parse(protein) != entry.proteinG
            || parse(carbs) != entry.carbsG
            || parse(fat) != entry.fatG

        entry.name = name.trimmingCharacters(in: .whitespaces)
        entry.date = date
        entry.kcal = parse(kcal) ?? 0
        entry.caffeineMg = parse(caffeine) ?? 0
        entry.proteinG = parse(protein)
        entry.carbsG = parse(carbs)
        entry.fatG = parse(fat)

        if changed && healthSync {
            let old = entry.hkIDs
            Task {
                try? await health.delete(ids: old)
                entry.hkIDs = (try? await health.save(entry)) ?? []
            }
        }
        dismiss()
    }

    private func remove() {
        let ids = entry.hkIDs
        context.delete(entry)
        Task { try? await health.delete(ids: ids) }
        dismiss()
    }
}
