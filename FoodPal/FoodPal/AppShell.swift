import SwiftUI

/// Die App hat **einen** Screen. Erfassen und Einstellungen sind Sheets:
/// sie kommen von unten, erledigen eine Sache und verschwinden wieder.
///
/// Damit entfällt die Tabbar. Sie hätte drei Ziele angeboten, von denen
/// zwei gar keine Orte sind, sondern Handlungen.
struct AppShell: View {
    @Environment(\.modelContext) private var context
    @AppStorage(Preference.healthSync) private var healthSync = true
    @State private var health = HealthKitSync()

    @State private var showCapture = {
        #if DEBUG
        return ProcessInfo.processInfo.environment["START_SHEET"] == "1"
        #else
        return false
        #endif
    }()
    @State private var showSettings = {
        #if DEBUG
        return ProcessInfo.processInfo.environment["START_SETTINGS"] == "1"
        #else
        return false
        #endif
    }()

    var body: some View {
        TodayView(
            onCapture: { showCapture = true },
            onSettings: { showSettings = true }
        )
        .background(Palette.paper)
        // Einmalig: Altbestand auf die Viertelstunde nachziehen. Health folgt
        // nur, wenn der Sync ueberhaupt an ist — sonst gehoert dort nichts hin.
        .task {
            let moved = QuarterHourMigration.run(context)
            guard healthSync, !moved.isEmpty else { return }
            await QuarterHourMigration.resync(moved, with: health)
        }
        .sheet(isPresented: $showCapture) {
            CaptureSheet()
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
                .presentationBackground(Palette.paper)
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
                .presentationBackground(Palette.paper)
        }
    }
}

/// Kopfzeile jedes Sheets: Titel links, Schliessen rechts. Beim dritten
/// Vorkommen ausgelagert — vorher waren es zwei Kopien, jetzt eine Regel.
struct SheetHeader: View {
    /// `LocalizedStringKey` und nicht `String`: `Text(einString)` setzt den
    /// Text woertlich und schlaegt nichts nach. Genau daran waere die halbe
    /// Oberflaeche unuebersetzt geblieben.
    let title: LocalizedStringKey
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .tracking(0.9)
                .foregroundStyle(Palette.ink2)
            Spacer()
            Button("Schließen") { dismiss() }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, Metric.margin)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }
}

/// ponytail: Platzhalter, bis die Foto-Erfassung dran ist.
struct PlaceholderScreen: View {
    let title: String

    var body: some View {
        VStack {
            Spacer()
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .tracking(0.9)
                .foregroundStyle(Palette.ink2)
            Text("folgt")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(Palette.ink)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Palette.paper)
    }
}
