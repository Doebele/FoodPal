import SwiftUI
import SwiftData

@main
struct FoodPalApp: App {
    @AppStorage(Preference.appearance) private var appearanceRaw = Appearance.auto.rawValue
    @AppStorage(Preference.scaleText) private var scaleText = true

    init() { Preference.registerDefaults() }

    var body: some Scene {
        WindowGroup {
            AppShell()
                .modelContainer(container)
                // Am Wurzelview, damit auch die Sheets folgen.
                .preferredColorScheme(Appearance(rawValue: appearanceRaw)?.colorScheme)
                // Aus heisst: auf die Vorgabegroesse festnageln. `.large` ist
                // genau die Groesse, in der die Entwuerfe gesetzt sind. An
                // heisst: gar nichts tun und die Systemwahl durchlassen.
                .modifier(FixedTypeSize(active: !scaleText))
        }
    }

    private let container: ModelContainer = {
        let container = try! ModelContainer(for: Entry.self)
        #if DEBUG
        if ProcessInfo.processInfo.environment["SEED_DEMO"] == "1" {
            DemoData.seedIfEmpty(ModelContext(container))
        }
        #endif
        return container
    }()
}

/// Nagelt die Schriftgroesse auf die Vorgabe fest — oder laesst sie in Ruhe.
///
/// Ein `.dynamicTypeSize()` mit einem optionalen Wert gibt es nicht; der
/// Modifier muss deshalb ganz wegbleiben, wenn die Systemwahl gelten soll.
private struct FixedTypeSize: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        if active {
            content.dynamicTypeSize(.large)
        } else {
            content
        }
    }
}
