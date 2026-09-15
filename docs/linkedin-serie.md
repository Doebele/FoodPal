---
tags: [projekt, ios, linkedin, marketing]
status: entwurf
erstellt: 2026-09-12
---

# Cafcalog – LinkedIn-Serie (5 Posts + Bonus)

Stand 2026-09-13. Fünfteilige Serie plus Bonus-Post zum iOS-27-Release. Am
12. September aus dem grill-me-Interview entstanden, am 13. September mit dem
Skill „vermenschlichen" stilistisch überarbeitet: KI-Muster reduziert
(Fettdruck-Lead-Ins, Gedankenstriche, negative Parallelismen), Ton an den
Sprachstil des Autors angelehnt. Publikum: KI-interessierte Fachleute,
Entwickler, Designer, Leute mit Geschäftsideen. Rhythmus: ein Post pro Woche.

Jeder Post liegt zusätzlich als eigene Notiz im Obsidian-Vault vor (Frontmatter,
geplantes Datum, Bildverweis) – diese Datei ist das Arbeitsdokument mit der
ganzen Serie und den redaktionellen Notizen.

Vorbereitendes Bildmaterial liegt unter `Developer/projects/food-pal/bilder/`:
Store-Screens in fünf Sprachen (`store/de` … `store/it`), App-Icon (`icon/`),
und im `kaffee/`-Ordner je Sorte vier Varianten (`barraquito-1.jpg` bis
`-4.jpg`) – ideal für Post 4. Fertige Collagen liegen in
`docs/linkedin-bilder/`.

---

## Post 1 – Die Geschichte: Sechs Tage, ein 20-Dollar-Abo, meine erste iOS-App

Vor gut einer Woche konnte ich kein Swift, hatte Xcode nie geöffnet und keine Ahnung, was ein Bundle Identifier ist. Jetzt liegt Cafcalog auf meinem iPhone: ein Logbuch für Kalorien und Koffein. Ein Foto oder ein Satz genügt für einen Eintrag, und für vorproduzierte Lebensmittel scannt man einfach den Barcode. Alles landet direkt in Apple Health.

Sechs Tage hat die Entwicklung gedauert. An meiner Seite: Claude (am Anfang auch GLM 5.3), mein Mac Mini, ein M4 Pro mit 64 GB RAM, und mein iPhone 17 Pro.

Rund 80 Prozent der Arbeit habe ich vom Handy aus gemacht. Ich habe Anweisungen per Sprache diktiert, das Ergebnis kontrolliert, nachgesteuert. Einmal ging das mitten auf einem Spaziergang mit dem Hund. Der Ablauf: Die Session läuft über mein Konto, der Mac Mini bleibt die Maschine, die arbeitet, Xcode installieren inklusive. Nach jedem Arbeitsschritt lag die neue Version auf meinem iPhone, und ich konnte auf dem Gerät weiterdenken, das die App später tragen soll.

Nach 24 Stunden hatte ich eine echte App in der Hand: sechs Kaffeesorten, korrekte Milligrammzahl, Synchronisation mit Apple Health. Nach 48 Stunden war sie fast einreichungsreif.

Drei Dinge habe ich gelernt, die ich nicht erwartet hätte:

1. Es gab keine Krise. Kein verlorenes Wochenende an einer Berechtigungskette, kein Debugging-Marathon. Die klassischen Fallgruben eines Erstprojekts (HealthKit, SwiftData, Deployment) sind vorhersehbare Probleme, und sie sind einfach nicht aufgetreten.

2. Die Designarbeit hat sich anders verteilt, als ich dachte. Ich habe gestaltet, Claude hat umgesetzt, und zwar pixelgenau. Davon erzähle ich nächste Woche.

3. Für die Bildauswertung braucht die App heute einen eigenen API-Key. Das ist der eine Punkt, der nicht elegant ist, und ich sage ihn lieber selbst: Wer ein passendes Modell oder Abo hat, kopiert den Key in die Einstellungen. Begründung: kein eigenes Backend, keine laufenden Kosten, keine Daten bei mir. Und es hat ein Ablaufdatum, dazu habe ich am Montag schon etwas geschrieben.

