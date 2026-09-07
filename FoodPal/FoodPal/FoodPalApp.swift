import SwiftUI
import SwiftData

@main
struct FoodPalApp: App {
    @AppStorage(Preference.appearance) private var appearanceRaw = Appearance.auto.rawValue

    init() { Preference.registerDefaults() }

    var body: some Scene {
        WindowGroup {
            AppShell()
                .modelContainer(container)
                // Am Wurzelview, damit auch die Sheets folgen.
                .preferredColorScheme(Appearance(rawValue: appearanceRaw)?.colorScheme)
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
