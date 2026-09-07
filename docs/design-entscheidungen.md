# FoodPal — Kalorien- & Kaffee-Tracking mit HealthKit-Sync

## Context

Persönliche iOS-App, nur für das eigene iPhone (Personal Team, kein App Store). Sie soll zwei Dinge schnell machen: Mahlzeiten per Foto erfassen (Kalorienschätzung durch ein Vision-LLM) und Kaffee in zwei Taps loggen. Alles landet in Apple Health, alles läuft lokal auf dem Gerät, kein Backend.

Das Projektverzeichnis ist leer — Greenfield. Gebaut wird in Phasen, beginnend mit einem Walking Skeleton, das genau eine Frage beantwortet: **schreibt die App auf einem kostenlosen Personal Team überhaupt nach HealthKit?** Erst wenn das auf dem echten Gerät steht, kommen UI und Foto-Erkennung.

Entschieden (aus den Rückfragen): Kalorien **plus** Makros (Protein/KH/Fett), Vision Framework entfällt (das LLM leistet die Bilderkennung vollständig), Projekt legst du selbst einmal in Xcode an, und die Schätzung soll gegen **drei** Backends laufen können — Claude, OpenAI und ein lokales Modell via LM Studio.

---

## Voraussetzungen (blockierend)

**Xcode fehlt.** `xcode-select -p` zeigt auf `/Library/Developer/CommandLineTools` — kein iOS-SDK, kein Simulator, keine Signierung. Aus dem App Store installieren (~10 GB), einmal öffnen, dann:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

Danach legst du das Projekt einmal an: **File → New → Project → iOS App**, Interface SwiftUI, Storage **SwiftData**, Name `FoodPal`, Bundle ID z.B. `com.clausmedvesek.foodpal`, Minimum Deployment **iOS 17.0**. Unter *Signing & Capabilities* dein Apple-ID-Team (Personal Team) wählen und **HealthKit** als Capability hinzufügen.

Xcode 16+ legt das Target mit synchronisierten Ordnerreferenzen an — alle `.swift`-Dateien, die ich danach in den Ordner schreibe, werden automatisch kompiliert. Kein pbxproj-Editieren, kein XcodeGen.

---

## Phase D — Entwürfe in Figma (zuerst)

