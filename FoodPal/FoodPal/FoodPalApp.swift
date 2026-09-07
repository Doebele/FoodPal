import SwiftUI
import SwiftData

@main
struct FoodPalApp: App {
    init() { Preference.registerDefaults() }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Entry.self)
    }
}
