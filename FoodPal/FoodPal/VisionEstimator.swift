import Foundation
import UIKit

/// Woher die Schätzung kommt.
///
/// Es gibt nur **zwei Körperformen**, nicht eine je Anbieter: Anthropic hat
/// eine eigene, alles Übrige spricht die OpenAI-Form. Deshalb ein `switch`
/// in einer Funktion und kein Protokoll mit Conformances.
///
/// `custom` ist dadurch weit mehr als LM Studio — jeder OpenAI-kompatible
/// Dienst passt hinein, mit Adresse, Modellnamen und optionalem Schlüssel:
/// OpenRouter, Gemini über seinen Kompatibilitätspfad, xAI Grok, Z.ai GLM,
/// Groq, Mistral, DeepSeek. Siehe `docs/anbieter.md`.
enum Provider: String, CaseIterable, Identifiable, Codable {
    // Rohwert "local" bleibt, damit bestehende Einstellungen weitergelten.
    case claude, openAI, custom = "local"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .claude: "Claude"
        case .openAI: "OpenAI"
        case .custom: "Eigener Dienst"
        }
    }

    /// Schlüssel in der Keychain. Lokal braucht keinen.
    var keychainAccount: String? {
        switch self {
        case .claude: "anthropic-key"
        case .openAI: "openai-key"
        case .custom: "custom-key"
        }
    }

    var defaultModel: String {
        switch self {
        case .claude: "claude-sonnet-5"
        case .openAI: "gpt-4o"
        case .custom: "zai-org/glm-4.6v-flash"
        }
    }

    /// Nur die beiden festen Dienste **verlangen** einen Schlüssel; ein
    /// eigener Endpunkt darf einen haben, muss aber nicht — LM Studio im
    /// eigenen Netz braucht keinen.
    var needsKey: Bool { self != .custom }
}

struct MealEstimate: Codable, Equatable, Sendable {
    var name: String
    var kcal: Double
    var proteinG: Double?
    var carbsG: Double?
    var fatG: Double?
}

enum VisionEstimator {

    enum Failure: LocalizedError {
        case missingKey
        case badResponse(Int, String)
        case unreadable(String)
        case badImage

        var errorDescription: String? {
            switch self {
            case .missingKey: "Kein API-Schlüssel hinterlegt."
            case .badResponse(let code, let body):
                "Der Dienst antwortete mit \(code). \(body.prefix(140))"
            case .unreadable: "Die Antwort war nicht lesbar."
            case .badImage: "Das Bild ließ sich nicht aufbereiten."
            }
        }
    }

    private static let prompt = """
    Schätze die Nährwerte dieser Mahlzeit anhand des Fotos.
    Antworte ausschließlich mit JSON, ohne Erklärung und ohne Codeblock:
    {"name":"kurze deutsche Bezeichnung","kcal":0,"proteinG":0,"carbsG":0,"fatG":0}
    Portionsgröße aus dem Bild abschätzen. Zahlen ohne Einheiten.
    """

    // MARK: - Aufruf

    static func estimate(
        image: UIImage,
        provider: Provider,
        model: String,
        baseURL: String
    ) async throws -> MealEstimate {
        guard let jpeg = downscaled(image) else { throw Failure.badImage }
        let base64 = jpeg.base64EncodedString()

        let key = provider.keychainAccount.flatMap(Keychain.get)
        if provider.needsKey, key?.isEmpty != false { throw Failure.missingKey }

        let request = provider == .claude
            ? anthropicRequest(base64: base64, model: model, key: key ?? "")
            : openAIRequest(base64: base64, model: model, key: key, baseURL: baseURL)

        let (data, response) = try await URLSession.shared.data(for: request)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            throw Failure.badResponse(code, String(data: data, encoding: .utf8) ?? "")
        }

