import Foundation
import FoundationModels

/// Apples Modell auf dem Gerät — kein Schlüssel, kein Netz, keine Kosten.
///
/// Der Gewinn gegenüber den gehosteten Diensten ist nicht nur der Preis,
/// sondern `@Generable`: die Antwort **ist** die Struktur. Der nachsichtige
/// JSON-Parser, den es für die anderen braucht, entfällt hier komplett.
///
/// Die Grenze steht im SDK: `Prompt` kennt in iOS 26 keinen Bildeingang.
/// Dieser Weg schätzt deshalb **nur aus Beschreibungen**; Fotos bleiben Sache
/// der gehosteten Modelle, bis Apple das nachreicht.
@available(iOS 26.0, *)
enum AppleEstimator {

    @Generable
    struct Meals {
        @Guide(description: "Ein Eintrag je genanntem Gericht")
        var items: [Meal]
    }

    @Generable
    struct Meal {
        @Guide(description: "Kurze Bezeichnung des Gerichts in der Sprache der App")
        var name: String
        @Guide(description: "Kalorien der genannten Portion, ohne Einheit")
        var kcal: Int
        @Guide(description: "Protein in Gramm")
        var proteinG: Int
        @Guide(description: "Kohlenhydrate in Gramm")
        var carbsG: Int
        @Guide(description: "Fett in Gramm")
        var fatG: Int
        @Guide(description: "Genannter Zeitpunkt in Ortszeit, Schreibweise 2026-01-31T21:00; leer lassen, wenn gar keine Zeit genannt wurde")
        var date: String
    }

    static var isAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }

    /// Warum es gerade nicht geht, in Klartext. „Nicht verfügbar" allein
    /// liesse einen im Dunkeln, ob das Gerät zu alt ist oder nur ein Schalter
    /// in den Systemeinstellungen aus.
    static var status: String {
        switch SystemLanguageModel.default.availability {
        case .available:
            String(localized: "Bereit — ohne Netz, ohne Schlüssel.")
        case .unavailable(.deviceNotEligible):
            String(localized: "Dieses Gerät unterstützt Apple Intelligence nicht.")
        case .unavailable(.appleIntelligenceNotEnabled):
            String(localized: "Apple Intelligence ist in den Systemeinstellungen ausgeschaltet.")
        case .unavailable(.modelNotReady):
            String(localized: "Das Modell wird noch geladen. Später erneut versuchen.")
        @unknown default:
            String(localized: "Nicht verfügbar.")
        }
    }

    static func estimate(text: String, now: Date = .now) async throws -> [MealEstimate] {
        let session = LanguageModelSession(instructions: """
        Du schätzt Nährwerte von Mahlzeiten aus einer Beschreibung.
        Die Bezeichnungen gibst du auf \(VisionEstimator.answerLanguage) zurück.
        Jetzt ist \(ISO8601DateFormatter.local.string(from: now)) in Ortszeit.
        Nenne jedes Gericht einzeln; fasse Beilagen und Getränke nicht zusammen.
        Berücksichtige Mengenangaben wie "klein", "drei Scheiben" oder "dünn bestrichen".
        Rechne Zeitangaben in einen Zeitpunkt um: "gestern Abend um neun" ebenso
        wie "zum Fruehstueck" (dann 08:00 annehmen).
        """)

        let answer = try await session.respond(to: text, generating: Meals.self)

        return answer.content.items.map { meal in
            MealEstimate(
                name: meal.name,
                kcal: Double(meal.kcal),
                proteinG: Double(meal.proteinG),
                carbsG: Double(meal.carbsG),
                fatG: Double(meal.fatG),
                date: VisionEstimator.localDate(meal.date)
            )
        }
    }
}