Cafcalog wird kostenlos sein. Kein Abo, keine Premium-Stufe, keine Datensammlung. Die teuren Tracker im Store packen Diätberatung dazu, die ich nie wollte. Ich wollte nur Kalorien und Koffein erfassen, und zwar so einfach wie möglich.

Was noch fehlt, bevor sie in den Store kann: die Texte in fünf Sprachen gegenlesen lassen, rechtliche Kleinigkeiten, das Developer-Programm. Die App ist fertig, die Hülle drumherum ist es noch nicht. Auch das gehört zur ehrlichen Geschichte.

Nächste Woche: Wie ich mit Claude und Figma gearbeitet habe, und warum mein Design nach zwei Runden pro Screen fertig war.

---

## Post 2 – Der Figma-Loop: Ich gestalte, Claude setzt um

Letzte Woche habe ich erzählt, wie in sechs Tagen Cafcalog entstanden ist. Heute der Teil, der für mich am überraschendsten war: die Zusammenarbeit im Design.

Eins vorab: Dieser Workflow braucht einen Figma-Professional-Account. Nur dort gibt es den Figma-MCP-Server, über den Claude und Figma miteinander reden. Die ehrliche Kostenrechnung meines Projekts: 20 Dollar Claude-Abo, dazu 15 Dollar Figma, und rund 10 Dollar Higgsfield für alle Kaffeebilder zusammen. Dazu in Teil 4 mehr.

So lief der Loop:

1. Ich sage Claude, welche Dateien er ins Figma übertragen soll, und gebe den Link zur Seite dazu.
2. Claude schreibt die Entwürfe direkt in meine Figma-Datei.
3. Ich überarbeite sie dort von Hand. Das Gestalten mache ich.
4. Ich gebe Claude den Frame zurück, und er übernimmt das Ergebnis pixelgenau in den Code.

Dazu gehören auch die Farbvariablen, in beide Richtungen. Passe ich einen Wert in Figma an, liest Claude ihn auf dem Rückweg wieder aus. An einem Punkt ist Claude einem Farbwert sogar zuvorgekommen. Er hat registriert, dass ein neuer Wert hinzugekommen war, und ihn übernommen, bevor ich ein Wort dazu gesagt hatte. Ich war überrascht, wie genau er dabei hinschaut.

Warum nur zwei Iterationen pro Screen? Nicht, weil alles auf Anhieb perfekt war. Sondern weil die Rollen sauber getrennt blieben: Die gestalterische Entscheidung fällt in Figma, bei mir, am Bildschirm. Claude hat nie designt, er hat übersetzt. Jede Runde, in der man das durcheinanderbringt, kostet Iterationen.

Mein Gestaltungsrahmen war simpel: Dieter Rams. So wenig wie möglich, reduziert auf das Wesentliche, kein Schnickschnack. Die 40-plus Kaffeesorten in der App wirken dem erst mal entgegen. Die Logik ist aber umgekehrt: Die App zeigt dir die zwei Getränke, die du täglich trinkst, großflächig. Danach sechs weitere, schnell zu scannen. Erst dahinter kommt die scrollbare Kachelreihe mit dem Rest. Was du oft antippst, wandert automatisch nach vorn. Die Komplexität ist da, aber sie liegt unter der Oberfläche, nicht auf ihr.

Der Schnickschnack, der geblieben ist, ist allerdings keiner: Die Kalorien- und Milligrammzahlen auf dem Hauptdisplay lassen sich in drei Retro-Darstellungen anzeigen, eine Sieben-Segment-Anzeige wie auf alten LCDs, ein Split-Flap-Display wie die Abfahrtstafeln am Bahnhof und eine Dot-Matrix. Digitale Röhrendisplays in SwiftUI, einfach weil ich sie schöner finde als Standard-Fonts.

Nächste Woche wird technischer: Xcode, HealthKit, Dynamic Fonts, und wie mein Mac Mini zu einem Mitarbeiter wurde.

---

## Post 3 – Xcode, HealthKit und ein Mac Mini als Kollege

Dritter Teil der Serie über Cafcalog, meine erste iOS-App.