        let text = provider == .claude
            ? anthropicText(from: data)
            : openAIText(from: data)
        guard let text else { throw Failure.unreadable("") }
        return try parse(text)
    }

    // MARK: - Antwort lesen

    /// Nachsichtig statt streng: Markdown-Zäune abstreifen, von der ersten
    /// `{` bis zur letzten `}` schneiden, dann decodieren.
    ///
    /// Kein `response_format` je Anbieter — lokale Modelle ignorieren das
    /// ohnehin häufig, und ein toleranter Parser deckt alle drei Fälle mit
    /// weniger Code ab.
    static func parse(_ raw: String) throws -> MealEstimate {
        guard let start = raw.firstIndex(of: "{"),
              let end = raw.lastIndex(of: "}"), start < end else {
            throw Failure.unreadable(raw)
        }
        let slice = String(raw[start...end])
        guard let data = slice.data(using: .utf8) else { throw Failure.unreadable(raw) }

        let decoder = JSONDecoder()
        if let estimate = try? decoder.decode(MealEstimate.self, from: data) {
            return estimate
        }
        // Zahlen kommen mitunter als Text zurück ("kcal": "620").
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw Failure.unreadable(raw)
        }
        func number(_ key: String) -> Double? {
            if let value = object[key] as? Double { return value }
            if let value = object[key] as? Int { return Double(value) }
            if let text = object[key] as? String {
                return Double(text.replacingOccurrences(of: ",", with: "."))
            }
            return nil
        }
        guard let kcal = number("kcal") else { throw Failure.unreadable(raw) }
        return MealEstimate(
            name: (object["name"] as? String) ?? "Mahlzeit",
            kcal: kcal,
            proteinG: number("proteinG"),
            carbsG: number("carbsG"),
            fatG: number("fatG")
        )
    }

    private static func anthropicText(from data: Data) -> String? {
        struct Response: Decodable {
            struct Block: Decodable { let text: String? }
            let content: [Block]
        }
        return (try? JSONDecoder().decode(Response.self, from: data))?
            .content.compactMap(\.text).joined()
    }

    private static func openAIText(from data: Data) -> String? {
        struct Response: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable { let content: String? }
                let message: Message
            }
            let choices: [Choice]
        }
        return (try? JSONDecoder().decode(Response.self, from: data))?
            .choices.first?.message.content
    }

    // MARK: - Anfragen

    private static func anthropicRequest(base64: String, model: String, key: String) -> URLRequest {
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.timeoutInterval = 60
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "model": model,
            "max_tokens": 300,
            "messages": [[
                "role": "user",
                "content": [
                    ["type": "image",
                     "source": ["type": "base64", "media_type": "image/jpeg", "data": base64]],
                    ["type": "text", "text": prompt]
                ]
            ]]
        ])
        return request
    }

    private static func openAIRequest(
        base64: String, model: String, key: String?, baseURL: String
    ) -> URLRequest {
        let base = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        var request = URLRequest(url: URL(string: base + "/chat/completions")!)
        request.httpMethod = "POST"
        if let key, !key.isEmpty {
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "model": model,
            "max_tokens": 300,
            "messages": [[
                "role": "user",
                "content": [
                    ["type": "text", "text": prompt],
                    ["type": "image_url",
                     "image_url": ["url": "data:image/jpeg;base64,\(base64)"]]
                ]
            ]]
        ])
        return request
    }

    // MARK: - Bild

    /// Auf 1024 px längste Kante und JPEG 0,7 — ein volles Kamerabild kostet
    /// sonst Sekunden Übertragung und beim Anbieter unnötig Geld.
    static func downscaled(_ image: UIImage, maxEdge: CGFloat = 1024) -> Data? {
        let longest = max(image.size.width, image.size.height)
        let scale = longest > maxEdge ? maxEdge / longest : 1
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        return resized.jpegData(compressionQuality: 0.7)
    }
}

// MARK: - Verbindungstest

extension VisionEstimator {
    /// Fragt die Modellliste ab. Billiger und ehrlicher als eine
    /// Probe-Schätzung: es kostet keine Tokens und sagt trotzdem, ob
    /// Adresse, Schlüssel und Erreichbarkeit stimmen.
    static func probe(provider: Provider, baseURL: String) async -> String {
        let key = provider.keychainAccount.flatMap(Keychain.get)
        if provider.needsKey, key?.isEmpty != false { return "Kein Schlüssel hinterlegt." }

        var request: URLRequest
        switch provider {
        case .claude:
            request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/models")!)
            request.setValue(key, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        case .openAI:
            request = URLRequest(url: URL(string: "https://api.openai.com/v1/models")!)
            request.setValue("Bearer \(key ?? "")", forHTTPHeaderField: "Authorization")
        case .custom:
            let base = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
            guard let url = URL(string: base + "/models") else { return "Adresse ist ungültig." }
            request = URLRequest(url: url)
            if let key, !key.isEmpty {
                request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
            }
        }
        request.timeoutInterval = 12

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            switch code {
            case 200..<300: return "Verbindung steht."
            case 401, 403: return "Schlüssel wird abgelehnt (\(code))."
            default: return "Antwort \(code)."
            }
        } catch {
            return error.localizedDescription
        }
    }
}
