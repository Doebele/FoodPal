import SwiftUI

/// Die App hat **einen** Screen. Erfassen und Einstellungen sind Sheets:
/// sie kommen von unten, erledigen eine Sache und verschwinden wieder.
///
/// Damit entfällt die Tabbar. Sie hätte drei Ziele angeboten, von denen
/// zwei gar keine Orte sind, sondern Handlungen.
struct AppShell: View {
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