Ich hatte vorher kein Swift geschrieben. Was mir an Xcode und iOS am meisten gebracht hat, und was mich überrascht hat:

Der Mac Mini wurde zur Werkbank. Ein M4 Pro mit 64 GB RAM und 4 TB Platte, gut ausgestattet, aber nicht das allerletzte Modell. Claude arbeitet dort direkt in Xcode. Für die Abnahme hat Claude die App selbst bedient: Bildschirmerkennung, Klicks, Eingaben. Ich konnte vom Handy aus zuschauen und steuern. Für die Layout-Prüfung hat Claude Screenshots des Simulators bei verschiedenen Schriftgrößen gemacht und sie mir als Bilder gezeigt. So habe ich Ausrichtungsfehler gesehen, die mir auf dem Standard-Schriftgrad nie aufgefallen wären. Was das nicht war: ein Ersatz für echte Accessibility-Prüfung. VoiceOver habe ich damit nicht getestet. Ich sage das lieber selbst, bevor es jemand im Kommentarbereich tut.

HealthKit war der Grund für das ganze Projekt. Ich fand im Store keine App, die Kalorien und Koffein gemeinsam erfasst, ohne Abo-Zwang und ohne Diätberatung, und die mit Apple Health spricht. Koffein-Tracking gibt es als Randfunktion in Habit-Apps, Kalorien-Tracker auch kostenlos. Die Kombination, simpel und mit Health-Synchronisation, habe ich nicht gefunden.

Und dann die Kleinigkeiten, die ein Projekt ausmachen. Beim Blättern zwischen Tagen und beim Umklappen der Split-Flap-Zahlen gibt es haptisches Feedback. Die App skaliert mit Dynamic Fonts, die Layouts bleiben dabei stabil. Links- und Rechtshänder schalten die Bedienung in den Einstellungen um.

Und dann ist da noch der Punkt, über den ich am Montag schon einmal geschrieben habe: die API-Key-Frage. Mit iOS 27, seit diesem Montag verfügbar, bekommen Entwickler über das Foundation Models framework multimodale Prompts: Bilder plus Text, analysiert auf dem Gerät, ohne API-Key, ohne Netzwerk, ohne dass ein Foto das iPhone verlässt. Auf iPhone 15 Pro und neuer. Genau das würde den einen Kompromiss meiner App überflüssig machen. Als Ausblick, nicht als angekündigtes Feature. Aber ihr dürft gespannt sein.

Übernächste Woche der letzte Teil: Wie 40-plus Kaffeegetränke Bilder bekamen, inklusive dem Modelltest, bei dem der Achtmal-günstigere Kandidat verloren hat.

---

## Post 4 – 172 Kaffeebilder: Der Flux-Prompt hinter den 40-plus Getränken

Vierter Teil der Cafcalog-Serie. Heute geht es ums Bildmaterial, und um das interessanteste Dokument, das bei diesem Projekt entstanden ist.

Die App kennt über 40 Kaffeesorten, vom Ristretto bis zum Barraquito von Teneriffa. Jede Sorte trägt ein Bild, alle aus einer Hand, alle im selben Stil. Die Kernfrage vorweg: Wie hält man 40 Generierungen konsistent?

Wir haben zuerst getestet, produziert wurde später. Bevor irgendetwas in Serie ging, sind vier Modelle an zwei Motiven gegangen: Espresso in der Tazzina und Vanilla Latte im hohen Glas, weil Gefäß, Schatten und Hintergrund zusammen die schwerste Probe sind. Ergebnis: Flux 2 pro war das einzige Modell, das alle drei Vorgaben gleichzeitig traf. Recraft renderte sauber, aber kühl und mit der falschen Tasse. Seedream und Soul, letzteres achtmal billiger, verloren bei Schatten und Grund. Der Achtmal-günstigere Kandidat hat verloren.

Der Produktionsprompt, im Original:

CAMERA 25 degrees above the rim plane, vessel upright and square to camera, base in frame. SUBJECT: {{DRINK}}. GROUND: one flat warm off-white tone #FAFAF8, empty in every direction, no horizon, no gradient, no visible surface. LIGHT: one large soft light from the upper left; exactly one soft shadow, on the ground to the lower right, about one vessel-width long, fading out. Matte throughout, no gloss, no reflection, no rim light. 85mm, whole vessel sharp, centred, alone in frame. Palette: off-white, near-black, roasted brown. Quiet Braun-catalogue product photography, blank undecorated surfaces.

Der Stilanker am Ende ist kein Zufall. Die Bilder sollen aussehen wie alte Braun-Katalogfotografie, ein Referenzrahmen, den man Jahrzehnte lang pflegen konnte.

Was wir dabei gelernt haben, und was im Prompt nicht steht:

- „No text" wurde dreimal überlesen. Eine Tasse trug am Ende das Wort „kaffee", eine andere einen erfundenen Röstereinamen. Hilft tut nicht das Verbot, sondern die Beschreibung: „its whole surface is one uniform plain white glaze from rim to foot, blank and undecorated". Flächen positiv beschreiben, statt Inhalte zu verbieten.
- Der Kamerastand wird hinten im Prompt überlesen. In Großbuchstaben und als erster Satz sitzt er.
- 25 Grad statt 10: Bei 10 Grad sieht man vom Getränk nichts, der Rand liegt als dünne Ellipse da. 25 Grad schaut weit genug ins Glas, um die Fläche zu lesen.
- Die Referenzfalle: Ein Hero-Bild als Stilreferenz überträgt Kamera und Licht tadellos, und überschreibt das Gefäß. Mit einer Tassen-Referenz kam der Barraquito, der im Glas gehört, als Tasse zurück. Lösung: je Gefäß ein eigener Hero, dann alle Sorten mit ihrem Gefäß-Helden als Referenz.
- Pappbecher sind raus. Wer sein Getränk nicht sieht, kann es auch nicht identifizieren. Also werden alle Getränke im Glas präsentiert, auch die, die man normalerweise to go trinkt. Das ist ein Kompromiss, und ein ehrlicher.

Vier Varianten je Sorte, dann die Auswahl von Hand. Das Modell ist daran nicht schuld; es streut eben bei Schaum und Schatten. 172 Bilder sind entstanden, je Sorte lagen vier Kandidaten vor. Die Auswahl ist inzwischen getroffen: ein Bild je Sorte, im Finder mit einem grünen Tag markiert, ausgewählt nach kurzem weichem Schatten, blankem Geschirr und ob das Getränk lesbar ist. Beim Barraquito die vier Bänder, beim Kafi Fertig die durchscheinenden Zuckerwürfel. Die drei Alternativen je Sorte bleiben als Ausgangsmaterial liegen, am Ende waren es 43 finale Bilder.

Und was hat der Satz gekostet? Gut 210 Credits, umgerechnet je nach Tarif rund 7 bis 10 Dollar. Soul wäre achtmal billiger gewesen und hat trotzdem verloren: Die Bilder sind die günstigste Zeile des Projekts und gleichzeitig die einzige mit eigenen Modellkosten. Die vollständige Rechnung steht in der Produktionsakte.

Und wo bleibt Apple Intelligence? Das freie Sketching aus der Texteingabe heraus ist nett, aber ein anderes Kaliber: schnelle Visualisierung statt konsistentem Satz. Für das eine ist es großartig, für das andere war Flux die richtige Wahl.

Nächste Woche der fünfte und letzte Teil, und der ist für die Entwickler unter euch: Wie die Kalorien- und Koffeinzahlen entstanden sind, mit offengelegter Rechnung statt geratener Werte.

---

## Post 5 – Keine geratenen Zahlen: Wie die Nährwerte wirklich entstanden

Letzter Teil der Cafcalog-Serie. Heute geht es nicht um KI, sondern um Zutatenlisten, Standardportionen und einen Unit-Test, der Schnaps entlarvt hat.

Die App kennt über 40 Kaffeegetränke mit Kalorien und Milligramm Koffein. Woher die Werte stammen, war mir wichtiger als jedes Feature.

