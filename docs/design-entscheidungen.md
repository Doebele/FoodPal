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

**Tages-Matrix.** 24 Stunden zu je **vier** Punkten Breite — eine Viertelstunde
je Spalte, 96 Spalten. Punkt 3 pt, Lücke 1 pt, **gleichmässige Teilung 4 pt**;
die frühere breitere Lücke zwischen den Stunden ist weg. Natürliche Breite
`96 · 4 − 1 = 383 pt`.

| Band | Reihen | Skala | Punktwert |
|---|---|---|---|
| Kalorien (oben) | 12 | 150 kcal je Reihe, bis 1800 je Stunde | 37,5 kcal |
| Koffein (unten) | 5 | 65 mg je Reihe, bis 325 je Stunde | 16,25 mg |

Zwischen den Bändern eine Reihe Fuge (4 pt), natürliche Gesamthöhe 70 pt.

**Die Koffein-Skala hat einen Anker: eine Reihe ist ungefähr ein Espresso**
(63 mg). Drei Espresso in einer Stunde füllen damit knapp drei Reihen. Bei den
früheren 100 mg je Reihe waren es kaum zwei — die Skala sagte nichts, was man
im Kopf nachrechnen konnte.

Unbeleuchtete Punkte in `rule`, nicht mehr in `ink3`: bei 1632 Punkten ist der
hellere Ton der Unterschied zwischen Raster und Rauschen.

**Der Zeitstrahl läuft aus dem Seitenrand heraus** bis 5 pt an den
Bildschirmrand. Das ist keine Kosmetik: beim Wischen von Tag zu Tag geht die
Rasterfläche dadurch nahezu fliessend ineinander über, statt an einer Kante
abzubrechen. Ganz bis zur Kante wäre falsch — das sähe nach Beschnitt aus statt
nach Absicht.

**Stundenmarken: nur noch 02, 08, 14, 20.** Vier statt sechs. Ein Tag hat vier
Sechserblöcke, und die Zahl steht am Anfang des zweiten davon. Mehr Marken waren
Lärm über einem Raster, das den Verlauf ohnehin zeigt.

**Die gepunktete Trennlinie zwischen Diagramm und Anzeige entfällt.** Sie sass
im alten Raster mit einem Punkt je Stundengruppe; im neuen wäre sie eine zweite,
gröber gerasterte Reihe direkt unter dem Zeitstrahl gewesen. Weissraum trennt
genauso gut.

**Kalorienanzeige — drei Darstellungen, in den Einstellungen wählbar.**

1. **Flip** — vier Karten 80 × 112, geteilt bei y = 55 mit 2 pt Fuge, Achsnocken (2 × 10, Radius 2) bei x = 7 und x = 72. Helle Karte, dunkle Ziffer.
2. **7-Segment** — abgeschrägte Segmentenden, unbeleuchtete Segmente in `Ink3` sichtbar.
3. **Dot-Matrix** — die ganze Fläche ist ein durchgehendes Punktfeld im **Spaltenraster des Tagesdiagramms**: gleichmässige Teilung, also `x(c) = c · 4`, Punkt 3 pt, 96 Spalten × 33 Reihen.

   Jede Ziffer ist **20 Spalten breit**, alle gleich — die Anzeige rastert wie ein Zählwerk, nicht wie ein Schriftsatz. Zwischen den Ziffern steht je eine **Trennspalte**; ohne sie stossen zwei Ziffern mit ihren leeren Randspalten aneinander und eine 11 sähe aus wie ein breiter Balken. Die Ziffern stehen **rechtsbündig**, links wird mit leeren Rasterspalten aufgefüllt:

   ```
   11 Füller │ 20 Ziffer │ 1 │ 20 │ 1 │ 20 │ 1 │ 20 │ 2  =  96
   ```

   Rechts bleiben zwei Spalten stehen, damit die Einerstelle nicht an der Kante klebt — mit der leeren Randspalte der Ziffer selbst sind es drei.

   **Senkrecht mittig.** Die Vorlage hat oben eine und unten sechs leere Reihen; übernähme man den Kasten unbesehen, sässen die Ziffern sichtbar zu hoch. Gezeichnet werden deshalb nur die Reihen mit Punkten, mit je drei Rasterreihen darüber und darunter. `DotMatrixFont.inkRows` rechnet den Bereich aus den Daten aus, statt ihn einzutragen — beim nächsten Entwurf stimmt es dann von selbst.

   **Der Abstand zum Zeitstrahl ist eine Rasterreihe**, derselbe wie zwischen Koffein- und Kalorienband. Damit lesen sich Diagramm und Anzeige als ein durchgehendes Feld, was sie ja auch sind.

   Damit läuft die Anzeige **genauso randlos wie der Zeitstrahl** — es ist dasselbe Raster, nur mit anderen Punkten beleuchtet. Flip und 7-Segment bleiben dagegen im Satzspiegel: sie sind Schrift auf einer Fläche.

   Die Glyphen stehen als Lauflängen in `DotMatrixFont.swift`, übertragen aus Figma (Node `101:253908`). Vier Tests prüfen die Unversehrtheit der Tabelle — bei übertragenen Daten fände sich ein Kopierfehler sonst erst am Bildschirm.

   Vier Räder heissen vier Stellen: über 9999 zeigt das Zählwerk 9999.

