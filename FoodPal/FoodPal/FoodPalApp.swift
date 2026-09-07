import SwiftUI
import SwiftData

@main
struct FoodPalApp: App {
    init() { Preference.registerDefaults() }

    var body: some Scene {
        WindowGroup {
            AppShell()
                .modelContainer(container)
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
