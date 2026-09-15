#!/usr/bin/env python3
"""Legt die ausgewaehlten Kaffeebilder in den Asset-Katalog.

Quelle ist `tools/kaffeeauswahl.txt`: eine Zeile je Sorte, der Dateiname
ohne Endung, also `espresso-3`. Die vier Kandidaten je Sorte liegen in
`bilder/kaffee/` und sind nicht im Repository — der Katalog ist es.

Die Sortennamen kommen aus `Entry.swift`, damit es keine zweite Liste gibt.
"""
import json
import re
import shutil
import sys
import unicodedata
from pathlib import Path

WURZEL = Path(__file__).resolve().parent.parent
QUELLE = WURZEL / "bilder" / "kaffee"
KATALOG = WURZEL / "FoodPal" / "FoodPal" / "Assets.xcassets" / "coffee"
AUSWAHL = WURZEL / "tools" / "kaffeeauswahl.txt"
ENTRY = WURZEL / "FoodPal" / "FoodPal" / "Entry.swift"

UMLAUTE = {"ä": "ae", "ö": "oe", "ü": "ue", "ß": "ss", "đ": "d"}


def ascii_falten(text):
    """Wie `CoffeeInfo.fold` in Swift: đ ersetzen, Akzente weg, nur a-z0-9."""
    text = text.replace("đ", "d")
    zerlegt = unicodedata.normalize("NFD", text.lower())
    return "".join(c for c in zerlegt if c.isalnum() and c.isascii())


def deutsch_falten(text):
    """Dieselbe Faltung, aber ue statt u — so sind die Dateien benannt."""
    for um, ersatz in UMLAUTE.items():
        text = text.lower().replace(um, ersatz)
    return ascii_falten(text)


def presets():
    quelle = ENTRY.read_text(encoding="utf-8")
    block = re.search(r"static let all.*?\n    \]", quelle, re.S)
    return re.findall(r'name: "([^"]*)"', block.group(0))


def main():
    namen = presets()
    # Ein Dateistamm darf auf beide Faltungen passen: `tuerkischer-mokka`
    # kommt aus der deutschen, `cafe-bombon` aus der ASCII-Fassung.
    nach_preset = {}
    for name in namen:
        for schluessel in (ascii_falten(name), deutsch_falten(name)):
            nach_preset[schluessel] = name

    if not AUSWAHL.exists():
        sys.exit(f"fehlt: {AUSWAHL}")

    gesetzt, fehler = {}, []
    for zeile in AUSWAHL.read_text(encoding="utf-8").splitlines():
        zeile = zeile.split("#")[0].strip()
        if not zeile:
            continue
        datei = QUELLE / f"{zeile}.jpg"
        if not datei.exists():
            fehler.append(f"{zeile}: keine Datei")
            continue
        stamm = re.sub(r"-\d+$", "", zeile)
        name = nach_preset.get(ascii_falten(stamm))
        if name is None:
            fehler.append(f"{zeile}: keine Sorte dazu")
            continue
        ziel = ascii_falten(name)
        ordner = KATALOG / f"{ziel}.imageset"
        ordner.mkdir(parents=True, exist_ok=True)
        shutil.copy2(datei, ordner / f"{ziel}.jpg")
        (ordner / "Contents.json").write_text(json.dumps({
            "images": [{"filename": f"{ziel}.jpg", "idiom": "universal"}],
            "info": {"author": "xcode", "version": 1},
        }, indent=2) + "\n", encoding="utf-8")
        gesetzt[name] = zeile

    KATALOG.mkdir(parents=True, exist_ok=True)
    (KATALOG / "Contents.json").write_text(json.dumps({
        "info": {"author": "xcode", "version": 1},
        "properties": {"provides-namespace": True},
    }, indent=2) + "\n", encoding="utf-8")

    print(f"{len(gesetzt)} von {len(namen)} Sorten im Katalog")
    offen = [n for n in namen if n not in gesetzt]
    if offen:
        print("offen: " + ", ".join(offen))
    for f in fehler:
        print("FEHLER " + f)
    return 1 if fehler else 0


if __name__ == "__main__":
    sys.exit(main())