Die Werte haben zwei sauber getrennte Quellen. Für Kettengetränke stehen Herstellerangaben in der offiziellen Ernährungstabelle (Bezugsgröße Grande, 473 ml). Für alles Übrige habe ich aus offengelegten Bausteinen gerechnet. Einen Barraquito gibt es nicht in der Fabrik, er entsteht in einer Bar auf Teneriffa. Also: Espresso 2 kcal und 63 mg, Vollmilch 64 kcal pro 100 ml, Kondensmilch 321, eine Whiskey-Portion 90. Jede Sorte trägt ihre Rechnung mit sich.

Damit sind die Getränke abgedeckt. Die Mahlzeiten laufen über eine dritte Quelle: die Open Food Database. Bei einem Foto schaut die App dort nach, was auf dem Teller liegt, und rechnet die Kalorien anhand der erkannten Menge. Beim Barcode-Scan ist es noch direkter: Die Nährwerte stehen schon auf dem Etikett, die App liest sie ab.

Dann die Gegenprobe. Eiweiß und Kohlenhydrate tragen 4 kcal pro Gramm, Fett 9, also muss die Summe der Makros die Kalorienzahl treffen. Sie tat es fast überall. Die fünf Ausnahmen: Carajillo, Irish Coffee, Schümli Pflümli, Kafi Fertig, Café Baileys. Das ist kein Fehler, sondern der Beweis, dass die Rechnung greift. Alkohol trägt 7 kcal pro Gramm und ist weder Eiweiß noch Kohlenhydrat noch Fett, und die Lücken waren exakt die Schnapsmengen. Beim Kafi Fertig hat die Probe sogar eine Zahl korrigiert: Drei Schweizer Würfelzucker sind 12 Gramm, nicht 9. Die Lücke schloss sich auf null.

Warum nicht einfach ein Modell fragen? Weil eine offengelegte Rechnung nachrechenbar und korrigierbar ist. Eine geratene Zahl sieht genauso aus, wie sie ist: geraten. Die Zahlen zu Cola und Red Bull stehen deshalb in Code und nicht im Prompt. Zwei Unit-Tests halten die Konsistenz fest: keine Sorte trägt mehr Makros als Kalorien, und was keinen Alkohol enthält, ist zu mindestens 85 Prozent durch seine Makros erklärt.

Und ja, auch das hat eine Geschichte. Die App ist fünfsprachig. Beim Dateinamen-Folding für die Kaffeebilder flutschte fast ein vietnamesischer Buchstabe durch: Das đ in Cà phê sữa đá sieht aus wie ein d mit Strich, ist aber ein eigener Buchstabe. Apples diacritic-insensitive Vergleich lässt ihn stehen, wo er É und Ó glattzieht. Ein Test prüft die vier Namen, an denen das passieren kann.

Das war die Serie: sechs Tage, eine erste App, ein Loop mit Figma, ein Mac Mini als Werkbank, 172 generierte Bilder und eine Tabelle mit offengelegter Rechnung. Was die fünf Posts gemeinsam haben, ist der Arbeitsmodus. Ich habe entschieden, die Maschinen haben ausgeführt, und an jeder Stelle steht dokumentiert, warum es so und nicht anders ist.

Wer Fragen hat: her damit. Wer die App sehen will, sobald sie im Store ist: folgt mir gern.

---

## Bonus-Post – Erscheint am 14. September, dem iOS-27-Tag

Kurzer, eigenständiger Post zum Release, verlinkt auf die Serie. Empfehlung: als erster Post der Reihe veröffentlichen, er nutzt den Nachrichtenanlass und verweist nach vorn.

Heute erscheint iOS 27, und für mich ist ein Satz in den Developer-Notizen wichtiger als die Keynote-Features: Das Foundation Models framework bekommt multimodale Prompts. Heißt: Eine App kann ab heute Bilder plus Text direkt auf dem iPhone analysieren, offline, ohne API-Key, ohne dass ein Foto das Gerät verlässt.

Warum ich das so genau anschaue: Ich habe in den letzten zwei Wochen meine erste iOS-App gebaut, ein Logbuch für Kalorien und Koffein. Für die eine Funktion, die ein Foto des Essens auswertet, braucht die App heute einen eigenen API-Key. Das war der einzige Punkt im Projekt, der sich nicht elegant lösen ließ: Backend wollte ich nicht bauen, Abo nicht verlangen, Daten nicht sammeln.

