import SwiftUI

/// Schlüssel der Einstellungen an einem Ort. `@AppStorage` verlangt an jeder
/// Verwendungsstelle denselben String — als Konstante kann er nicht auseinanderlaufen.
enum Preference {
    static let haptics = "hapticsEnabled"
    static let healthSync = "healthSyncEnabled"
    static let roast = "accentRoast"
    static let numberStyle = "numberStyle"
    static let captureMode = "captureMode"
    static let appearance = "appearance"
    static let provider = "visionProvider"
    /// Modellname **je Anbieter**, als JSON. Siehe `PerProvider`.
    static let models = "visionModels"
    /// Adresse je Anbieter, als JSON — betrifft nur die ohne feste Adresse.
    static let addresses = "visionAddresses"

    private static let legacyModel = "visionModel"
    private static let legacyURL = "lmStudioURL"

    /// Voreinstellungen. Haptik ist **an** — abschaltbar, aber wer sie nicht
    /// vorfindet, entdeckt sie nie.
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            haptics: true,
            healthSync: true,
            roast: Roast.hell.rawValue,
            numberStyle: NumberStyle.flip.rawValue,
            captureMode: Entry.Kind.coffee.rawValue,
            appearance: Appearance.auto.rawValue,
            provider: Provider.claude.rawValue,
            models: "{}",
            addresses: "{}"
        ])
        migrateSingleValues()
    }

    /// Frueher gab es **einen** Modellnamen und **eine** Adresse für alle
    /// Anbieter. Beim Wechsel ging deshalb verloren, was für den vorherigen
    /// eingerichtet war. Die Altwerte gehörten dem damals gewählten Anbieter —
    /// dorthin werden sie einmalig übernommen.
    private static func migrateSingleValues() {
        let store = UserDefaults.standard
        let owner = Provider(rawValue: store.string(forKey: provider) ?? "") ?? .claude

        if let old = store.string(forKey: legacyModel), !old.isEmpty {
            store.set(PerProvider.setting(store.string(forKey: models) ?? "{}", owner, old),
                      forKey: models)
        }
        if let old = store.string(forKey: legacyURL), !old.isEmpty, owner.editableAddress {
            store.set(PerProvider.setting(store.string(forKey: addresses) ?? "{}", owner, old),
                      forKey: addresses)
        }
        store.removeObject(forKey: legacyModel)
        store.removeObject(forKey: legacyURL)
    }
}

/// Ein Wert je Anbieter, als JSON in einem einzigen `UserDefaults`-Eintrag.
///
/// `@AppStorage` kann keine Dictionaries, und je Anbieter und Feld einen
/// eigenen Schlüssel anzulegen wären zwei Dutzend Namen, die auseinanderlaufen
/// können. Ein kleines JSON-Objekt bleibt beobachtbar und wächst mit der Liste
/// mit, ohne dass irgendwo etwas nachgetragen werden muss.
enum PerProvider {
    static func value(_ json: String, _ provider: Provider) -> String {
        decoded(json)[provider.rawValue] ?? ""
    }

    /// Gibt das neue JSON zurück, statt selbst zu schreiben — so bleibt der
    /// Schreibweg die `@AppStorage`-Bindung und die Views aktualisieren sich.
    static func setting(_ json: String, _ provider: Provider, _ value: String) -> String {
        var map = decoded(json)
        map[provider.rawValue] = value.isEmpty ? nil : value
        guard let data = try? JSONEncoder().encode(map),
              let text = String(data: data, encoding: .utf8) else { return json }
        return text
    }

    private static func decoded(_ json: String) -> [String: String] {
        guard let data = json.data(using: .utf8),
              let map = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return map
    }
}

/// Hell, Dunkel oder dem Gerät folgen. Voreingestellt ist **Auto** —
/// die App hat keinen Grund, die Systemwahl zu überstimmen.
enum Appearance: String, CaseIterable, Identifiable {
    case auto, light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .auto: String(localized: "Auto")
        case .light: String(localized: "Hell")
        case .dark: String(localized: "Dunkel")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .auto: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum NumberStyle: String, CaseIterable, Identifiable {
    case flip, sevenSegment, dotMatrix

    var id: String { rawValue }

    var label: String {
        switch self {
        case .flip: "Flip"
        case .sevenSegment: "7-Segment"
        case .dotMatrix: "Dot-Matrix"
        }
    }
}

// MARK: - Haptik

extension View {
    /// Haptischer Impuls, sofern in den Einstellungen aktiv.
    ///
    /// Bewusst über einen einzigen Modifier statt `.sensoryFeedback` an jeder
    /// Stelle: der Schalter greift dann überall, ohne dass jeder Screen ihn
    /// selbst abfragen muss.
    ///
    /// Gehört an Stellen, an denen etwas **einrastet** — gesichert, gelöscht,
    /// Tag gewechselt. Nicht an jeden Tastendruck; sonst nutzt sie sich ab.
    func haptic<T: Equatable>(
        _ feedback: SensoryFeedback = .impact(weight: .light, intensity: 0.7),
        trigger: T
    ) -> some View {
        modifier(GatedHaptic(feedback: feedback, trigger: trigger))
    }
}

private struct GatedHaptic<T: Equatable>: ViewModifier {
    @AppStorage(Preference.haptics) private var enabled = true
    let feedback: SensoryFeedback
    let trigger: T

    func body(content: Content) -> some View {
        content.sensoryFeedback(trigger: trigger) { _, _ in
            enabled ? feedback : nil
        }
    }
}
