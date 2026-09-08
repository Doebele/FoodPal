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
    // Rohwert "local" bleibt bei custom, damit bestehende Einstellungen und
    // der dort hinterlegte Keychain-Eintrag weitergelten.
    case claude, openAI, openRouter, gemini, grok, glm, deepSeek, muse, mistral
    case lmStudio, ollama, custom = "local"

    var id: String { rawValue }

    /// Adresse, Standardmodell und Bezugsquelle des Schlüssels — eine Zeile je
    /// Anbieter. Eine Tabelle statt drei paralleler `switch`, damit beim
    /// Nachtragen eines Dienstes nichts an drei Stellen auseinanderläuft.
    ///
    /// `url == nil` heisst: die Adresse steht nicht fest, weil der Rechner im
    /// eigenen Netz hängt oder frei gewählt wird.
    private var spec: (label: String, url: String?, model: String, keys: String) {
        switch self {
        case .claude:     ("Claude", "https://api.anthropic.com/v1", "claude-sonnet-5", "https://console.anthropic.com/settings/keys")
        case .openAI:     ("OpenAI", "https://api.openai.com/v1", "gpt-4o", "https://platform.openai.com/api-keys")
        case .openRouter: ("OpenRouter", "https://openrouter.ai/api/v1", "anthropic/claude-sonnet-5", "https://openrouter.ai/keys")
        case .gemini:     ("Gemini", "https://generativelanguage.googleapis.com/v1beta/openai", "gemini-2.5-flash", "https://aistudio.google.com/apikey")
        case .grok:       ("Grok", "https://api.x.ai/v1", "grok-4", "https://console.x.ai")
        case .glm:        ("GLM", "https://api.z.ai/api/paas/v4", "glm-4.5v", "https://z.ai/manage-apikey/apikey-list")
        case .deepSeek:   ("DeepSeek", "https://api.deepseek.com/v1", "deepseek-v4-flash-vision-exp", "https://platform.deepseek.com/api_keys")
        case .muse:       ("Muse", "https://api.meta.ai/v1", "muse-spark-1.1", "https://dev.meta.ai")
        case .mistral:    ("Mistral", "https://api.mistral.ai/v1", "pixtral-large-latest", "https://console.mistral.ai/api-keys")
        case .lmStudio:   ("LM Studio", nil, "zai-org/glm-4.6v-flash", "")
        case .ollama:     ("Ollama", nil, "qwen3-vl", "")
        case .custom:     ("Eigener Dienst", nil, "", "")
        }
    }

    var label: String { spec.label }
    var defaultModel: String { spec.model }

    /// Seite, auf der man den Schlüssel holt — leer bei den schlüssellosen.
    var keyPage: URL? { spec.keys.isEmpty ? nil : URL(string: spec.keys) }

    /// Dieselbe Adresse als Beschriftung. Das Schema wegzulassen ist die
    /// gewohnte Schreibweise und spart eine Zeile Umbruch.
    var keyPageLabel: String {
        spec.keys.replacingOccurrences(of: "https://", with: "")
    }

    /// Feste Adresse, wo es eine gibt. Sonst kommt sie aus den Einstellungen.
    var fixedBaseURL: String? { spec.url }
    var editableAddress: Bool { spec.url == nil }

    /// Vorschlag fürs Adressfeld — die Portnummern unterscheiden die beiden,
    /// die IP muss ohnehin jeder selbst eintragen.
    var defaultAddress: String {
        switch self {
        case .lmStudio: "http://192.168.1.42:1234/v1"
        case .ollama: "http://192.168.1.42:11434/v1"
        default: ""
        }
    }

    /// Die Dienste im eigenen Netz kommen ohne Schlüssel aus, beim freien Slot
    /// ist er erlaubt, aber nicht verlangt. Alles Gehostete braucht einen.
    var needsKey: Bool {
        switch self {
        case .lmStudio, .ollama, .custom: false
        default: true
        }
    }

    /// Je Anbieter ein eigenes Fach — wer zwischen zweien wechselt, tippt den
    /// Schlüssel nicht jedes Mal neu ein. Die drei ersten Namen sind
    /// historisch, damit bereits hinterlegte Schlüssel auffindbar bleiben.
    var keychainAccount: String {
        switch self {
        case .claude: "anthropic-key"
        case .openAI: "openai-key"
        case .custom: "custom-key"
        default: rawValue + "-key"
        }
    }

    /// Eingerichtet heisst: es liegt ein Schlüssel bereit, oder der Dienst
    /// braucht keinen. Nur so lässt sich in der Liste sehen, wohin man
    /// zurückwechseln kann, ohne etwas neu einzutragen.
    var isConfigured: Bool {
        needsKey ? Keychain.has(keychainAccount) : true
    }

    // MARK: - Werte je Anbieter
    //
    // Beide lesen aus dem JSON der Einstellungen und fallen auf die Vorgabe
    // zurueck. Dadurch bleibt erhalten, was fuer einen Anbieter eingerichtet
    // wurde, auch wenn zwischendurch ein anderer benutzt wird.

    func model(from json: String) -> String {
        let stored = PerProvider.value(json, self)
        return stored.isEmpty ? defaultModel : stored
    }

    func address(from json: String) -> String {
        if let fixed = fixedBaseURL { return fixed }
        let stored = PerProvider.value(json, self)
        return stored.isEmpty ? defaultAddress : stored
    }
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

        let key = Keychain.get(provider.keychainAccount)
        if provider.needsKey, key?.isEmpty != false { throw Failure.missingKey }

        let base = provider.fixedBaseURL ?? baseURL
        let request = provider == .claude
            ? anthropicRequest(base64: base64, model: model, key: key ?? "", baseURL: base)
            : openAIRequest(base64: base64, model: model, key: key, baseURL: base)

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

    private static func anthropicRequest(
        base64: String, model: String, key: String, baseURL: String
    ) -> URLRequest {
        var request = URLRequest(url: URL(string: trimmed(baseURL) + "/messages")!)
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
        var request = URLRequest(url: URL(string: trimmed(baseURL) + "/chat/completions")!)
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

    /// Ein abschliessender Schrägstrich in der selbst eingetragenen Adresse
    /// ergäbe sonst `//chat/completions`.
    static func trimmed(_ url: String) -> String {
        url.hasSuffix("/") ? String(url.dropLast()) : url
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
    static func probe(provider: Provider, model: String, baseURL: String) async -> String {
        let key = Keychain.get(provider.keychainAccount)
        if provider.needsKey, key?.isEmpty != false { return "Kein Schlüssel hinterlegt." }

        let base = provider.fixedBaseURL ?? baseURL
        guard !base.isEmpty, let url = URL(string: trimmed(base) + "/models") else {
            return "Adresse fehlt oder ist ungültig."
        }

        var request = URLRequest(url: url)
        if provider == .claude {
            request.setValue(key, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        } else if let key, !key.isEmpty {
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = 12

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            switch code {
            case 200..<300:
                // Modell-IDs wandern; ein Tippfehler oder ein abgekündigter
                // Name fiele sonst erst beim ersten Foto auf.
                let ids = listedModels(data)
                if ids.isEmpty { return "Verbindung steht." }
                return ids.contains(model)
                    ? "Verbindung steht, Modell vorhanden."
                    : "Verbindung steht, aber \(model) ist nicht in der Liste."
            case 401, 403: return "Schlüssel wird abgelehnt (\(code))."
            default: return "Antwort \(code)."
            }
        } catch {
            return error.localizedDescription
        }
    }

    /// Anthropic und die OpenAI-Form liefern beide `{"data":[{"id":…}]}`.
    private static func listedModels(_ data: Data) -> Set<String> {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = root["data"] as? [[String: Any]] else { return [] }
        return Set(items.compactMap { $0["id"] as? String })
    }
}
