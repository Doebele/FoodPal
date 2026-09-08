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
CATALOG = ROOT / "FoodPal" / "FoodPal" / "Localizable.xcstrings"
LANGS = ["de", "en", "fr", "it", "es"]
HEADER = ["Schlüssel (deutsch)"] + LANGS[1:] + ["Anmerkung"]


def load():
    return json.loads(CATALOG.read_text())


def value(entry, lang):
    unit = entry.get("localizations", {}).get(lang, {}).get("stringUnit", {})
    return unit.get("value", "")


def export(target: Path):
    catalog = load()
    rows = []
    for key, entry in sorted(catalog["strings"].items()):
        if not entry.get("localizations"):
            continue  # unübersetzt gelassen: Einheiten, Eigennamen
        rows.append([key] + [value(entry, l) for l in LANGS[1:]] + [""])

    with target.open("w", encoding="utf-8-sig", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(HEADER)
        writer.writerows(rows)
    print(f"{len(rows)} Zeilen → {target}")


def import_(source: Path):
    catalog = load()
    changed, unknown = 0, []

    with source.open(encoding="utf-8-sig", newline="") as f:
        # Semikolon oder Komma: was in der Kopfzeile öfter vorkommt, trennt.
        head = f.readline()
        f.seek(0)
        for row in csv.DictReader(f, delimiter=";" if head.count(";") > head.count(",") else ","):
            key = (row.get(HEADER[0]) or "").strip()
            entry = catalog["strings"].get(key)
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

    CATALOG.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n")
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