Ziffern sind **proportional**, nicht monospaced, und ihre Breiten sind Vielfache von 3 — also einer Stundengruppe: `1` = 12 Spalten, `4` = 18, alle übrigen 15. Ziffernabstand 3 Spalten. Höhe 21 Reihen, **Strich 2,7 pt** (feine Fassung).

In Figma liegen die zehn Ziffern als Komponenten `Ziffer/0` … `Ziffer/9`; jede enthält alle Zellen, an wie aus. Feintuning heißt: einen Punkt anklicken und seine Füllung zwischen `ink` und `rule` umstellen — die Änderung wirkt in beiden Anzeigen. Die Anzeige selbst ist ein Hintergrundraster mit Instanzen darüber.

**Ausrichtung.** Ursprünglich rechtsbündig, damit die Einerstelle beim Wechsel von 1849 auf 206 stehen bleibt statt dass die ganze Zahl springt. Seit `Digits.of` immer vier Stellen zeigt, springt ohnehin nichts mehr, und das Argument ist hinfällig: **Flip und 7-Segment stehen zentriert** — waagerecht auf derselben Achse wie der Umschalter darunter, senkrecht mit gleichem Abstand nach oben und unten (36 · 112 · 36). Die Dot-Matrix bleibt rechtsbündig: sie sitzt nicht im Satzspiegel, sondern im Raster des Zeitstrahls, und füllt links mit leeren Rasterspalten auf.

Dabei kam ein Layoutfehler heraus, der lange unbemerkt blieb: **die Flipkarte zeichnete 28 pt unter ihrem eigenen Rahmen.** Ihr `ZStack(alignment: .top)` enthält zwei Kartenhälften, die untere nur per `offset` platziert — und ein Offset lässt das Layout nicht mitwachsen. Der ZStack war damit eine halbe Karte hoch, und das umschließende `.frame(height: h)` zentrierte diese halbe Höhe: die ganze Karte rutschte um `h/4` nach unten. Sichtbar wurde es erst im Vergleich, weil 7-Segment korrekt sass und beide Stile deshalb 28 pt auseinanderlagen. `alignment: .top` auf demselben `frame` behebt es.

Die Abstände um die Anzeige waren an diesem Fehler ausgerichtet und stimmten nur für Flip. Sie stehen jetzt **je Stil in seinem eigenen Zweig** statt gemeinsam am Umschalter — die Dot-Matrix braucht mehr Luft nach unten als die Karten, und ein gemeinsamer Wert hätte den Umschalter bei einem der beiden verrückt.

**Konstruktion der Glyphen — gerade Strecken mit gerundeten Ecken, keine Ellipsen.** Das ist die Machart klassischer Punktmatrix-Schriften: rechteckige Innenräume, flache Ober- und Unterkanten, gerade Flanken. Grundformen sind das gerundete Rechteck (`0`, `8`, obere Schale der `9`, untere der `6`) und die rechts offene Schale (`3`, `5`); `1`, `4` und `7` sind reine Strecken. Ein erster Versuch mit reinen Ellipsenbögen war zu rund und blasig und traf den Charakter nicht.

Gerastert wird über **Abstand zur Polylinie**: eine Zelle leuchtet, wenn ihr Mittelpunkt näher als der halbe Strich an einer Skelettlinie liegt; Bögen werden vorher als Polylinie abgetastet. Der Weg über Ellipsenabstand und Winkelbereiche erzeugt entstellte 8, 4 und 9 — ausprobiert und verworfen.

Zur Laufzeit wird nicht gerastert: die Zellmengen einmal erzeugen und als Tabelle ablegen.

