import SwiftUI
import UIKit

/// Das Beschreibungsfeld als `UITextView`.
///
/// SwiftUIs `TextField` mit `@FocusState` nimmt den Fokus in diesem Sheet
/// nicht an — zugewiesen wird er, gelesen wird er als `false`, und die
/// Tastatur bleibt unten. Mehrfaches Anbieten über anderthalb Sekunden ändert
/// daran nichts. Hier ist der Fokus aber kein Beiwerk, sondern der halbe
/// Sinn des Schirms: man öffnet ihn, um sofort zu sprechen oder zu tippen.
///
/// `becomeFirstResponder()` kennt diese Zweifel nicht.
struct SpokenField: UIViewRepresentable {
    @Binding var text: String
    var font: UIFont
    /// Setzt beim ersten Erscheinen den Cursor.
    var focusOnAppear = true
    /// Aufschrift der linken Taste im Tastaturbalken — sie schaltet das
    /// Diktat, und ihre Farbe zeigt, ob es laeuft.
    var dictateTitle: String = ""
    var dictateColor: Color = Palette.ink
    var onDictate: () -> Void = {}

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        // Ohne eigenes Scrollen wächst das Feld mit dem Text, und SwiftUI
        // bekommt eine brauchbare Höhe statt eines festen Kastens.
        view.isScrollEnabled = false
        view.font = font
        view.textColor = UIColor(Palette.ink)
        view.tintColor = UIColor(Palette.ink)
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        // Der Balken haengt am Feld, nicht am Bildschirm: SwiftUIs
        // `.toolbar(placement: .keyboard)` braucht einen Wirt, den ein Sheet
        // ohne `NavigationStack` nicht hat — und der Erstantwortende ist hier
        // ohnehin ein `UITextView`. Der Balken erschien deshalb nie.
        view.inputAccessoryView = context.coordinator.bar
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        if view.text != text { view.text = text }
        view.font = font
        context.coordinator.onDictate = onDictate
        context.coordinator.setDictate(title: dictateTitle, color: UIColor(dictateColor))

        if focusOnAppear && !context.coordinator.didFocus {
            context.coordinator.didFocus = true
            DispatchQueue.main.async { view.becomeFirstResponder() }
        }
    }

    /// Ohne diese Angabe nimmt sich der Textview die ganze angebotene Höhe,
    /// und die Haarlinie darunter rutschte ans Seitenende.
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width ?? uiView.bounds.width
        let fitting = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: max(fitting.height, uiView.font?.lineHeight ?? 20))
    }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    final class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        var didFocus = false
        var onDictate: () -> Void = {}

        private let dictateButton = UIButton(type: .system)
        private let doneButton = UIButton(type: .system)
        let bar = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 46))

        init(text: Binding<String>) {
            _text = text
            super.init()

            // Ein schlichter Balken statt `UIToolbar`: seit iOS 26 setzt die
            // Toolbar ihre Tasten in Glaskapseln, und Kapseln kennt dieser
            // Entwurf nicht. Papier, eine Haarlinie, zwei Aufschriften.
            bar.backgroundColor = UIColor(Palette.paper)
            bar.autoresizingMask = .flexibleWidth

            let rule = UIView()
            rule.backgroundColor = UIColor(Palette.rule)
            rule.translatesAutoresizingMaskIntoConstraints = false

            dictateButton.addTarget(self, action: #selector(dictate), for: .touchUpInside)
            doneButton.addTarget(self, action: #selector(done), for: .touchUpInside)
            doneButton.setAttributedTitle(
                NSAttributedString(
                    string: String(localized: "Fertig").lowercased(),
                    attributes: Self.style(.regular, UIColor(Palette.ink))
                ),
                for: .normal
            )

            for view in [rule, dictateButton, doneButton] {
                view.translatesAutoresizingMaskIntoConstraints = false
                bar.addSubview(view)
            }
            NSLayoutConstraint.activate([
                rule.topAnchor.constraint(equalTo: bar.topAnchor),
                rule.leadingAnchor.constraint(equalTo: bar.leadingAnchor),
                rule.trailingAnchor.constraint(equalTo: bar.trailingAnchor),
                rule.heightAnchor.constraint(equalToConstant: 1),
                dictateButton.leadingAnchor.constraint(
                    equalTo: bar.leadingAnchor, constant: Metric.margin
                ),
                dictateButton.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
                doneButton.trailingAnchor.constraint(
                    equalTo: bar.trailingAnchor, constant: -Metric.margin
                ),
                doneButton.centerYAnchor.constraint(equalTo: bar.centerYAnchor)
            ])
        }

        func setDictate(title: String, color: UIColor) {
            dictateButton.setAttributedTitle(
                NSAttributedString(
                    string: title.lowercased(),
                    attributes: Self.style(.medium, color)
                ),
                for: .normal
            )
        }

        private static func style(_ weight: Font.Weight, _ colour: UIColor) -> [NSAttributedString.Key: Any] {
            [
                .font: UIFont(name: Fira.name(weight, .default, condensed: false), size: 15)
                    ?? .systemFont(ofSize: 15),
                .foregroundColor: colour
            ]
        }

        @objc private func dictate() { onDictate() }
        @objc private func done() { UIApplication.shared.endEditing() }

        func textViewDidChange(_ view: UITextView) { text = view.text }
    }
}

extension UIApplication {
    /// Tastatur schliessen, ohne dass jede Ansicht dafuer einen `FocusState`
    /// halten muss.
    func endEditing() {
        connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?
            .endEditing(true)
    }
}
