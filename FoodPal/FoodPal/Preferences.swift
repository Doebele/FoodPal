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

    /// Voreinstellungen. Haptik ist **an** — abschaltbar, aber wer sie nicht
    /// vorfindet, entdeckt sie nie.
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            haptics: true,
            healthSync: true,
            roast: Roast.hell.rawValue,
            numberStyle: NumberStyle.flip.rawValue,
            captureMode: Entry.Kind.coffee.rawValue,
            appearance: Appearance.auto.rawValue
        ])
    }
}

/// Hell, Dunkel oder dem Gerät folgen. Voreingestellt ist **Auto** —
/// die App hat keinen Grund, die Systemwahl zu überstimmen.
enum Appearance: String, CaseIterable, Identifiable {
    case auto, light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .auto: "Auto"
        case .light: "Hell"
        case .dark: "Dunkel"
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
