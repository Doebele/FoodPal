#!/usr/bin/env python3
"""Übersetzungen zwischen String-Katalog und Tabelle hin- und herschieben.

    python3 tools/uebersetzungen.py export  [datei.csv]
    python3 tools/uebersetzungen.py import   datei.csv

Der Katalog ist das Original — die Tabelle ist nur die Fassung, die man
jemandem zum Gegenlesen gibt. Deshalb schreibt der Import ausschließlich
Werte zurück und legt keine Schlüssel an: was in der Tabelle steht und im
Katalog fehlt, ist ein Tippfehler und keine neue Zeile.

Komma und die nackten Sprachkürzel als Spaltenköpfe — genau so, wie
Google Sheets die Tabelle wieder ausgibt. Der Import erkennt das Trennzeichen
selbst, damit auch eine mit Semikolon gespeicherte Fassung durchgeht.
"""

import csv
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
# Zwei Kataloge: die Oberfläche und die sechs Berechtigungstexte, die iOS
# selbst zeigt. Beide gehören in dieselbe Tabelle — wer gegenliest, soll
# nicht die Hälfte der sichtbaren Sätze übersehen.
CATALOGS = [
    ROOT / "FoodPal" / "FoodPal" / "Localizable.xcstrings",
    ROOT / "FoodPal" / "FoodPal" / "InfoPlist.xcstrings",
]
LANGS = ["de", "en", "fr", "it", "es"]
HEADER = ["Schlüssel (deutsch)"] + LANGS[1:] + ["Anmerkung"]


def value(entry, lang):
    unit = entry.get("localizations", {}).get(lang, {}).get("stringUnit", {})
    return unit.get("value", "")


def entries():
    """Alle übersetzten Einträge beider Kataloge, deutsch zuerst.

    Vorn steht immer der **deutsche Satz**, nicht der Schlüssel: in der
    Oberfläche ist beides dasselbe, bei den Berechtigungstexten heisst der
    Schlüssel `NSCameraUsageDescription` und sagt dem Gegenleser nichts.
    """
    catalogs = [(path, json.loads(path.read_text())) for path in CATALOGS]
    for path, catalog in catalogs:
        for key, entry in sorted(catalog["strings"].items()):
            if not entry.get("localizations"):
                continue  # unübersetzt gelassen: Einheiten, Eigennamen
            yield value(entry, "de") or key, entry


def export(target: Path):
    rows = []
    for label, entry in entries():
        rows.append([label] + [value(entry, l) for l in LANGS[1:]] + [""])

    with target.open("w", encoding="utf-8-sig", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(HEADER)
        writer.writerows(rows)
    print(f"{len(rows)} Zeilen → {target}")


def import_(source: Path):
    catalogs = [(path, json.loads(path.read_text())) for path in CATALOGS]
    known = {}
    for _, catalog in catalogs:
        for key, entry in catalog["strings"].items():
            if entry.get("localizations"):
                known[value(entry, "de") or key] = entry

    changed, unknown = 0, []

    with source.open(encoding="utf-8-sig", newline="") as f:
        # Semikolon oder Komma: was in der Kopfzeile öfter vorkommt, trennt.
        head = f.readline()
        f.seek(0)
        for row in csv.DictReader(f, delimiter=";" if head.count(";") > head.count(",") else ","):
            key = (row.get(HEADER[0]) or "").strip()
            entry = known.get(key)
            if not entry:
                if key:
                    unknown.append(key)
                continue
            for lang, column in zip(LANGS[1:], HEADER[1:-1]):
                new = (row.get(column) or "").strip()
                if new and new != value(entry, lang):
                    entry.setdefault("localizations", {})[lang] = {
                        "stringUnit": {"state": "translated", "value": new}
                    }
                    changed += 1

    for path, catalog in catalogs:
        path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n")
    print(f"{changed} Werte übernommen")
    for key in unknown:
        print(f"  unbekannter Schlüssel, übersprungen: {key!r}")


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    path = Path(sys.argv[2]) if len(sys.argv) > 2 else ROOT / "docs" / "uebersetzungen.csv"

    if mode == "export":
        export(path)
    elif mode == "import":
        import_(path)
    else:
        sys.exit(__doc__)
