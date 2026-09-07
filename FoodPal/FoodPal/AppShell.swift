import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case start, capture, settings

    var id: String { rawValue }

    var label: String {
        switch self {
        case .start: "Start"
        case .capture: "Erfassen"
        case .settings: "Einstellungen"
        }
    }

    var pictogram: Pictogram.Kind {
        switch self {
        case .start: .start
        case .capture: .capture
        case .settings: .settings
        }
    }
}

/// Eigene Tabbar statt `TabView`: die Piktogramme sind gezeichnete Flächen,
/// keine Symbolschrift — `tabItem` würde sie als Schablone behandeln und
/// die Innenformen verlieren.
struct TabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Palette.rule).frame(height: 1)
            HStack(spacing: 0) {
                ForEach(AppTab.allCases) { tab in
                    let active = tab == selection
                    Button {
                        selection = tab
                    } label: {
                        VStack(spacing: 4) {
                            Pictogram(kind: tab.pictogram, color: active ? Palette.ink : Palette.ink2)
                                .frame(width: 24, height: 24)
                            Text(tab.label)
                                .font(.system(size: 10, weight: active ? .medium : .regular))
                                .foregroundStyle(active ? Palette.ink : Palette.ink2)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tab.label)
                    .accessibilityAddTraits(active ? [.isSelected, .isButton] : .isButton)
                }
            }
            .padding(.top, 10)
        }
        .background(Palette.paper)
    }
}

struct AppShell: View {
    @State private var tab: AppTab = {
        #if DEBUG
        // Erlaubt Screenshots einzelner Tabs ohne Bedienung des Simulators.
        if let raw = ProcessInfo.processInfo.environment["START_TAB"],
           let forced = AppTab(rawValue: raw) { return forced }
        #endif
        return .start
    }()

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch tab {
                case .start: TodayView()
                case .capture: PlaceholderScreen(title: "Erfassen")
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            TabBar(selection: $tab)
        }
        .background(Palette.paper)
    }
}

/// ponytail: Platzhalter, bis die Screens dran sind — kein Gerüst auf Vorrat.
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
