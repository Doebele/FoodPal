# Anbieter für die Bildanalyse

Die App kennt **zwei Request-Formen**, nicht eine je Anbieter:

| Form | Wer spricht sie |
|---|---|
| Anthropic Messages | Claude |
| OpenAI Chat Completions | alle übrigen |

Ein Anbieter ist deshalb nur eine Zeile Daten, kein Code. Die Liste steht in
`Provider.spec` in [`VisionEstimator.swift`](../FoodPal/FoodPal/VisionEstimator.swift)
— Adresse, Standardmodell und Bezugsquelle des Schlüssels je Zeile:

| Dienst | Adresse | Schlüssel von | Vorgabemodell |
|---|---|---|---|
| **Apple** | — (auf dem Gerät) | — | — |
| Claude | `https://api.anthropic.com/v1` | [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys) | `claude-sonnet-5` |
| OpenAI | `https://api.openai.com/v1` | [platform.openai.com/api-keys](https://platform.openai.com/api-keys) | `gpt-4o` |
| OpenRouter | `https://openrouter.ai/api/v1` | [openrouter.ai/keys](https://openrouter.ai/keys) | `anthropic/claude-sonnet-5` |
| Gemini | `https://generativelanguage.googleapis.com/v1beta/openai` | [aistudio.google.com/apikey](https://aistudio.google.com/apikey) | `gemini-2.5-flash` |
| Grok | `https://api.x.ai/v1` | [console.x.ai](https://console.x.ai) | `grok-4` |
| GLM | `https://api.z.ai/api/paas/v4` | [z.ai/manage-apikey/apikey-list](https://z.ai/manage-apikey/apikey-list) | `glm-4.5v` |
| DeepSeek | `https://api.deepseek.com/v1` | [platform.deepseek.com/api_keys](https://platform.deepseek.com/api_keys) | `deepseek-v4-flash-vision-exp` |
| Muse | `https://api.meta.ai/v1` | [dev.meta.ai](https://dev.meta.ai) | `muse-spark-1.1` |
| Mistral | `https://api.mistral.ai/v1` | [console.mistral.ai/api-keys](https://console.mistral.ai/api-keys) | `pixtral-large-latest` |
| Kimi | `https://api.moonshot.ai/v1` | [platform.kimi.ai/console/api-keys](https://platform.kimi.ai/console/api-keys) | `kimi-k2.6` |
| LM Studio | `http://<Mac-IP>:1234/v1` | — | `zai-org/glm-4.6v-flash` |
| Ollama | `http://<Mac-IP>:11434/v1` | — | `qwen3-vl` |
| Eigener Dienst | frei | optional | frei |

**Apple** läuft über keinen der beiden Wege, sondern über das
FoundationModels-Framework: kein Schlüssel, kein Netz, keine Kosten, und dank
`@Generable` **ist** die Antwort die Struktur — der nachsichtige JSON-Parser
entfällt dort. Der Preis steht im SDK: `Prompt` kennt in iOS 26 keinen
Bildeingang, Apple schätzt deshalb **nur aus Beschreibungen**. Fotos bleiben
Sache der gehosteten Modelle, bis das nachgereicht wird (angekündigt für
iOS 27) — dann kommt in `VisionEstimator.estimate(image:)` ein Zweig dazu und
`Provider.readsPhotos` fällt weg.

Ausserdem ist es ein rund 3B grosses Modell auf dem Telefon. Kalorienschätzung
ist eine **Wissensaufgabe**, und darin sind kleine Modelle schwächer. Ob es für
den Alltag reicht, beantwortet nur der Vergleich an eigenen Mahlzeiten.

Nur Claude spricht die Anthropic-Form; alles darunter läuft durch denselben
OpenAI-Request. **Eigener Dienst** bleibt für alles, was hier nicht steht —
Groq (`https://api.groq.com/openai/v1`), DeepInfra, Together, ein eigener
Proxy. Die Adresse endet **ohne** `/chat/completions`, das hängt die App an.

Jeder Anbieter hat ein eigenes Keychain-Fach, Wechseln kostet also keinen
Schlüssel. Die Schlüsselseite steht auch im Sheet selbst und ist dort
antippbar — Ink und unterstrichen, nicht im Akzent: der gehört dem Koffein.

## Modellnamen wandern

Die Vorgaben oben stimmen zum Zeitpunkt des Eintragens und veralten. Deshalb
prüft **„Verbindung testen"** nicht nur die Erreichbarkeit, sondern vergleicht
das eingetragene Modell mit `/models` des Dienstes:

- *„Verbindung steht, Modell vorhanden."* — passt
- *„Verbindung steht, aber X ist nicht in der Liste."* — Adresse und Schlüssel
  stimmen, der Modellname nicht
- *„Verbindung steht."* — der Dienst gibt keine Modellliste heraus

Was der Test nicht sagen kann: ob das Modell **sehen** kann. `deepseek-chat`
existiert, nimmt aber keine Bilder — das zeigt sich erst am ersten Foto.

## Was nicht geht

**Cursor** ist ein Editor, keine Inferenz-API. Es gibt keinen Endpunkt, gegen den
sich ein Foto schicken ließe.

**Textmodelle.** Der Anbieter ist gleichgültig, das Modell nicht: `gpt-4o` sieht,
`deepseek-chat` nicht. Siehe oben — der Verbindungstest findet den Namen, aber
nicht die fehlenden Augen.

## Lokal im eigenen Netz

LM Studio und Ollama laufen ohne Schlüssel, brauchen aber Erreichbarkeit:

- LM Studio: Server starten, *Serve on Local Network* an
- Ollama: `OLLAMA_HOST=0.0.0.0 ollama serve`
- `Info.plist` erlaubt bereits Klartext-HTTP im lokalen Netz
  (`NSAllowsLocalNetworking`)

Unterwegs funktioniert das nicht. Wer es trotzdem will: Tailscale auf beiden
Geräten und `tailscale serve` — das ergibt eine HTTPS-Adresse unter `.ts.net`,
die überall erreichbar ist und ATS ohnehin zufriedenstellt. **LM Link** hilft
hier nicht; es vernetzt LM-Studio-Installationen untereinander, und auf dem
iPhone läuft keine.

## Nährwertdatenbank

Neben den Schätzern steht **Open Food Facts** — ohne Eintrag in den
Einstellungen, weil es nichts zu wählen gibt: kein Schlüssel, keine
Registrierung, eine feste Adresse.

Der Weg ist automatisch und hat keinen eigenen Screen. Jedes aufgenommene Foto
läuft zuerst durch `VNDetectBarcodesRequest` (EAN-13, EAN-8, UPC-E, auf dem
Originalbild — bei 1024 px ist ein EAN aus normalem Abstand nicht mehr lesbar).
Sitzt ein Code darauf und kennt die Datenbank ihn, kommen exakte Werte je 100 g
und die Bestätigung bekommt ein Mengenfeld. Sonst läuft stillschweigend der
gewohnte Weg über das LLM.

Pflicht ist ein eigener User-Agent, sonst wird die IP irgendwann gesperrt. In
`FoodDatabase.swift` steht dort die Repo-Adresse statt einer Mailadresse.
Limits: 100 Produktabfragen/min — für eine Ein-Personen-App belanglos.

**Die Datenbank ersetzt den Schätzer nicht.** Sie kennt Verpacktes mit Barcode;
ein Teller Pasta, das Gipfeli vom Bäcker und alles Selbstgekochte stehen dort
nicht. Und selbst beim Treffer bleibt die Menge zu beantworten — die Datenbank
weiss, was 100 g Joghurt haben, nicht wie viel im Becher war.

## Auswahl

Für Portionsschätzung aus einem Foto zählt genau eine Disziplin, und dort fallen
kleine Modelle ab. Ein lokales 7B-VLM erkennt „Teller mit Nudeln", schätzt die
Menge aber schlecht. Claude oder GPT liegen realistisch ±30 % daneben, kleine
lokale Modelle deutlich mehr. Deshalb der Bestätigungsschritt vor dem Speichern —
und deshalb ist der Anbieter in den Einstellungen umschaltbar statt fest.