Zwischen Diagramm und Anzeige trennt eine **gepunktete Linie** — ein Punkt je Stundengruppe, 24 Stück, in `ink-2`.

### Skalierung über Bildschirmgrößen

Die Frage „kommen Segmente hinzu oder fallen weg?" beantwortet sich aus der Fixierung des Diagramms: ein Tag hat immer 24 Stunden, also hat das Raster **immer 96 Spalten**. Die Spaltenzahl ist damit gesetzt, und die Teilung ergibt sich aus der verfügbaren Breite:

```
pitch = verfügbareBreite / 95,75     // 383 pt natürliche Breite bei Teilung 4
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

**Alle Räder drehen gleichzeitig, und immer aufwärts.** Ein Zählwerk, das man von Hand hochdreht, rollt 3→4→5→6→7 — und es dreht alle Räder zugleich, nicht eines nach dem anderen. Wer weniger Weg vor sich hat, steht früher still; genau dieses ungleiche Auslaufen ist der Effekt. Von 0189 auf 0344 heisst das: die Hunderter sind nach zwei Klappen fertig, die Zehner brauchen sechs, und dazwischen dreht sich immer weniger, bis nur noch ein Rad läuft.

Das galt zuerst nur nach dem Nullen (Moduswechsel), ist aber die Regel für **jede** Wertänderung — auch nach dem Sichern eines Eintrags. Die Bewegung wird dadurch länger, und das ist beabsichtigt: sie zeigt, dass etwas dazugekommen ist, statt nur ein Ergebnis zu setzen.

Vorwärts zu zählen begrenzt die Sache von selbst: von 8 auf 1 sind es drei Schritte über 9 und 0, nie sieben rückwärts. **Keine Stelle braucht mehr als neun Klappen**, egal wie weit der Wert springt — bei rund 0,14 s je Klappe ist die längste Bewegung gut eine Sekunde. Solange die Stellen nacheinander liefen, addierten sich ihre Schritte und es brauchte eine Deckelung (vierzehn Klappen, darüber wurde gesetzt); gleichzeitig ist sie überflüssig und wieder draussen.

**Ein Vorlauf von 0,4 s vor dem Rollen.** Der Wert ändert sich in dem Moment, in dem gesichert wird — das Bottom Sheet fährt danach erst heraus und läge sonst über den ersten, informationsreichsten Klappen. Beim Moduswechsel entfällt der Vorlauf: dort ist nichts im Weg.

**`Task.sleep` mit `try?` allein reicht nicht.** Wird die Animation abgebrochen (zwei Einträge kurz hintereinander), schluckt `try?` den Abbruch und die Restschleife rattert ohne jede Pause durch. Deshalb prüft `pause(_:)` das Ergebnis und bricht ab.

Haptik, und hier liegt die Falle: `UIFeedbackGenerator` fasst Ereignisse unter ~50 ms zusammen. Vier Ziffern à Klappe ergäben Matsch statt Rhythmus. Deshalb **ein Impuls je Klappwelle**, nicht je Ziffer:

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

`SettingsView` — HealthKit-Status und Sync-Schalter, Provider-Auswahl, Keyfelder, LM-Studio-URL mit Verbindungstest, Ziffernstil, Röstung und **Haptik-Schalter**.

### Haptik

**Abschaltbar, aber voreingestellt an.** Wer sie nicht vorfindet, entdeckt sie nie; wer sie stört, findet den Schalter.

Alle Impulse laufen über **einen** Modifier, nicht über verstreute `.sensoryFeedback`-Aufrufe:

```swift
someView.haptic(trigger: counter)          // gestuft über Preference.haptics
```

Der Schalter greift damit überall, ohne dass jeder Screen ihn selbst abfragt. Voreinstellungen werden beim Start über `Preference.registerDefaults()` gesetzt.

**Wo Haptik hingehört:** dort, wo etwas *einrastet* — Kaffee gesichert, Eintrag gelöscht, Flipkarte aufgesetzt, Tag gewechselt. **Nicht** an jeden Tastendruck; sonst nutzt sie sich ab und wird zum Rauschen.

**Die Untergrenze der Taktung:** iOS fasst Haptik-Ereignisse unter rund 50 ms zusammen. Bei der Flip-Kaskade heißt das: unter etwa 110 ms je Stelle verschmelzen die Impulse zu einem Brummen. Nicht die Animation setzt hier das Limit, sondern die Haptik.

**Auch das Nullen ist spürbar.** Ursprünglich war der Wechsel kcal ↔ mg stumm: erst geräuschlos auf null, dann hörbar auf den neuen Wert. Umgekehrt entschieden — es ist eine echte Klappe, und was sich bewegt, soll sich auch anfühlen. Der Rücksetz-Schritt läuft mit 110 ms je Stelle, also genau auf der Grenze, an der die Impulse noch einzeln ankommen.

Was sich **nicht** meldet, ist eine Stelle, die schon steht: eine 0, die 0 bleibt, klappt nicht.

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

## Sprachen

**Deutsch ist die Quellsprache**, übersetzt sind **Englisch, Französisch, Italienisch, Spanisch**. Die Schlüssel im String-Katalog *sind* der deutsche Text; das hält die Vorlage im Quelltext lesbar.

**Kein eigener Sprachschalter in der App.** Sobald mehrere Sprachen im Bundle liegen, zeigt iOS unter *Einstellungen → FoodPal → Sprache* eine Auswahl je App — genau der Fall „deutsche App auf englischem Gerät". Ein eigener Schalter wäre schlechter: er könnte `Locale.current` nicht mitdrehen, und Datum, Uhrzeit und Monatsnamen liefen weiter der Gerätesprache nach. Genau diese Mischung gab es vorher zu sehen — deutsche Beschriftungen neben „8 Sep 2026 at 12:30".

**Die Modelle antworten in der App-Sprache**, nicht in der Sprache der Eingabe: `VisionEstimator.answerLanguage` steht im Prompt. Wer die App auf Italienisch stellt, will keine deutschen Gerichtsnamen in seiner Liste — beschreiben darf er trotzdem auf Deutsch, das verstehen die Modelle ohnehin.

Zwei Stolpersteine, die dabei auffielen und im Code stehen:

- **`Text(einString)` übersetzt nicht.** Nur `Text(einLiteral)` wird als `LocalizedStringKey` gelesen. Die Bausteine `row`, `caption`, `actionRow`, `field` und `SheetHeader` nahmen `String` — dadurch war die halbe Oberfläche nicht extrahierbar, ohne dass es irgendwo aufgefallen wäre. Erst nach der Umstellung auf `LocalizedStringKey` stieg die Zahl der Schlüssel von 89 auf 130.
- **Anzeigetexte gehören nicht in `rawValue`.** `HealthKitSync.Status` trug seine deutschen Wörter als Rohwert; damit hing die Übersetzung an der Datenhaltung. Jetzt ist der Rohwert ein Bezeichner und `label` die Anzeige.

Die Übersetzungen für FR, IT und ES stammen von mir und sollten vor einem App-Store-Start von Muttersprachlern gegengelesen werden.

## Barrierefreiheit

Drei Schritte, in dieser Reihenfolge — Trefferflächen und Kontrast zuerst, weil sie **jeden** betreffen und nichts am Entwurf kosten; Dynamic Type danach, weil es das Layout anfasst.

**Trefferflächen ≥ 44 × 44.** Das Zahnrad und die Tagespfeile waren kleiner als ihr Glyph vermuten liess. Die sichtbare Marke bleibt gleich gross; nur die `frame` darum wuchs.

**Kontrast.** `ink2` hell stand bei `#8A8A82` — 3,33 : 1 gegen `paper` und damit unter der WCAG-AA-Schwelle von 4,5 : 1 für Text unter 18 pt. Jetzt `#72726A`, gemessen 4,64 : 1. Dunkel lag mit 5,04 : 1 schon darüber und blieb unverändert.