Mit iOS 27 gibt es dafür einen sauberen Weg: On-Device-Inferenz über das Systemmodell, auf iPhone 15 Pro und neuer. Keine Kosten pro Anfrage, keine Datenbank bei mir, kein Foto in der Cloud. Für eine kostenlose App, die niemandem etwas verkaufen will, ist das die Lösung, die es vorher schlicht nicht gab.

Für Gründer heißt das ganz nüchtern: Eine KI-Funktion, für die man früher Backend-Infrastruktur und laufende Kosten brauchte, passt jetzt in eine App, die ein Einzelner in einer Woche gebaut hat.

Ich dokumentiere gerade die ganze Entwicklung in einer fünfteiligen Serie hier: sechs Tage, ein 20-Dollar-Abo, ein Mac Mini, 172 generierte Kaffeebilder und eine Nährwerttabelle mit offengelegter Rechnung. Der erste Teil kommt diese Woche.

---

## Redaktionelle Notizen (nicht posten)

- Zahlen konsistent halten: „über 40" Sorten (Akte sagt 43 erzeugt, 17 mit Warenkunde; der mündlich genannte Wert „40" wurde als „über 40" vereinheitlicht).
- Preise ehrlich nennen: 20 $ Claude + 15 $ Figma Professional (Pflicht für MCP) + ~7–10 $ Higgsfield (gut 210 Credits, Rechnung in `docs/kaffeebilder.md`, Kap. „Was der Satz gekostet hat"; Preise Stand 9/2026, vor Veröffentlichung gegen die Higgsfield-Preisseite prüfen).
- Nicht im Store → transparent in Post 1, keine „fertige App"-Behauptung.
- API-Key: offen adressieren in Post 1 und 3, iOS-27-Ausblick mit Erscheinungsdatum 14.9.2026 und Hardware-Grenze (iPhone 15 Pro+).
- Accessibility: nur behaupten, was geprüft wurde (Screenshots bei Dynamic-Type-Größen). Keine VoiceOver-Behauptung.
- Bonus-Post am 14.9. (iOS-27-Release) als Auftakt veröffentlichen, danach Post 1–5 im Wochenrhythmus. In Post 3 auf den Bonus-Post zurückverlinken statt den Ausblick zu wiederholen.
- Zielpublikum (vom Autor bestätigt): KI-interessierte Fachleute, darunter Entwickler und Designer, sowie Leute mit Geschäftsideen. Ton: technisch, aber lesbar; Nutzen für Gründer betonen (Aufwand, Kosten, Arbeitsmodus).
- Bildzuordnung final (alle unter `docs/linkedin-bilder/` im Projekt-Workspace):
  - Post 1 → `post1-app-collage.jpg` (drei Screens: Tag, Kaffeeauswahl, Eintrag)
  - Post 2 → `post2-figma-vs-app.jpg` (echter Figma-Frame „A · Heute", per use_figma/MCP exportiert, gegen fertigen Screen)
  - Post 3 → `post3-display-modi.jpg` (Sieben-Segment, Split-Flap, Dot-Matrix)
  - Post 4 → `post4-barraquito-varianten.jpg` (gewählte Variante mit grünem Rahmen)
  - Post 5 → `post5-irish-coffee-rechnung.jpg` (Rechnungsgrafik Irish Coffee, Werte aus `docs/kaffeebilder.md`)
- Die Akte `docs/kaffeebilder.md` darf als Begleitdokument verlinkt werden (z. B. Gist), wenn gewünscht – enthält aber interne Kostenangaben (Credits/Bild), vor Veröffentlichung prüfen.
- Bildauswahl ist getroffen: 43 finale Bilder, im Finder per grünem Tag markiert (Attribut `com.apple.metadata:_kMDItemUserTags`). Beispiel Barraquito: final ist `bilder/kaffee/barraquito-1.jpg`, Alternativen `barraquito-2` bis `-4`.