Datei: [FoodPal](https://www.figma.com/design/lnnLbFFgY1nf4fA5c4ZB6X/FoodPal?node-id=0-1) — aktuell leer, eine Seite ohne Inhalt.

Der Dev-Mode-MCP-Server der Desktop-App ist nicht aktiv (Figma-Menü → Preferences → *Enable Dev Mode MCP Server*, danach Claude neu starten). Für das Anlegen der Frames brauche ich ihn nicht — der zweite Figma-Server hat Schreibzugriff auf die Datei. Aktivieren lohnt trotzdem, wenn ich später aus den fertigen Frames Code ziehen soll.

**Neun Frames, 393 × 852 (iPhone 16 Pro), drei Spalten à drei Screens:**

| | A · Anzeige | B · Datenblatt | C · Achse |
|---|---|---|---|
| Heute | Hero-Ziffer, ruhige Liste | Kennzahlenkopf, Lineatur | Zeitachse mit Ticks |
| Kaffee | Raster mit Rasterlinien | Preisliste, Zifferspalten | Liste an derselben Achse |
| Erfassung | \" | \" | \" |

Die Erfassung bekommt pro Richtung drei Zustände nebeneinander, weil dort die eigentliche Arbeit steckt: **Aufnahme** (Sucher, Auslöser, Verweis auf manuelle Eingabe) → **Analyse** (das Foto steht schon, dünne indeterminierte Linie an der Oberkante, kein Spinner) → **Bestätigung** (Name, kcal, drei Makrofelder, alle editierbar, Sichern). Dazu der Fehlerfall als vierter, kleiner Frame: eine Zeile Klartext, „Erneut versuchen", manuelle Eingabe bleibt erreichbar.

Aufbau in der Datei:
- **Figma-Variablen** für die Palette (`paper`, `ink`, `ink-2`, `rule`, `accent`) mit Light- und Dark-Mode, damit die Umschaltung ein Klick ist und die Werte 1:1 in die SwiftUI-Farben wandern
- **Text-Styles** entlang der iOS-Typoskala, alle Zahlen auf Tabellenziffern
- Abstände auf einem 4-pt-Raster, 24 pt Außenrand
- Ein Frame je Zustand, keine Komponenten-Bibliothek — für neun Screens wäre das mehr Pflege als Nutzen

Das läuft ohne Xcode. Installier Xcode parallel, dann steht der Simulator bereit, wenn die Entscheidung gefallen ist.

---

## Phase 0 — Walking Skeleton

Ziel: ein Screen, zwei Buttons, ein Statustext. Kein Design, keine Fotos.

1. `Entry` (SwiftData) + `HealthKitSync` schreiben.
2. Wegwerf-`ContentView`: Button „Test-Mahlzeit (500 kcal)", Button „Test-Espresso (2 kcal / 63 mg)", darunter der HealthKit-Autorisierungsstatus.
3. Beide Buttons speichern nach SwiftData **und** nach HealthKit.

**Verifikation — zwingend auf dem echten iPhone, nicht nur im Simulator.** Der Simulator braucht keine Provisionierung und beantwortet die Entitlement-Frage deshalb nicht. Auf dem Gerät: Berechtigungsdialog erscheint → in der Health-App unter *Durchsuchen → Ernährung* müssen „Nahrungsenergie" und „Koffein" mit den Testwerten stehen.

Erst wenn das grün ist, geht es weiter. Ich zeige dir Datenmodelle, HealthKit-Setup und Struktur an diesem Punkt.

---

## Datenmodell

`FoodPal/Entry.swift` — **ein** Model für beides, unterschieden durch `kind`. Die Tagesübersicht braucht ohnehin eine gemischte Chronologie; zwei Models würden zwei Queries und zwei Speicherpfade bedeuten.

```swift
@Model final class Entry {
    var date: Date
    var name: String
    var kindRaw: String        // "meal" | "coffee"
    var kcal: Double
    var caffeineMg: Double     // 0 bei Mahlzeiten
    var proteinG: Double?
    var carbsG: Double?
    var fatG: Double?
    var hkIDs: [UUID]          // gespeicherte HealthKit-Objekte, für sauberes Löschen
    @Attribute(.externalStorage) var photo: Data?
}
```

`hkIDs` ist kein Luxus: ohne die UUIDs bleiben beim Löschen eines Eintrags Leichen in Health zurück, die sich nur von Hand entfernen lassen.

**Kaffee-Presets** sind ein `static let`-Array von Structs in derselben Datei, kein persistiertes Model — feste Daten, die sich nie ändern. Espresso, Ristretto, Doppio, Cappuccino, Latte Macchiato, Flat White, Filterkaffee, Americano, Cold Brew; je mit kcal und Koffein pro Standardportion. Editierbar ist der **Eintrag** (bei Milch/Zucker), nicht das Preset.

```
// ponytail: Presets als statisches Array; ein @Model erst, wenn du eigene Getränke anlegen willst
```

---

## HealthKit

`FoodPal/HealthKitSync.swift` — eine Klasse, kein Protokoll, drei Methoden: `requestAuth()`, `save(Entry) -> [UUID]`, `delete([UUID])`.

Typen (write-only, `read: []`):

| Wert | Identifier | Einheit |
|---|---|---|
| Kalorien | `.dietaryEnergyConsumed` | kcal |
| Koffein | `.dietaryCaffeine` | mg |
| Protein | `.dietaryProtein` | g |
| Kohlenhydrate | `.dietaryCarbohydrates` | g |
| Fett | `.dietaryFatTotal` | g |

Die Samples werden als **`HKCorrelation` vom Typ `.food`** gespeichert, nicht als lose Einzelwerte — das ist der von der Plattform dafür vorgesehene Weg und die Health-App zeigt daraus einen benannten Eintrag mit aufklappbaren Nährwerten statt fünf zusammenhangloser Zeilen. Der Name wandert über `HKMetadataKeyFoodType` in die Metadaten.

Status für den „verbunden / nicht verbunden"-Screen: `authorizationStatus(for:)` liefert bei Share-Typen verlässlich `.sharingAuthorized` / `.sharingDenied` / `.notDetermined` (bei Read-Typen wäre das absichtlich blind).

Sync-Schalter: ein `@AppStorage("healthSyncEnabled")`. Bei „aus" wird lokal gespeichert und HealthKit übersprungen.

---

## Vision-Schätzung — drei Backends, zwei Request-Formen

`FoodPal/VisionEstimator.swift`

Der zentrale Punkt: **LM Studio spricht die OpenAI-API.** „OpenAI" und „lokal" sind derselbe Request-Body, nur mit anderer Base-URL, anderem Modellnamen und ohne echten Key. Es gibt also zwei Body-Formen, nicht drei — ein `switch` in einer Funktion, kein Protokoll mit drei Conformances.

```swift
enum Provider: String, CaseIterable { case claude, openAI, local }

struct MealEstimate: Codable {
    var name: String
    var kcal: Double
    var proteinG: Double?
    var carbsG: Double?
    var fatG: Double?
}

func estimate(image: Data, provider: Provider) async throws -> MealEstimate
```

**JSON-Rückgabe:** Prompt fordert reines JSON, geparst wird nachsichtig (Markdown-Fences strippen, erste `{` bis letzte `}`). Kein `response_format`/Tool-Schema pro Anbieter — lokale Modelle ignorieren das ohnehin häufig, und ein toleranter Parser deckt alle drei Fälle mit weniger Code ab.

```
// ponytail: ein nachsichtiger Parser statt drei Structured-Output-Konfigurationen
```

**Lokale Modelle:** In deinem LM Studio liegt mit `zai-org/glm-4.6v-flash` bereits ein Vision-Modell; `google/gemma-4-12b` ist der Alternativkandidat. Die Qwen-Modelle tragen kein `-VL` und dürften text-only sein. Verifikation ist ein Einzeiler: ein Testbild schicken — akzeptiert das Modell den `image_url`-Part, ist es multimodal, sonst kommt ein 400er.

Ein echtes On-Device-Modell auf dem iPhone habe ich verworfen: Apples Foundation-Models-Framework ist text-only, und ein VLM über MLX Swift zu bündeln heißt mehrere GB App-Größe und träge Inferenz — für eine persönliche App unverhältnismäßig. „Lokal" heißt hier: dein Mac rechnet, das iPhone fragt über WLAN.

**Damit das iPhone LM Studio erreicht:**
- In LM Studio: Server starten, *Serve on Local Network* aktivieren (bindet auf `0.0.0.0`, nicht nur `127.0.0.1`)
- Beide Geräte im selben WLAN; die Mac-IP wird in den App-Einstellungen hinterlegt
- Info.plist: `NSAppTransportSecurity` → `NSAllowsLocalNetworking: true` (erlaubt HTTP nur im lokalen Netz, statt ATS global abzuschalten) und `NSLocalNetworkUsageDescription`
- Praktische Grenze: funktioniert nur zu Hause. Deshalb ist der Provider pro Schätzung umschaltbar, nicht global fest.

**API-Keys** liegen in der Keychain — `FoodPal/Keychain.swift`, rund 25 Zeilen über `SecItemAdd`/`SecItemCopyMatching`/`SecItemDelete`, keine Abhängigkeit. UserDefaults kommt für Zugangsdaten nicht in Frage.

---

## UI — Swiss / Rams

**Entschieden an den Entwürfen (Phase D abgeschlossen):** A als Gerüst, C als Informationsschicht, B verworfen.

### Festgelegte Details

**Schrift.** Fließtext SF Pro. Alle Zahlen — Uhrzeiten, kcal, mg, Gramm — in **Fira Mono**. Die Flip-Ziffern ebenfalls Fira Mono.

**Tages-Matrix.** 24 Stundenspalten à 13 pt (3 Punkte zu 3 pt, 2 pt Abstand), 2 pt zwischen den Stunden. Je Spalte 13 Reihen à 3 pt mit 2 pt Abstand:

| Band | Reihen | Skala | Punktwert |
|---|---|---|---|
| Kalorien (oben) | 10 | 200 kcal je Reihe, bis 2000 | 66,7 kcal |
| Koffein (unten) | 3 | 100 mg je Reihe, bis 300 | 33,3 mg |

Unbeleuchtete Punkte in `Ink3`. In Figma existiert das als Komponente `Hour` (13 × 65) und `Day` (24 Instanzen) — bei der Umsetzung als ein `Canvas`- oder `Grid`-View nachbauen, nicht als 936 einzelne Views.

**Kalorienanzeige — drei Darstellungen, in den Einstellungen wählbar.**

1. **Flip** — vier Karten 80 × 112, geteilt bei y = 55 mit 2 pt Fuge, Achsnocken (2 × 10, Radius 2) bei x = 7 und x = 72. Helle Karte, dunkle Ziffer.
2. **7-Segment** — abgeschrägte Segmentenden, unbeleuchtete Segmente in `Ink3` sichtbar.
3. **Dot-Matrix** — die ganze Fläche ist ein durchgehendes Punktfeld im **Spaltenraster des Tagesdiagramms**: Dreiergruppen mit 2 pt Zwischenraum, also `x(c) = ⌊c/3⌋ · 15 + (c mod 3) · 5`, Punkt 3 pt. 72 Spalten, 25 Reihen, davon 2 Reihen Rand oben und unten.

Ziffern sind **proportional**, nicht monospaced, und ihre Breiten sind Vielfache von 3 — also einer Stundengruppe: `1` = 12 Spalten, `4` = 18, alle übrigen 15. Ziffernabstand 3 Spalten. Höhe 21 Reihen, **Strich 2,7 pt** (feine Fassung).

In Figma liegen die zehn Ziffern als Komponenten `Ziffer/0` … `Ziffer/9`; jede enthält alle Zellen, an wie aus. Feintuning heißt: einen Punkt anklicken und seine Füllung zwischen `ink` und `rule` umstellen — die Änderung wirkt in beiden Anzeigen. Die Anzeige selbst ist ein Hintergrundraster mit Instanzen darüber.

**Rechtsbündig gesetzt.** Nicht nur Konvention: so bleibt die Einerstelle beim Wechsel von 1849 auf 206 stehen, statt dass die ganze Zahl springt — für die Animation entscheidend.

**Konstruktion der Glyphen — gerade Strecken mit gerundeten Ecken, keine Ellipsen.** Das ist die Machart klassischer Punktmatrix-Schriften: rechteckige Innenräume, flache Ober- und Unterkanten, gerade Flanken. Grundformen sind das gerundete Rechteck (`0`, `8`, obere Schale der `9`, untere der `6`) und die rechts offene Schale (`3`, `5`); `1`, `4` und `7` sind reine Strecken. Ein erster Versuch mit reinen Ellipsenbögen war zu rund und blasig und traf den Charakter nicht.

Gerastert wird über **Abstand zur Polylinie**: eine Zelle leuchtet, wenn ihr Mittelpunkt näher als der halbe Strich an einer Skelettlinie liegt; Bögen werden vorher als Polylinie abgetastet. Der Weg über Ellipsenabstand und Winkelbereiche erzeugt entstellte 8, 4 und 9 — ausprobiert und verworfen.

Zur Laufzeit wird nicht gerastert: die Zellmengen einmal erzeugen und als Tabelle ablegen.

Zwischen Diagramm und Anzeige trennt eine **gepunktete Linie** — ein Punkt je Stundengruppe, 24 Stück, in `ink-2`.

### Skalierung über Bildschirmgrößen

Die Frage „kommen Segmente hinzu oder fallen weg?" beantwortet sich aus der Fixierung des Diagramms: ein Tag hat immer 24 Stunden, also hat das Raster **immer 72 Spalten**. Die Spaltenzahl ist damit gesetzt, und die Teilung ergibt sich aus der verfügbaren Breite:

```
pitch = verfügbareBreite / 71,6      // 358 pt natürliche Breite bei Teilung 5
```

| Gerät | Breite (ohne Rand) | Teilung | Punkt | Ziffernhöhe |
|---|---|---|---|---|
| iPhone SE | 272 pt | 3,80 | 2,28 | 80 pt |
| iPhone 16 | 345 pt | 4,82 | 2,89 | 101 pt |
| 16 Pro Max | 382 pt | 5,34 | 3,20 | 112 pt |

**Die eine Regel, an der alles hängt: dieselbe Teilung für beide Achsen.** Gestaucht wird nur, wenn Breite und Höhe unabhängig eingepasst werden. Wird die Teilung einmal aus der Breite berechnet und dann auch für die Reihen benutzt, bleiben die Punkte quadratisch und das Verhältnis unverändert — Quetschen ist dann gar nicht möglich. Kein `scaledToFill`, kein unabhängiges `frame(width:height:)` auf dem Feld.

Was mit der Bildschirmhöhe flext, sind folglich die **Reihen**, nicht deren Proportion: die Glyphen bleiben 21 Reihen hoch, das Feld bekommt mehr oder weniger Randreihen. Reihen kommen und gehen, Spalten nie.

Darunter ein Umschalter kcal / mg; im mg-Modus stehen die Ziffern im Akzent.

**Das Punktraster ist die verbindende Systematik der App**, nicht nur eine Diagrammform. Es trägt bereits das Tagesdiagramm, die Ziffernanzeige und die Röstungsfelder (je 10 × 7 Zellen, 1 Zelle Abstand). Piktogramme im selben Raster sind der nächste denkbare Schritt — bei 24 pt Kantenlänge stehen dafür nur 5 × 5 Zellen zur Verfügung, das ist für Kamera oder Tasse zu grob. Sinnvoll wäre es erst ab etwa 40 pt, also für großformatige Zustandsbilder, nicht für die Tabbar.

**Die Auswahl in den Einstellungen zeigt die echte Darstellung** — eine Flipkarte mit Fuge und Achsnocken, eine Sieben-Segment-Acht, eine Punktmatrix-Acht — kein Text-Etikett. Man wählt, was man sieht.

### Animation der Ziffernwechsel

Gemeinsam: ein `enum NumberStyle` in `@AppStorage`, ein `switch` im Elternview. Kein Protokoll — drei konkrete Views, kein Erweiterungspunkt. Bei `UIAccessibility.isReduceMotionEnabled` alle drei auf einfache Überblendung zurückfallen.

**Flip — der aufwendigste, aber der einzige mit Haptik.**

Ein Klappschritt in zwei Hälften:
1. Die obere statische Hälfte zeigt sofort die **neue** Ziffer.
2. Ein Blatt mit der **alten** oberen Hälfte dreht von 0° auf −90°, `rotation3DEffect(axis: (1,0,0), anchor: .bottom, perspective: 0.6)`, ~90 ms.
3. Ab 90° dreht ein zweites Blatt mit der **neuen** unteren Hälfte von +90° auf 0°, Anker `.top`, ~90 ms.
4. Die untere statische Hälfte wechselt beim Aufsetzen.

`PhaseAnimator` (iOS 17+) bildet die zwei Phasen sauber ab. Ziffern laufen **von rechts nach links** mit 45 ms Versatz, wie der Übertrag in einem mechanischen Zählwerk.

Durchblättern: echtes Zählwerk rollt 3→4→5→6→7. Pro Ziffer auf **höchstens sechs Schritte** deckeln, darüber direkt auf den Zielwert klappen — sonst rollt die Einerstelle bei 1849 → 2469 sechshundertmal.

Haptik, und hier liegt die Falle: `UIFeedbackGenerator` fasst Ereignisse unter ~50 ms zusammen. Vier Ziffern à Klappe ergäben Matsch statt Rhythmus. Deshalb **ein Impuls je Klappwelle**, ausgelöst vom führenden Blatt, nicht je Ziffer:

```swift
.sensoryFeedback(.impact(weight: .light, intensity: 0.6), trigger: flapWave)
```

Für die wirklich analoge Fassung ein `CHHapticEngine`-Pattern mit transienten Ereignissen exakt auf den Aufsetzzeitpunkten — dann lässt sich die Intensität je Stelle staffeln. Rund 40 Zeilen, lohnt sich nur, wenn die einfache Variante zu grob wirkt.

**7-Segment — reine Überblendung, keine Haptik.**

Je Segment die Farbe animieren, mit kleinem Versatz je Segmentindex, damit die Ziffer *aufklart* statt umzuspringen:

```swift
.animation(.easeInOut(duration: 0.16).delay(Double(i) * 0.012), value: digit)
```

Ein Detail mit echter Wirkung: Segmente, die **ausgehen**, langsamer blenden (0,22 s) als solche, die **angehen** (0,12 s). Das ist das Nachleuchten echter LCDs.

**Dot-Matrix — diagonaler Durchlauf.**

Verzögerung je Punkt aus seiner Position: `delay = (row + col) * 0.015`. Angehende Punkte zusätzlich von `scale 0.85` auf `1.0`. Ergibt den Eindruck einer Anzeigetafel, die durchläuft.

Der Gewinn dieser Variante: das Tagesdiagramm darüber benutzt dasselbe Punktraster. Ein neuer Eintrag kann seine Diagrammpunkte mit **derselben** Bewegung aufleuchten lassen — eine Bewegungssprache für Anzeige und Diagramm. Haptik: ein einzelner leichter Impuls, wenn der Wert steht, nicht je Punkt.

**Piktogramme nach Otl Aicher.** Massive Flächen, runde Endkappen, nur 0° / 45° / 90°. Durchgehend **Strichstärke 2,4** und **Radius 1,2** auf 24er-Raster (Radius = halbe Strichstärke, also identisch mit dem Kappenradius). Fünf Glyphen: Start, Erfassen, Kaffee, Profil, Einstellungen. Die Tabbar führt vier davon — Profil hat in einer Ein-Personen-App keinen Inhalt.

**Akzent = Röstung.** Sechs wählbare Töne als Figma-Variablen `roast/*`, je mit Light-/Dark-Wert:

| | Light | Dark |
|---|---|---|
| Zimt | `#C9793A` | `#E3A876` |
| Hell (Vorgabe) | `#B4531F` | `#E08A4E` |
| Mittel | `#9A4A22` | `#CE7B45` |
| Wien | `#7A3A1B` | `#BC6D3C` |
| Französisch | `#5A2A14` | `#A75E33` |
| Italienisch | `#3D1C0E` | `#91502B` |

In SwiftUI ein `enum Roast` mit `@AppStorage` und je einem Farbpaar. Der Akzent bleibt dem Koffein vorbehalten; alles Antippbare ist Ink in Medium.

Drei Tabs: **Start · Erfassen · Einstellungen**.

### Erfassung folgt dem Modus

Der kcal/mg-Umschalter unter der Anzeige setzt einen Modus, der **erhalten bleibt**. Er bestimmt, womit die Erfassung öffnet:

| Modus | Erfassen öffnet |
|---|---|
| kcal | Kamera / Foto |
| mg | Getränkeauswahl |

Auf dem Erfassungs-Screen steht derselbe Umschalter unten statt einer Tabbar; er wechselt zwischen Sucher und Getränkeauswahl. Damit entfällt der Kaffee-Tab — er wäre eine zweite Tür zum selben Raum.

Der Preis, bewusst angenommen: Kaffee kostet zwei Taps, solange der Modus auf mg steht, und drei, wenn er auf kcal steht. Bei überwiegender Kaffee-Erfassung steht er praktisch immer auf mg.

### Getränkeauswahl

**14 Sorten**, zweispaltig. Sortiert nach zuletzt gehäufter Nutzung — aber **die häufigsten stehen unten**, entgegen der Leserichtung: dort liegt der Daumen bei einhändiger Bedienung. Koffein je Sorte als Punktbalken im feinen Raster (12 Punkte, rund 13 mg je Punkt), Kalorien als Zahl rechts.

Gestaltungsregeln, die ich durchhalte:

- **Typografie trägt alles.** SF Pro, eine Gewichtsrampe, keine dekorativen Schnitte. Alle Zahlen `.monospacedDigit()`, damit Summen beim Aktualisieren nicht springen.
- **Keine Karten, keine Schatten, keine abgerundeten Kacheln auf grauem Grund.** Inhalt steht direkt auf der Fläche, getrennt durch Haarlinien und Weißraum.
- **Nahezu farblos.** Fast-Schwarz auf Off-White, ein einziger Akzent, reserviert für den Koffeinwert. Semantische Farben, damit Dark Mode korrekt kippt.
- **Strenges Raster.** 24 pt Außenränder, linksbündig, feste vertikale Rhythmik.
- **Die Tagessumme ist der Held**: sehr groß, sehr leicht gesetzt, wie eine Braun-Anzeige. Darunter die Chronologie in ruhigen Zeilen.

`TodayView` — Tagessumme kcal, darunter Koffein, darunter die chronologische Liste. Leerzustand: **ein** Satz, keine Illustration, kein Onboarding-Button.

### Tageswechsel durch Wischen

Kein Pfeilwerk in der Kopfzeile — zwischen den Tagen wird gewischt. Der Datumsbereich ist endlich (erster Eintrag bis heute), also reicht ein pagender `ScrollView` mit `LazyHStack`:

```swift
ScrollView(.horizontal) {
    LazyHStack(spacing: 0) {
        ForEach(days, id: \.self) { day in
            DayView(date: day)
                .containerRelativeFrame(.horizontal)
                .id(day)
        }
    }
    .scrollTargetLayout()
}
.scrollTargetBehavior(.paging)
.scrollPosition(id: $currentDay)
.scrollIndicators(.hidden)
```

Nach links über heute hinaus geht nichts — Gummiband statt leerer Zukunftstage. Rechts in der Kopfzeile erscheint eine stille Aktion **„Heute"**, aber nur wenn man nicht auf heute steht.

**Swipe-to-delete entfällt.** Es wäre dieselbe Geste in derselben Fläche wie der Tageswechsel; iOS lässt dann die Zeilengeste gewinnen und Wischen funktionierte nur oberhalb der Liste. Stattdessen: Zeile antippen öffnet `EntryDetailView` — Werte editierbar, unten „Eintrag löschen" mit Nachfrage. Löschen entfernt auch die HealthKit-Objekte über die gespeicherten `hkIDs`.

**Fallstrick bei der Ziffernanimation:** beim Wischen darf die Anzeige nicht umklappen. Die Animation gehört an Wertänderungen des laufenden Tages, nicht ans Blättern — also am Wert *für ein Datum* aufhängen, nicht daran, dass sich die dargestellte Zahl geändert hat. Sonst rattert bei jedem Wisch die ganze Anzeige durch.

`CoffeeView` — Raster der Presets. Tippen speichert **sofort** mit Standardportion; darunter erscheint kurz eine schmale Bestätigungszeile mit „Bearbeiten", die von selbst verschwindet. Das ist ein Tap statt zwei — so entschieden. Langes Drücken öffnet direkt das Mengen-/Korrektur-Sheet. Beim Speichern ein leichtes `.sensoryFeedback(.success, …)`, damit die stumme Aktion spürbar quittiert wird.

`AddMealView` — `PhotosPicker` oder Kamera → Analyse → Bestätigungs-Sheet mit Name, kcal und drei Makrofeldern, alle editierbar, dann sichern. Manuelle Eingabe ohne Foto ist derselbe Screen, nur leer.
Ladezustand während der Analyse: kein Spinner in einer Box, sondern das Foto steht bereits da und trägt eine dünne indeterminierte Fortschrittslinie an der Oberkante. Fehlerfall: eine Zeile Klartext plus „Erneut versuchen", und die manuelle Eingabe bleibt jederzeit erreichbar.

`SettingsView` — HealthKit-Status und Sync-Schalter, Provider-Auswahl, Keyfelder, LM-Studio-URL mit Verbindungstest.

`PhotosPicker` läuft außerhalb des App-Prozesses und braucht **keine** Fotoberechtigung — es bleibt nur `NSCameraUsageDescription`.

---

## Dateien

```
FoodPal/
  FoodPalApp.swift          @main, .modelContainer
  Entry.swift               @Model, Kind, CoffeePreset-Array
  HealthKitSync.swift       Auth, save, delete
  Keychain.swift            ~25 Zeilen
  VisionEstimator.swift     Provider, estimate(), JSON-Parser
  DesignSystem.swift        Abstände + Typo-Konstanten, ~25 Zeilen
  Views/TodayView.swift
  Views/CoffeeView.swift
  Views/AddMealView.swift
  Views/SettingsView.swift
FoodPalTests/
  EstimateParsingTests.swift
```

Info.plist: `NSHealthUpdateUsageDescription`, `NSCameraUsageDescription`, `NSLocalNetworkUsageDescription`, `NSAppTransportSecurity`.

---

## Reihenfolge

| Phase | Inhalt | Abnahme |
|---|---|---|
| D | Neun Frames in Figma: A/B/C × Heute, Kaffee, Erfassung | du wählst eine Richtung |
| 0 | Skeleton: Model + HealthKit + zwei Buttons | Werte stehen in der Health-App **auf dem iPhone** |
| 1 | Struktur & Modelle im Detail vorstellen | dein Go |
| 2 | UI in der gewählten Richtung, manuell voll bedienbar | Simulator-Screenshots gegen die Frames |
| 3 | Foto-Analyse, drei Provider, Keychain | echtes Essensfoto, alle drei Backends |
| 4 | Feinschliff: Leer-/Lade-/Fehlerzustände, Dark Mode | — |

Phase D braucht kein Xcode — die Installation kann nebenher laufen.

---

## Verifikation

- **Phase 0** nur auf dem Gerät: Berechtigungsdialog → Testwerte → Health-App unter *Ernährung* prüfen. Dann einen Eintrag in der App löschen und kontrollieren, dass er auch in Health verschwindet.
- **UI-Phasen** treibe ich selbst im Simulator (Screenshots, Taps über die Simulator-Tools) — du musst nicht selbst klicken, um zu sehen, wo es steht.
- **Parser**: `EstimateParsingTests.swift` mit einer Handvoll realistischer Antwortformen — bare JSON, in ```json-Fences gewickelt, mit vorangestelltem Fließtext, mit fehlenden Makrofeldern. Das ist der eine Test, der hier fällig ist; der Rest der App ist zu dünn für Tests.
- **Provider**: dasselbe Foto durch alle drei schicken und die Schätzungen nebeneinanderlegen — das beantwortet gleich, ob das lokale Modell für dich brauchbar ist.

---

## Risiken

1. ~~**HealthKit auf Personal Team.**~~ **Erledigt am 7.9.2026 — funktioniert.** Apple stellt dem kostenlosen Personal Team ein Profil mit `com.apple.developer.healthkit` aus; die signierte App trägt die Berechtigung, Schreiben und Löschen laufen auf dem Gerät. Das Profil enthält sogar `healthkit.background-delivery`, die wir nicht anfordern.

   **Fallstrick, der dabei auffiel:** `requestAuthorization` weist **Korrelationstypen ab** und beendet die App mit `NSInvalidArgumentException — Authorization to share the following types is disallowed: HKCorrelationTypeIdentifierFood`. Angefragt werden dürfen nur die Einzelwerte. Die `HKCorrelation` lässt sich trotzdem speichern, solange ihre enthaltenen Werte freigegeben sind; gelöscht wird ebenfalls nur über die Einzelwerte.
2. **7-Tage-Ablauf.** Personal-Team-Profile laufen wöchentlich ab, die App startet dann nicht mehr und muss aus Xcode neu aufgespielt werden. Ohne bezahltes Konto nicht zu umgehen. Die SwiftData-Daten überleben das.
3. **Schätzgenauigkeit.** Kalorien aus einem Foto liegen realistisch ±30 % daneben — die Portionsgröße ist aus einem Bild schlicht nicht sicher ableitbar. Deshalb der Bestätigungsschritt vor jedem Speichern.
4. **Lokales Modell schwächer.** Portionsschätzung ist genau die Disziplin, in der kleine VLMs gegen Claude/GPT abfallen. Der Vergleich in Phase 3 zeigt, ob es für dich reicht.

---

## Bewusst weggelassen

- **Vision Framework** — das LLM macht die Bilderkennung komplett. Der eine sinnvolle Einsatz wäre Barcode-Scan für Fertigprodukte (`VNDetectBarcodesRequest` + Open Food Facts); das ist ein eigenes Feature mit eigener Datenquelle, vorgemerkt für später.
- **Rücklesen aus HealthKit** — die Tagessumme zeigt nur, was du in dieser App erfasst hast. Nötig, sobald eine zweite App Ernährungsdaten schreibt.
- **Nachträglicher Sync** von Einträgen, die bei ausgeschaltetem Sync entstanden sind.
- **Bearbeitbare Preset-Bibliothek**, Zielwerte/Tagesbudget, Wochen- und Verlaufsstatistiken, Widgets, iCloud-Sync (mit Personal Team ohnehin gesperrt).