**Dynamic Type über `scaledFont`, nicht `UIFontMetrics`.** Die App setzt Grössen fest (`13`, `17`, `82 · k`), weil der Entwurf auf ihnen steht. `UIFontMetrics` liest die Merkmale des *Bildschirms* und wäre deshalb taub gegen `.dynamicTypeSize()` — also gegen den Schalter in den Einstellungen. `scaledFont` nimmt stattdessen `\.dynamicTypeSize` aus der Umgebung und multipliziert mit Apples eigener Fliesstext-Staffelung (14 · 15 · 16 · **17** · 19 · 21 · 23, in den Bedienhilfen 28 · 33 · 40 · 47 · 53), normiert auf 17.

**Der Schalter „Schrift folgt dem System" ist voreingestellt an.** Aus nagelt die App auf `.large` fest, die Grösse, in der die Entwürfe gesetzt sind. Er ist für den Fall da, dass jemand die Systemschrift aus anderen Gründen gross stellt und in dieser einen App den Satz behalten will — nicht als Vorgabe.

Fest bleiben zwei Stellen, an denen Schrift Geometrie ist und keine Sprache: die Ziffer auf der Flipkarte (`82 · k`, sie füllt die Karte) und die Stundenmarken über dem Zeitstrahl (10 pt, sie sitzen auf Rasterspalten).

