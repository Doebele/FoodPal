# Anbieter für die Bildanalyse

Die App kennt **zwei Request-Formen**, nicht eine je Anbieter:

| Form | Wer spricht sie |
|---|---|
| Anthropic Messages | Claude |
| OpenAI Chat Completions | alle übrigen |

Deshalb gibt es in den Einstellungen drei Einträge, nicht dreizehn:

| Einstellung | Adresse | Schlüssel |
|---|---|---|
| **Claude** | fest | nötig |
| **OpenAI** | fest | nötig |
| **Eigener Dienst** | frei | optional |

„Eigener Dienst" ist der Sammelplatz für alles, was die OpenAI-Form spricht.
Adresse, Modellname und — falls der Dienst einen verlangt — Schlüssel eintragen,
„Verbindung testen" drücken, fertig. Kein Code je Anbieter.

## Getestete Adressen

| Dienst | Adresse | Schlüssel | Beispielmodell |
|---|---|---|---|
| OpenRouter | `https://openrouter.ai/api/v1` | ja | `anthropic/claude-sonnet-5` |
| Google Gemini | `https://generativelanguage.googleapis.com/v1beta/openai` | ja | `gemini-2.5-flash` |
| xAI Grok | `https://api.x.ai/v1` | ja | `grok-4` |
| Z.ai GLM | `https://api.z.ai/api/paas/v4` | ja | `glm-4.5v` |
| DeepSeek | `https://api.deepseek.com/v1` | ja | `deepseek-v4-flash-vision-exp` |
| Meta Muse | `https://api.meta.ai/v1` | ja | `muse-spark-1.1` |
| Groq | `https://api.groq.com/openai/v1` | ja | — |
| Mistral | `https://api.mistral.ai/v1` | ja | `pixtral-large-latest` |
| LM Studio | `http://<Mac-IP>:1234/v1` | nein | `zai-org/glm-4.6v-flash` |
| Ollama | `http://<Mac-IP>:11434/v1` | nein | `qwen3-vl` |

Die Adresse endet **ohne** `/chat/completions` — das hängt die App an.

## Was nicht geht

**Cursor** ist ein Editor, keine Inferenz-API. Es gibt keinen Endpunkt, gegen den
sich ein Foto schicken ließe.

**Textmodelle.** Der Anbieter ist gleichgültig, das Modell nicht: `gpt-4o` sieht,
`deepseek-chat` nicht. Der Verbindungstest fragt nur die Modellliste ab und meldet
deshalb „Verbindung steht", auch wenn das eingetragene Modell blind ist — das
zeigt sich erst beim ersten Foto als 400er.

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

## Auswahl

Für Portionsschätzung aus einem Foto zählt genau eine Disziplin, und dort fallen
kleine Modelle ab. Ein lokales 7B-VLM erkennt „Teller mit Nudeln", schätzt die
Menge aber schlecht. Claude oder GPT liegen realistisch ±30 % daneben, kleine
lokale Modelle deutlich mehr. Deshalb der Bestätigungsschritt vor dem Speichern —
und deshalb ist der Anbieter in den Einstellungen umschaltbar statt fest.
