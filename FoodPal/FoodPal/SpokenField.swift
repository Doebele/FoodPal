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
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        if view.text != text { view.text = text }
        view.font = font

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

        init(text: Binding<String>) { _text = text }

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
