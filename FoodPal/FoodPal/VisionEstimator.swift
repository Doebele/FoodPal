import Foundation
import UIKit

extension ISO8601DateFormatter {
    /// Ortszeit ohne Zonenangabe — in dieser Schreibweise fragt der Prompt
    /// nach dem Zeitpunkt, und in ihr kommt die Antwort zurück.
    static let local: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate,
                                   .withColonSeparatorInTime]
        formatter.timeZone = .current
        return formatter
    }()
}

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
    case apple
    case claude, openAI, openRouter, gemini, grok, glm, deepSeek, muse, mistral
    case lmStudio, ollama, custom = "local"

    var id: String { rawValue }

    /// Die drei Arten, an eine Schätzung zu kommen — und damit die einzige
    /// Frage, die beim Einrichten wirklich zählt: was kostet es und wohin geht
    /// das Bild. Die Gruppe leitet auch ab, welche Felder überhaupt nötig sind.
    enum Group: String, CaseIterable, Identifiable {
        case onDevice = "auf dem gerät"
        case hosted = "gehostet · mit schlüssel"
        case selfRun = "selbst betrieben"

        var id: String { rawValue }
    }

    var group: Group {
        switch self {
        case .apple: .onDevice
        case .lmStudio, .ollama, .custom: .selfRun
        default: .hosted
        }
    }

    /// Apples Modell kennt genau sich selbst — dort gibt es nichts zu wählen.
    var hasModelChoice: Bool { group != .onDevice }

    /// Adresse, Standardmodell und Bezugsquelle des Schlüssels — eine Zeile je
    /// Anbieter. Eine Tabelle statt drei paralleler `switch`, damit beim
    /// Nachtragen eines Dienstes nichts an drei Stellen auseinanderläuft.
    ///
    /// `url == nil` heisst: die Adresse steht nicht fest, weil der Rechner im
    /// eigenen Netz hängt oder frei gewählt wird.
    private var spec: (label: String, url: String?, model: String, keys: String) {
        switch self {
        case .apple:      ("Apple", nil, "", "")
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
    var editableAddress: Bool { group == .selfRun }

    /// Vorschlag fürs Adressfeld — die Portnummern unterscheiden die beiden,
    /// die IP muss ohnehin jeder selbst eintragen.
    var defaultAddress: String {
        switch self {
        case .lmStudio: "http://192.168.1.42:1234/v1"
        case .ollama: "http://192.168.1.42:11434/v1"
        default: ""
        }
    }

    /// Fotos kann nur, wer Bilder entgegennimmt. Apples `Prompt` kennt in
    /// iOS 26 keinen Bildeingang — dort bleibt es bei Beschreibungen.
    var readsPhotos: Bool { self != .apple }

    /// Die Dienste im eigenen Netz kommen ohne Schlüssel aus, beim freien Slot
    /// ist er erlaubt, aber nicht verlangt. Alles Gehostete braucht einen.
    var needsKey: Bool { group == .hosted }

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
        switch group {
        case .hosted:
            Keychain.has(keychainAccount)
        case .onDevice:
            // Nicht eingerichtet, sondern nicht vorhanden: ohne Apple
            // Intelligence bleibt das Quadrat leer, statt Bereitschaft zu
            // behaupten, die das Geraet nicht hat.
            if #available(iOS 26.0, *) { AppleEstimator.isAvailable } else { false }
        case .selfRun:
            true
        }
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
    /// Nur bei gesprochenen Einträgen belegt: „gestern Abend um neun" löst das
    /// Modell auf, weil es die Ortszeit im Prompt mitbekommt.
    var date: Date?
}

enum VisionEstimator {

    enum Failure: LocalizedError {
        case missingKey
        case badResponse(Int, String)
        case unreadable(String)
        case badImage
        case noPhotos(String)
        case needsNewerOS

        var errorDescription: String? {
            switch self {
            case .missingKey: "Kein API-Schlüssel hinterlegt."
            case .badResponse(let code, let body):
                "Der Dienst antwortete mit \(code). \(body.prefix(140))"
            case .unreadable: "Die Antwort war nicht lesbar."
            case .badImage: "Das Bild ließ sich nicht aufbereiten."
            case .noPhotos(let label):
                "\(label) schätzt nur aus Beschreibungen. Für Fotos in den Einstellungen einen anderen Dienst wählen."
            case .needsNewerOS: "Dieser Dienst braucht iOS 26."
            }
        }
    }

    private static let photoPrompt = """
    Schätze die Nährwerte dieser Mahlzeit anhand des Fotos.
    Antworte ausschließlich mit JSON, ohne Erklärung und ohne Codeblock:
    {"name":"kurze deutsche Bezeichnung","kcal":0,"proteinG":0,"carbsG":0,"fatG":0}
    Portionsgröße aus dem Bild abschätzen. Zahlen ohne Einheiten.
    """

    /// Anders als beim Foto ein **Array**: „Spaghetti Bolognese, dazu eine
    /// kleine Minestrone" sind zwei Gerichte und sollen zwei Einträge werden.
    /// Und mit der Ortszeit im Prompt kann das Modell „gestern Abend um neun"
    /// selbst auflösen — sonst müsste man jeden Nachtrag von Hand datieren.
    private static func spokenPrompt(now: Date) -> String {
        let stamp = ISO8601DateFormatter.local.string(from: now)
        return """
        Jetzt ist \(stamp) (Ortszeit). Schätze die Nährwerte der beschriebenen Mahlzeit.
        Antworte ausschließlich mit einem JSON-Array, ohne Erklärung und ohne Codeblock:
        [{"name":"kurze deutsche Bezeichnung","kcal":0,"proteinG":0,"carbsG":0,"fatG":0,"date":"JJJJ-MM-TTTHH:MM"}]
        Ein Objekt je Gericht — nenne Beilagen und Getränke einzeln, fasse sie nicht zusammen.
        Mengenangaben wie "klein", "drei Scheiben" oder "dünn bestrichen" berücksichtigen.
        "date" ist der genannte Zeitpunkt in Ortszeit; ohne Angabe das Feld weglassen.
        Zahlen ohne Einheiten.
        """
    }

    // MARK: - Aufruf

    static func estimate(
        image: UIImage,
        provider: Provider,
        model: String,
        baseURL: String
    ) async throws -> MealEstimate {
        guard provider.readsPhotos else { throw Failure.noPhotos(provider.label) }
        guard let jpeg = downscaled(image) else { throw Failure.badImage }
        let answer = try await send(
            base64: jpeg.base64EncodedString(),
            prompt: photoPrompt,
            provider: provider, model: model, baseURL: baseURL
        )
        return try parse(answer)
    }

    /// Derselbe Weg ohne Bild. Es braucht keine neue Anbieterform: beide
    /// Körper tragen ohnehin eine Liste von Inhaltsblöcken, der Bildblock
    /// entfällt hier einfach.
    static func estimate(
        text: String,
        provider: Provider,
        model: String,
        baseURL: String,
        now: Date = .now
    ) async throws -> [MealEstimate] {
        // Apple laeuft nicht ueber HTTP, sondern ueber FoundationModels — die
        // Antwort ist dort bereits die Struktur, es gibt nichts zu parsen.
        if provider == .apple {
            guard #available(iOS 26.0, *) else { throw Failure.needsNewerOS }
            return try await AppleEstimator.estimate(text: text, now: now)
        }

        let answer = try await send(
            base64: nil,
            prompt: spokenPrompt(now: now) + "\n\nBeschreibung:\n" + text,
            provider: provider, model: model, baseURL: baseURL
        )
        let items = parseList(answer)
        guard !items.isEmpty else { throw Failure.unreadable(answer) }
        return items
    }

    private static func send(
        base64: String?,
        prompt: String,
        provider: Provider,
        model: String,
        baseURL: String
    ) async throws -> String {
        let key = Keychain.get(provider.keychainAccount)
        if provider.needsKey, key?.isEmpty != false { throw Failure.missingKey }

        let base = provider.fixedBaseURL ?? baseURL
        let request = provider == .claude
            ? anthropicRequest(base64: base64, prompt: prompt, model: model, key: key ?? "", baseURL: base)
            : openAIRequest(base64: base64, prompt: prompt, model: model, key: key, baseURL: base)

        let (data, response) = try await URLSession.shared.data(for: request)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            throw Failure.badResponse(code, String(data: data, encoding: .utf8) ?? "")
        }

        let text = provider == .claude ? anthropicText(from: data) : openAIText(from: data)
        guard let text else { throw Failure.unreadable("") }
        return text
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

    /// Mehrere Gerichte aus einer gesprochenen Beschreibung.
    ///
    /// Ebenso nachsichtig wie `parse`: Modelle liefern hier mal ein Array, mal
    /// ein Objekt mit `items`, mal — wenn nur ein Gericht genannt war — doch
    /// wieder ein einzelnes Objekt. Alle drei sind brauchbar, also werden alle
    /// drei genommen.
    static func parseList(_ raw: String) -> [MealEstimate] {
        guard let data = slice(raw) else { return [] }

        let objects: [[String: Any]]
        switch try? JSONSerialization.jsonObject(with: data) {
        case let array as [[String: Any]]:
            objects = array
        case let object as [String: Any]:
            objects = (object["items"] as? [[String: Any]])
                ?? (object["meals"] as? [[String: Any]])
                ?? [object]
        default:
            return []
        }

        return objects.compactMap { object in
            func number(_ key: String) -> Double? {
                if let value = object[key] as? Double { return value }
                if let value = object[key] as? Int { return Double(value) }
                if let text = object[key] as? String {
                    return Double(text.replacingOccurrences(of: ",", with: "."))
                }
                return nil
            }
            guard let kcal = number("kcal") else { return nil }
            return MealEstimate(
                name: (object["name"] as? String) ?? "Mahlzeit",
                kcal: kcal,
                proteinG: number("proteinG"),
                carbsG: number("carbsG"),
                fatG: number("fatG"),
                date: (object["date"] as? String).flatMap(localDate)
            )
        }
    }

    /// Vom ersten `{` oder `[` bis zur passenden letzten Klammer — dieselbe
    /// Nachsicht wie bei `parse`, nur auch für Arrays.
    private static func slice(_ raw: String) -> Data? {
        let openers: [(Character, Character)] = [("[", "]"), ("{", "}")]
        let found = openers.compactMap { open, close -> (Int, String.Index, String.Index)? in
            guard let start = raw.firstIndex(of: open),
                  let end = raw.lastIndex(of: close), start < end else { return nil }
            return (raw.distance(from: raw.startIndex, to: start), start, end)
        }
        // Die äussere Klammer ist die, die zuerst auftaucht.
        guard let outer = found.min(by: { $0.0 < $1.0 }) else { return nil }
        return String(raw[outer.1...outer.2]).data(using: .utf8)
    }

    /// Das Modell antwortet in Ortszeit ohne Zonenangabe — genau so, wie der
    /// Prompt es verlangt. Mit Zone geschriebene Antworten werden trotzdem
    /// genommen; manche Modelle hängen sie unaufgefordert an.
    static func localDate(_ text: String) -> Date? {
        if let date = ISO8601DateFormatter.local.date(from: text) { return date }
        let withZone = ISO8601DateFormatter()
        withZone.formatOptions = [.withInternetDateTime]
        return withZone.date(from: text)
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
        base64: String?, prompt: String, model: String, key: String, baseURL: String
    ) -> URLRequest {
        var request = URLRequest(url: URL(string: trimmed(baseURL) + "/messages")!)
        request.httpMethod = "POST"
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.timeoutInterval = 60

        var content: [[String: Any]] = []
        if let base64 {
            content.append(["type": "image",
                            "source": ["type": "base64", "media_type": "image/jpeg", "data": base64]])
        }
        content.append(["type": "text", "text": prompt])

        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "model": model,
            "max_tokens": 800,
            "messages": [["role": "user", "content": content]]
        ])
        return request
    }

    private static func openAIRequest(
        base64: String?, prompt: String, model: String, key: String?, baseURL: String
    ) -> URLRequest {
        var request = URLRequest(url: URL(string: trimmed(baseURL) + "/chat/completions")!)
        request.httpMethod = "POST"
        if let key, !key.isEmpty {
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        var content: [[String: Any]] = [["type": "text", "text": prompt]]
        if let base64 {
            content.append(["type": "image_url",
                            "image_url": ["url": "data:image/jpeg;base64,\(base64)"]])
        }

        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "model": model,
            "max_tokens": 800,
            "messages": [["role": "user", "content": content]]
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
    /// Ein Eintrag aus `/models`.
    ///
    /// `seesImages` ist **dreiwertig**: manche Dienste nennen die Eingabearten
    /// je Modell, die meisten nicht. `nil` heisst deshalb „unbekannt", nicht
    /// „nein" — geraten wird hier nicht.
    struct ListedModel: Hashable, Sendable {
        let id: String
        let seesImages: Bool?
    }

    static func probe(provider: Provider, model: String, baseURL: String) async -> String {
        if provider == .apple {
            guard #available(iOS 26.0, *) else { return "Dieser Dienst braucht iOS 26." }
            return AppleEstimator.status
        }

        guard let request = modelsRequest(provider, baseURL) else {
            return provider.needsKey && !Keychain.has(provider.keychainAccount)
                ? "Kein Schlüssel hinterlegt."
                : "Adresse fehlt oder ist ungültig."
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            switch code {
            case 200..<300:
                // Modell-IDs wandern; ein Tippfehler oder ein abgekündigter
                // Name fiele sonst erst beim ersten Foto auf. Geprüft wird
                // gegen die **ganze** Liste: die Frage ist, ob es den Namen
                // gibt, nicht ob das Modell sehen kann.
                let listed = parseModels(data)
                if listed.isEmpty { return "Verbindung steht." }
                return listed.contains { $0.id == model }
                    ? "Verbindung steht, Modell vorhanden."
                    : "Verbindung steht, aber \(model) ist nicht in der Liste."
            case 401, 403: return "Schlüssel wird abgelehnt (\(code))."
            default: return "Antwort \(code)."
            }
        } catch {
            return error.localizedDescription
        }
    }

    /// Die Modellliste des Dienstes, für die Auswahl in den Einstellungen.
    static func models(provider: Provider, baseURL: String) async throws -> [ListedModel] {
        guard let request = modelsRequest(provider, baseURL) else {
            throw provider.needsKey && !Keychain.has(provider.keychainAccount)
                ? Failure.missingKey
                : Failure.unreadable("Adresse fehlt oder ist ungültig.")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            throw Failure.badResponse(code, String(data: data, encoding: .utf8) ?? "")
        }
        return parseModels(data)
    }

    /// Eine Anfrage für beide Zwecke — Test und Auswahl fragen dasselbe ab.
    private static func modelsRequest(_ provider: Provider, _ baseURL: String) -> URLRequest? {
        let key = Keychain.get(provider.keychainAccount)
        if provider.needsKey, key?.isEmpty != false { return nil }

        let base = provider.fixedBaseURL ?? baseURL
        guard !base.isEmpty, let url = URL(string: trimmed(base) + "/models") else { return nil }

        var request = URLRequest(url: url)
        if provider == .claude {
            request.setValue(key, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        } else if let key, !key.isEmpty {
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = 12
        return request
    }

    /// Anthropic und die OpenAI-Form liefern beide `{"data":[{"id":…}]}`.
    ///
    /// Manche Dienste — OpenRouter etwa — nennen dort unter `architecture`
    /// auch die Eingabearten. Wo sie stehen, lässt sich sagen, ob ein Modell
    /// Bilder annimmt; wo nicht, bleibt es offen.
    static func parseModels(_ data: Data) -> [ListedModel] {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = root["data"] as? [[String: Any]] else { return [] }

        return items.compactMap { item in
            guard let id = item["id"] as? String else { return nil }
            let modalities = (item["architecture"] as? [String: Any])?["input_modalities"] as? [String]
            return ListedModel(id: id, seesImages: modalities.map { $0.contains("image") })
        }
        .sorted { $0.id < $1.id }
    }
}
