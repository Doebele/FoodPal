# FoodPal

Kalorien und Koffein für ein einziges iPhone. Mahlzeiten werden fotografiert
oder diktiert und von einem Modell geschätzt, Kaffee kostet zwei Taps, alles
landet in Apple Health. Kein Backend, keine Konten, kein Server — die
Schlüssel liegen in der Keychain und verlassen das Gerät nur als Kopfzeile
der Anfrage an den gewählten Anbieter.

SwiftUI · SwiftData · HealthKit · iOS 17 · rund 6 000 Zeilen · 75 Tests

> **Der Name ist vergeben.** „FoodPal" gibt es im App Store bereits dreimal,
> einmal davon als deutschsprachige Ernährungs-App in derselben Kategorie.
> Vor einer Veröffentlichung braucht die App einen anderen — 75 geprüfte
> Kandidaten stehen in der Namensakte.

---

## Der Entwurf

Swiss/Rams, und die verbindende Systematik ist ein **Punktraster**. Es trägt
den Tagesverlauf, die grosse Ziffernanzeige, die Röstungsfelder, die Auswahl
für Hell/Dunkel und die Piktogramme über den Erfassungsschirmen. Off-White
Papier, Fast-Schwarz, **ein** Akzent — und der gehört ausschliesslich dem
Koffein, wählbar als Röstung von Zimt bis Italienisch.

- **Ein Screen.** Erfassen und Einstellungen kommen als Bottom Sheet von
  unten, erledigen eine Sache und verschwinden. Keine Tabbar.
- **Der Tag ist eine Zeile.** 24 Stunden in 96 Rasterspalten, eine
  Viertelstunde je Spalte, oben Kalorien, unten Koffein, eine Kerbe für jetzt.
- **Drei Ziffernstile**, in den Einstellungen wählbar: Flipkarte nach der
  Braun-Klappuhr, Sieben-Segment, Dot-Matrix im Raster des Zeitstrahls.
  Das Zählwerk dreht alle Räder gleichzeitig und immer aufwärts.
- **Schrift: Fira** — Sans, Sans Condensed und Mono, mitgeliefert (SIL OFL).
- **Nur Hochformat.** Der ganze Entwurf hängt an einer Spalte.

Die Begründungen zu jeder dieser Entscheidungen — samt der Fehler, die dabei
auffielen — stehen in **[docs/design-entscheidungen.md](docs/design-entscheidungen.md)**.

## Was sie kann

| | |
|---|---|
| **Foto** | Kamera oder Fotomediathek, Schätzung durch ein Vision-Modell |
| **Beschreiben** | Tippen oder Diktieren; „gestern Abend um neun" wird als Zeitpunkt gelesen, mehrere Gerichte werden einzeln erfasst |
| **Barcode** | wird im Foto automatisch erkannt, Nährwerte von Open Food Facts |
| **Kaffee** | 14 Sorten, ein Tap; die häufigsten stehen unten, im Daumenbereich |
| **Koffein** | auch aus Mahlzeiten — Cola, Red Bull, Monster, Tee; Werte aus belegten Quellen, nicht vom Modell geraten |
| **Health** | Kalorien, Koffein und Makros als `HKCorrelation`; Löschen räumt dort mit auf |
| **Kalender** | Tage mit Einträgen sind markiert |

Zeitpunkte rasten auf **Viertelstunden**, abgerundet: 9:00 bis 9:14 landen
auf 9:00.

## Zwölf Wege zur Schätzung

Apple Intelligence auf dem Gerät, neun gehostete Dienste (Claude, OpenAI,
OpenRouter, Gemini, Grok, GLM, DeepSeek, Muse, Mistral) und zwei selbst
betriebene (LM Studio, Ollama) plus ein freies Feld. Dahinter stecken nur
**zwei** Anfrageformen — Anthropic Messages und OpenAI Chat Completions —,
alles andere ist eine andere Adresse und ein anderer Modellname.

Einzelheiten, Kosten und Einrichtung: **[docs/anbieter.md](docs/anbieter.md)**.

## Bauen

```bash
xcodebuild -project FoodPal/FoodPal.xcodeproj -scheme FoodPal \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

Signiert wird mit einem kostenlosen Personal Team. Dessen Profile laufen
**nach sieben Tagen ab**; die App startet dann nicht mehr und muss neu
aufgespielt werden. Die Daten überleben das.

Zum Ansehen ohne Xcode gibt es Startvarianten über Umgebungsvariablen —
`START_SHEET`, `START_SETTINGS`, `START_DESCRIBE`, `START_MEAL`,
`START_ENTRY`, `START_VISION` — jeweils `=1`, nur in Debug-Builds.

## Übersetzungen gegenlesen

Deutsch ist die Quellsprache; übersetzt sind Englisch, Französisch,
Italienisch und Spanisch. Der String-Katalog
`FoodPal/FoodPal/Localizable.xcstrings` ist das Original, zum Gegenlesen gibt
es eine Tabelle:

```bash
python3 tools/uebersetzungen.py export          # -> docs/uebersetzungen.csv
python3 tools/uebersetzungen.py import datei.csv
```

Komma-getrennt und UTF-8 mit BOM — genau die Form, die Google Sheets beim
Herunterladen ausgibt, sodass eine gegengelesene Tabelle ohne Umformatieren
zurückläuft. Der Import erkennt das Trennzeichen selbst. Er schreibt nur
Werte zurück und legt keine Schlüssel an: was in der Tabelle steht und im
Katalog fehlt, ist ein Tippfehler, keine neue Zeile.

Die Übersetzungen für FR, IT und ES stammen nicht von Muttersprachlern und
sollten vor einer Veröffentlichung gegengelesen werden.

## Vor einem App Store

- anderer Name (siehe oben)
- Muttersprachler für FR, IT, ES
- Datenschutzerklärung und App-Privacy-Angaben
- bezahltes Developer-Programm statt Personal Team

## Lizenzen

Der Code gehört mir. Mitgeliefert sind **Fira Sans**, **Fira Sans Condensed**
und **Fira Mono** unter der SIL Open Font License 1.1. Nährwerte für
Fertigprodukte kommen von **Open Food Facts** (ODbL).
