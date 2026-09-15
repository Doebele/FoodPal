# Ramadan-Bereich im Zeitstrahl

**Status: Konzept. Nicht umgesetzt, nicht angefangen.** Notiert als Kandidat
für ein Premium-Feature.

## Die Idee

Der Zeitstrahl zeigt den Tag ohnehin als 96 Spalten von 0 bis 24 Uhr. Während
des Ramadan wird zwischen Morgendämmerung und Sonnenuntergang nicht gegessen.
Also: **nur der Bereich, in dem gegessen werden darf, ist aktiv.** Der Rest des
Rasters steht still.

## Was die Grenzen wirklich sind

Der erste Reflex sagt „Sonnenaufgang bis Sonnenuntergang". Das ist falsch, und
zwar auf einer Seite deutlich:

- **Maghrib** ist der Sonnenuntergang. Der Sonnenmittelpunkt steht dann 0,833°
  unter dem Horizont — 34 Bogenminuten Refraktion plus 16 Bogenminuten
  Halbdurchmesser.
- **Fadschr** ist die *wahre Morgendämmerung*, nicht der Sonnenaufgang. Sie
  liegt je nach Methode 60 bis 90 Minuten früher.

Gefastet wird von Fadschr bis Maghrib. Gegessen wird von Maghrib bis Fadschr,
also **über Mitternacht hinweg**. Für den Zeitstrahl heisst das: der aktive
Bereich sind **zwei Stücke** — 0:00 bis Fadschr und Maghrib bis 24:00 —, und
der ruhende liegt in der Mitte. Das liest sich gut: der Tag ist in der Mitte
zu.

Fadschr ist ein Dämmerungswinkel, und der ist **Konvention, nicht Physik**:

| Methode | Fadschr |
|---|---|
| Muslim World League | 18° |
| ISNA (Nordamerika) | 15° |
| Ägyptische Vermessungsbehörde | 19,5° |
| Umm al-Qura (Saudi-Arabien) | 18,5° |
| Diyanet (Türkei) | 18° |

Diese Zahlen sind aus dem Gedächtnis notiert und **vor der Umsetzung gegen eine
Quelle zu prüfen**. Die Methode gehört in die Einstellungen, mit einer Vorgabe
nach Region.

## Standort, ohne das Versprechen zu brechen

Der Sonnenstand ist eine geschlossene Formel aus Datum, Breite und Länge.
**Kein Server, keine API** — die Rechnung läuft auf dem Gerät. „Kein Konto,
kein Server" bleibt wahr.

Gebraucht wird nur die Position. Drei Wege:

1. **CoreLocation mit reduzierter Genauigkeit.** Ein paar Kilometer verschieben
   die Zeit um Sekunden; stadtgenau genügt völlig. Braucht
   `NSLocationWhenInUseUsageDescription`.
2. **Stadt von Hand wählen.** Kein Berechtigungsdialog, keine neue Zusage.
3. **Zeitzone als Näherung.** Zu grob für den Betrieb, brauchbar als Startwert
   für die Stadtwahl.

Empfehlung: **2 als Vorgabe, 1 als Angebot.** Eine App, die bisher nichts vom
Nutzer will, sollte für ein Saisonfeature nicht plötzlich den Standort
verlangen.

## Welche Tage

Ramadan ist der neunte Monat des islamischen Kalenders, und iOS kann das ohne
Zutun: `Calendar(identifier: .islamicUmmAlQura)`, Monat 9.

Der Haken ist die Mondsichtung. Sie ist lokal und weicht regelmässig um einen
Tag von der Tabelle ab. Es braucht deshalb einen **Versatz von ±1 Tag** in den
Einstellungen. Ohne ihn ist das Feature an einem von dreissig Tagen falsch —
und zwar am ersten, dem, auf den es ankommt.

## Hohe Breiten

Über etwa 48,5° Nord erreicht die Sonne um die Sommersonnenwende die 18° unter
dem Horizont nicht mehr. Dann gibt es kein Fadschr, und die Formel liefert
nichts. Berlin liegt bei 52,5°.

Akut ist das nicht: Ramadan wandert jedes Jahr rund elf Tage nach vorn, liegt
2026 im Februar und bleibt zwei Jahrzehnte im Winterhalbjahr. Wer das Feature
trotzdem baut, muss einen der üblichen Behelfe wählen und ihn benennen —
nächstgelegener Ort mit gültigem Wert (Aqrab al-Bilad), Siebtel-Regel, Mitte
der Nacht.

## Darstellung

Die erloschenen Punkte des Zeitstrahls stehen in `Palette.matrix`. Für die
Fastenstunden werden sie **weiter zurückgenommen, bis auf Papier**. Dann gibt
es das Raster dort schlicht nicht, und der Tag steht als zwei Blöcke da. Kein
Rahmen, keine Schraffur, keine zweite Farbe — das Raster selbst sagt es, wie
überall sonst in der App.

Die Jetzt-Linie bleibt unverändert.

**Was nicht passieren darf:** Einträge in den Fastenstunden ausblenden,
verschieben oder mit einem Hinweis versehen. Wer isst, isst. Der Bereich ist
eine Auskunft, kein Urteil.

## Haltung

Das Feature berührt religiöse Praxis. Daraus folgen vier Regeln:

- Es **rechnet ein Zeitfenster aus**, es erteilt keine Auskunft. Nirgends steht
  „jetzt darfst du essen".
- Methode wählbar, Zeiten von Hand korrigierbar.
- **Aus, bis es jemand einschaltet.** Wer es nicht braucht, sieht nie etwas
  davon.
- Keine Gebetszeiten, keine Benachrichtigungen. Dafür gibt es bessere Apps, und
  es ist nicht, was Cafcalog ist.

## Warum Premium — und warum das wacklig ist

Vier Wochen im Jahr sind eine dünne Grundlage für ein Abo. Als **einmalige
Freischaltung** oder als Teil einer Unterstützerstufe passt es besser.

Der Wert liegt ohnehin nicht in der Rechnung — die kann jede
Gebetszeiten-App —, sondern darin, dass das Fenster **im selben Zeitstrahl**
steht wie das Essen. Genau das kann sonst niemand.

## Aufwand

| Teil | grob |
|---|---|
| Sonnenstand, Fadschr und Maghrib | 60 Zeilen |
| Standort oder Stadtwahl | 40 bis 80 Zeilen |
| Islamischer Kalender samt Versatz | 20 Zeilen |
| Einstellungen | 40 Zeilen |
| Zeitstrahl (`DayMatrix.swift`) | 30 Zeilen |

Ein bis zwei Tage. Der grössere Teil davon ist **Prüfen**: die gerechneten
Zeiten gegen veröffentlichte Tabellen für mehrere Städte und mehrere Methoden
halten. Eine Zeit, die zehn Minuten danebenliegt, ist bei diesem Thema nicht
„fast richtig".

## Der eigentliche Hebel

Derselbe Mechanismus trägt andere Fenster: **Intervallfasten** (16:8), eine
selbst gesetzte Essenszeit, ein **Koffein-Stopp** am Nachmittag. Der
Ramadan-Bereich ist der aufwendigste Fall davon — wer ihn baut, bekommt die
anderen fast geschenkt.

Das ist womöglich das bessere Produktargument: nicht „Ramadan-Modus", sondern
**Zeitfenster im Zeitstrahl**, von dem Ramadan der anspruchsvollste ist.
