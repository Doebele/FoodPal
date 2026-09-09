import SwiftUI

/// Zeitrad in **Viertelstunden** statt in Minuten.
///
/// Dieselbe Auflösung wie der Zeitstrahl, der je Stunde vier Spalten hat, und
/// dieselbe, auf die `Entry` beim Speichern rundet. Vier Rasten statt sechzig:
/// das Rad ist in einer Bewegung dort, wo man hin will.
///
/// SwiftUIs `DatePicker` reicht `minuteInterval` nicht durch — `UIDatePicker`
/// kann es seit je. Deshalb der Umweg über zwanzig Zeilen `UIViewRepresentable`
/// statt eines selbstgebauten Rades.
struct QuarterHourPicker: UIViewRepresentable {
    @Binding var date: Date

    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .wheels
        picker.minuteInterval = 15
        // Nach vorn ist bei jetzt Schluss: ein Eintrag in der Zukunft wäre
        // unsichtbar, weil die Tagesansicht bei heute endet.
        picker.maximumDate = Date.now.startOfQuarterHour
        picker.addTarget(context.coordinator,
                         action: #selector(Coordinator.changed(_:)),
                         for: .valueChanged)
        return picker
    }

    func updateUIView(_ picker: UIDatePicker, context: Context) {
        context.coordinator.date = $date
        picker.maximumDate = Date.now.startOfQuarterHour
        if abs(picker.date.timeIntervalSince(date)) > 1 {
            picker.setDate(date, animated: false)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(date: $date) }

    final class Coordinator {
        var date: Binding<Date>
        init(date: Binding<Date>) { self.date = date }

        @objc func changed(_ picker: UIDatePicker) {
            date.wrappedValue = picker.date
        }
    }
}

/// Das Rad in einem Sheet von unten statt im Formular.
///
/// Ein `UIDatePicker` braucht die **volle Breite** — drei Räder nebeneinander,
/// Tag, Stunde, Minute. Im Formular sitzt der Zeitpunkt seit dem zweispaltigen
/// Satz in einer 213 pt schmalen Spalte, und dort lief das Rad rechts aus dem
/// Bild: die Minuten waren nicht mehr zu sehen.
///
/// Von unten hereingefahren bekommt es die ganze Breite — und passt zum Rest
/// der App, in der ohnehin alles, was eine Sache erledigt und wieder geht,
/// ein Bottom Sheet ist.
struct QuarterHourSheet: View {
    @Binding var date: Date

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "Zeitpunkt", action: "Fertig")
            QuarterHourPicker(date: $date)
                .frame(maxWidth: .infinity)
            Spacer(minLength: 0)
        }
        .background(Palette.paper)
    }
}
