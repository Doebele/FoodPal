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
        // unsichtbar, weil die Tagesansicht bei heute endet. Gerundet, sonst
        // liesse sich ein um 10:08 gespeicherter Eintrag (10:15) nicht mehr
        // auf seinem eigenen Wert stehen lassen.
        picker.maximumDate = Date.now.roundedToQuarterHour
        picker.addTarget(context.coordinator,
                         action: #selector(Coordinator.changed(_:)),
                         for: .valueChanged)
        return picker
    }

    func updateUIView(_ picker: UIDatePicker, context: Context) {
        context.coordinator.date = $date
        picker.maximumDate = Date.now.roundedToQuarterHour
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
