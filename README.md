# FoodPal
Mobile App to track and capture food and drinking habits

## Übersetzungen gegenlesen

Der String-Katalog `FoodPal/FoodPal/Localizable.xcstrings` ist das Original.
Zum Gegenlesen gibt es eine Tabelle:

```bash
python3 tools/uebersetzungen.py export          # -> docs/uebersetzungen.csv
python3 tools/uebersetzungen.py import datei.csv
```

Semikolon-getrennt und UTF-8 mit BOM, damit Excel und Numbers ohne
Nachfragen aufteilen; in Google Sheets über *Datei → Importieren* einlesen.
Der Import schreibt nur Werte zurück und legt keine Schlüssel an — was in
der Tabelle steht und im Katalog fehlt, ist ein Tippfehler, keine neue Zeile.

Der offizielle Weg für Übersetzungsbüros wäre stattdessen
`xcodebuild -exportLocalizations` / `-importLocalizations` mit `.xcloc`-Paketen.