**Was bei 53 pt umbrechen musste.** Die Screenshots bei `accessibility-extra-extra-extra-large` zeigten vier Stellen, an denen der Satz nicht nur gross, sondern kaputt war — und jede brauchte eine andere Antwort:

| Stelle | Vorher | Jetzt |
|---|---|---|
| Eintragszeile | Uhrzeit auf 52 pt genagelt → „1…" | Ab Bedienhilfen-Grösse zweizeilig: Uhrzeit und Wert oben, Name darunter über die volle Breite |
| Umschalter kcal/mg | feste 124 × 40 → „kcal" abgeschnitten | Polster statt Rahmen, die Kapsel wächst mit |
| Sheet-Kopf | „Schließe / n" mitten im Wort | Titel und Knopf untereinander |
| Getränkeraster | zwei Spalten → „Macc…" neben „Cold…" | eine Spalte, volle Breite je Sorte |

`ViewThatFits` schied für den Sheet-Kopf aus: die Zeile lebt von einem `Spacer`, dessen Idealbreite null ist — die Kopfzeile stünde dann immer zusammengeschoben in der Mitte.

**`ScrollsWhenNeeded`** (in `DesignSystem.swift`) löst das allgemeinere Problem: bei 53 pt passt kein Sheet mehr auf den Schirm, und SwiftUI staucht dann die erste Zeile. Ein gewöhnlicher `ScrollView` wäre der Preis dafür, dass ein `Spacer` darin nichts mehr hält — die Getränkeliste hängt aber absichtlich unten, im Daumenbereich. `minHeight` aus der Container-Höhe hält beides: unter der Schwelle steht alles, wo es entworfen wurde, darüber wird gescrollt.

**Bewegung.** `accessibilityReduceMotion` schaltet das Zählwerk der Flipkarten ab: der Wert wird gesetzt, mit **einem** Impuls statt einer Kaskade. Die Rückmeldung bleibt, die Bewegung geht. Die Dot-Matrix läuft dann ohne Diagonale auf.

## Nur Hochformat

`UISupportedInterfaceOrientations` steht auf `UIInterfaceOrientationPortrait`, iPhone wie iPad. Der ganze Entwurf haengt an einer Spalte: der Zeitstrahl ist ein Tag von 24 Stunden in 96 Rasterspalten, die Anzeige benutzt dasselbe Raster, und die Erfassung kommt als Bottom Sheet von unten. Quer waere das Raster entweder gedehnt oder verloren — und ein Layout, das niemand entworfen hat, ist schlechter als eines, das gar nicht erst erscheint.

## Bewusst weggelassen

- **Ein eigener Scanner-Screen.** Der Barcode-Weg ist gebaut (`VNDetectBarcodesRequest` + Open Food Facts), aber ohne zweite Tür: das Foto, das du ohnehin machst, wird vorher geprüft. Ein Live-Scanner (`DataScannerViewController`) wäre die Nachrüstung, falls sich EANs aus normalem Abstand zu selten lesen lassen — siehe [Nährwertdatenbank](anbieter.md#nährwertdatenbank).
- **Offline-Cache der Produktdaten.** Jeder Scan fragt neu. Lohnt erst, wenn dieselben fünf Produkte täglich durchlaufen.
- **Die gescannte Menge speichern.** `Entry` hält die ausgerechneten Werte, nicht „200 g von X". Wer den Eintrag später bearbeitet, korrigiert deshalb kcal, nicht Gramm. Ein optionales `grams` wäre eine automatische SwiftData-Migration, falls das stört.
- **Rücklesen aus HealthKit** — die Tagessumme zeigt nur, was du in dieser App erfasst hast. Nötig, sobald eine zweite App Ernährungsdaten schreibt.
- **Nachträglicher Sync** von Einträgen, die bei ausgeschaltetem Sync entstanden sind.
- **Bearbeitbare Preset-Bibliothek**, Zielwerte/Tagesbudget, Wochen- und Verlaufsstatistiken, Widgets, iCloud-Sync (mit Personal Team ohnehin gesperrt).
