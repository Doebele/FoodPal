import SwiftUI

/// Die App hat **einen** Screen. Erfassen und Einstellungen sind Sheets:
/// sie kommen von unten, erledigen eine Sache und verschwinden wieder.
///
/// Damit entfällt die Tabbar. Sie hätte drei Ziele angeboten, von denen
/// zwei gar keine Orte sind, sondern Handlungen.
struct AppShell: View {
    @Environment(\.modelContext) private var context
    @AppStorage(Preference.healthSync) private var healthSync = true
    @AppStorage(Preference.appearance) private var appearanceRaw = Appearance.auto.rawValue
    @State private var health = HealthKitSync()

    /// Dieselbe Wahl wie am Wurzelschirm — die Sheets brauchen sie
    /// **noch einmal**: `preferredColorScheme` an der Wurzel erreicht ein
    /// bereits offenes Sheet nicht mehr. Wer in den Einstellungen von dunkel
    /// auf hell stellte, sah den Wechsel erst nach dem Schliessen.
    private var scheme: ColorScheme? { Appearance(rawValue: appearanceRaw)?.colorScheme }

    @State private var showCapture = {
        #if DEBUG
        return ProcessInfo.processInfo.environment["START_SHEET"] == "1"
        #else
        return false
        #endif
    }()
    /// **Wohin die Einstellungen öffnen.** Als Wert und nicht als Flagge:
    /// `sheet(isPresented:)` baut seinen Inhalt schon, bevor die Flagge
    /// gesetzt ist, und der Anbieterdialog blieb deshalb zu. `sheet(item:)`
    /// bekommt den Wert mit, den man ihm beim Öffnen gibt.
    private enum SettingsTarget: String, Identifiable {
        case plain, vision
        var id: String { rawValue }
    }

    @State private var settings: SettingsTarget? = {
        #if DEBUG
        return ProcessInfo.processInfo.environment["START_SETTINGS"] == "1" ? .plain : nil
        #else
        return nil
        #endif
    }()
    /// Gemerkt, bis das Erfassungsblatt unten ist.
    @State private var wantsModel = false

    var body: some View {
        TodayView(
            onCapture: { showCapture = true },
            onSettings: { settings = .plain }
        )
        .background(Palette.paper)
        // Einmalig: Altbestand auf die Viertelstunde nachziehen. Health folgt
        // nur, wenn der Sync ueberhaupt an ist — sonst gehoert dort nichts hin.
        .task {
            let moved = QuarterHourMigration.run(context)
            guard healthSync, !moved.isEmpty else { return }
            await QuarterHourMigration.resync(moved, with: health)
        }
        // **Erst schliessen, dann oeffnen.** Solange das eine Blatt noch nach
        // unten faehrt, schluckt UIKit die Anweisung fuers naechste. `onDismiss`
        // feuert, wenn wirklich nichts mehr da ist.
        .sheet(isPresented: $showCapture, onDismiss: {
            guard wantsModel else { return }
            wantsModel = false
            settings = .vision
        }) {
            CaptureSheet(onModelSetup: { wantsModel = true })
                .preferredColorScheme(scheme)
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
                .presentationBackground(Palette.paper)
        }
        .sheet(item: $settings) { ziel in
            SettingsSheet(startVision: ziel == .vision)
                .preferredColorScheme(scheme)
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
    /// „Fertig" statt „Schliessen", wo etwas uebernommen wird.
    var action: LocalizedStringKey = "Schließen"

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var appeared = false

    var body: some View {
        // Nebeneinander, solange beides nebeneinander passt. Bei den
        // Bedienhilfen-Groessen tut es das nicht mehr — dort brach
        // „Schließen" mitten im Wort um. Untereinander bleibt beides lesbar,
        // und der Knopf behaelt seine Trefferflaeche.
        //
        // `ViewThatFits` waere hier falsch: die Zeile lebt von einem `Spacer`,
        // und dessen Idealbreite ist null — die Kopfzeile stuende dann immer
        // zusammengeschoben in der Mitte statt an den Raendern.
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) { label; button }
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack { label; Spacer(); button }
            }
        }
        .padding(.horizontal, Metric.margin)
        // 16 oben wie unten um eine 14 pt hohe Zeile — die 46 aus dem Entwurf.
        .padding(.vertical, 16)
        // Ein Sheet, das von unten hereinfaehrt, ist eine Bewegung — die darf
        // man spueren. Leicht, denn es rastet nichts ein, es kommt nur an.
        .haptic(.impact(weight: .light, intensity: 0.5), trigger: appeared)
        .task { appeared = true }
    }

    private var label: some View {
        Text(title)
            .scaledFont(12)
            .tracking(0.4)
            .textCase(.lowercase)
            .foregroundStyle(Palette.ink2)
    }

    private var button: some View {
        Button(action) { dismiss() }
            .buttonStyle(.plain)
            .scaledFont(12)
            .tracking(0.4)
            .textCase(.lowercase)
            .foregroundStyle(Palette.ink)
    }
}

/// ponytail: Platzhalter, bis die Foto-Erfassung dran ist.
struct PlaceholderScreen: View {
    let title: String

    var body: some View {
        VStack {
            Spacer()
            Text(title)
                .scaledFont(13, weight: .medium)
                .tracking(0.9)
                .foregroundStyle(Palette.ink2)
            Text("folgt")
                .scaledFont(22, weight: .light)
                .foregroundStyle(Palette.ink)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Palette.paper)
    }
}
