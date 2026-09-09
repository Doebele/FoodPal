import SwiftUI
import UIKit

/// Der Kalender hinter dem Datum in der Kopfzeile.
///
/// Gewischt wird von Tag zu Tag — das ist der Weg für gestern und vorgestern.
/// Für „irgendwann letzte Woche" wären das ein Dutzend Wischer, und deshalb
/// klappt ein Kalender auf, sobald man das Datum antippt.
///
/// `UICalendarView` statt `DatePicker`: nur der erste kann **Tage markieren**.
/// Wo schon etwas erfasst ist, sitzt ein kleines Quadrat unter der Zahl — im
/// selben Punktvokabular wie der Zeitstrahl, und man sieht auf einen Blick,
/// wo es etwas zu sehen gibt.
struct DayPicker: UIViewRepresentable {
    @Binding var selection: Date
    /// Tagesanfänge, an denen Einträge liegen.
    let marked: Set<Date>
    let range: ClosedRange<Date>
    let onPick: (Date) -> Void

    func makeUIView(context: Context) -> UICalendarView {
        let view = UICalendarView()
        view.calendar = .current
        view.locale = .current
        view.delegate = context.coordinator
        view.backgroundColor = .clear
        view.tintColor = UIColor(Palette.ink)
        view.availableDateRange = DateInterval(start: range.lowerBound, end: range.upperBound)

        let behaviour = UICalendarSelectionSingleDate(delegate: context.coordinator)
        behaviour.selectedDate = Calendar.current.dateComponents([.year, .month, .day], from: selection)
        view.selectionBehavior = behaviour
        return view
    }

    func updateUIView(_ view: UICalendarView, context: Context) {
        context.coordinator.marked = marked
        context.coordinator.onPick = onPick

        // Nur was sich geändert hat neu zeichnen: `reloadDecorations` ohne
        // Angabe gibt es nicht, und der ganze Monat flackerte sonst.
        let changed = marked.symmetricDifference(context.coordinator.drawn)
        if !changed.isEmpty {
            context.coordinator.drawn = marked
            view.reloadDecorations(
                forDateComponents: changed.map {
                    Calendar.current.dateComponents([.year, .month, .day], from: $0)
                },
                animated: false
            )
        }
    }

    /// Ohne diese Angabe nimmt sich der Kalender die ganze angebotene Höhe.
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UICalendarView, context: Context) -> CGSize? {
        let width = proposal.width ?? uiView.bounds.width
        let fitting = uiView.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        return CGSize(width: width, height: fitting.height)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(marked: marked, onPick: onPick)
    }

    final class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var marked: Set<Date>
        var drawn: Set<Date>
        var onPick: (Date) -> Void

        init(marked: Set<Date>, onPick: @escaping (Date) -> Void) {
            self.marked = marked
            self.drawn = marked
            self.onPick = onPick
        }

        func calendarView(
            _ view: UICalendarView,
            decorationFor dateComponents: DateComponents
        ) -> UICalendarView.Decoration? {
            guard let day = Calendar.current.date(from: dateComponents),
                  marked.contains(Calendar.current.startOfDay(for: day)) else { return nil }
            // Ein Quadrat, kein Punkt: dasselbe Zeichen wie im Zeitstrahl.
            return .customView {
                let mark = UIView()
                mark.backgroundColor = UIColor(Palette.ink)
                mark.frame = CGRect(x: 0, y: 0, width: 5, height: 5)
                mark.widthAnchor.constraint(equalToConstant: 5).isActive = true
                mark.heightAnchor.constraint(equalToConstant: 5).isActive = true
                return mark
            }
        }

        func dateSelection(
            _ selection: UICalendarSelectionSingleDate,
            didSelectDate dateComponents: DateComponents?
        ) {
            guard let components = dateComponents,
                  let day = Calendar.current.date(from: components) else { return }
            onPick(Calendar.current.startOfDay(for: day))
        }
    }
}
