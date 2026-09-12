#!/usr/bin/env python3
"""Die zwei Linkshänder-Bilder für die Promo-Seite, aus dem Simulator.

Gleiche Machart wie tools/screenshots.py — dieselbe Saat, dieselbe Uhr,
derselbe vergangene Tag —, nur mit der Bedienhand auf links gestellt. Die
Rechts-Gegenstücke sind die Store-Bilder 01 und 03; weil der Same identisch
ist, unterscheiden sich die Paare nur durch die Hand.

    python3 tools/promobilder.py

Ausgabe nach `bilder/promo/` (1320 × 2868, wie die Store-Bilder).
"""
import json
import subprocess
import time
from pathlib import Path

WURZEL = Path(__file__).resolve().parent.parent
ZIEL = WURZEL / "bilder" / "promo"
BUNDLE = "com.clausmedvesek.kk26"
GERAET = "iPhone 17 Pro Max"
UHRZEIT = "9:41"
VERSATZ = "-2"
MAHLZEITEN = ["Porridge", "Linsensuppe", "Pasta",
              "Porridge mit Beeren", "Bowl mit Lachs", "Ofengemüse"]
KAFFEE = "Filterkaffee"

# Je Bild: Dateiname, Startvariante, Einstellungen. Der Heute-Schirm zeigt
# Kalorien (Flip) — die Erfassung die Getränkekacheln, die bei links unten
# LINKS liegen; genau der Unterschied, den die Promo zeigen will.
BILDER = [
    ("links-heute", {}, {"numberStyle": "flip", "captureMode": "meal"}),
    ("links-erfassen", {"START_SHEET": "1"}, {"captureMode": "coffee"}),
    # Die Detailseite ist der interessierte Fall: bei links tauschen die
    # Spalten (bezeichnung/values links statt rechts), die Ausrichtung der
    # Texte bleibt. Gleiches Env wie Store-Bild 04, damit das Paar stimmt.
    ("links-eintrag", {"START_ENTRY": "coffee"}, {}),
]


def sim(*args, pruefen=True):
    return subprocess.run(["xcrun", "simctl", *args], capture_output=True,
                          text=True, check=pruefen).stdout.strip()


def geraet_id():
    daten = json.loads(sim("list", "devices", "--json"))
    for liste in daten["devices"].values():
        for g in liste:
            if g["name"] == GERAET and g["isAvailable"]:
                return g["udid"]
    raise SystemExit(f"Simulator {GERAET} nicht gefunden")


def app_pfad():
    treffer = sorted(Path.home().glob(
        "Library/Developer/Xcode/DerivedData/FoodPal-*/Build/Products/"
        "Debug-iphonesimulator/FoodPal.app"))
    if not treffer:
        raise SystemExit("Kein Simulator-Build — bitte erst bauen.")
    return treffer[-1]


def main():
    udid = geraet_id()
    app = app_pfad()
    if "Booted" not in sim("list", "devices", GERAET):
        sim("boot", udid, pruefen=False)
        time.sleep(20)
    sim("status_bar", udid, "override", "--time", UHRZEIT,
        "--cellularMode", "active", "--cellularBars", "4",
        "--wifiMode", "active", "--wifiBars", "3",
        "--batteryState", "discharging", "--batteryLevel", "100",
        pruefen=False)

    ZIEL.mkdir(parents=True, exist_ok=True)
    for name, umgebung, einstellungen in BILDER:
        sim("terminate", udid, BUNDLE, pruefen=False)
        time.sleep(0.5)
        # Frisch installieren: seedIfEmpty saet nur in leeren Speicher.
        sim("uninstall", udid, BUNDLE, pruefen=False)
        sim("install", udid, str(app))
        # Die Bedienhand VOR dem Start schreiben — alles andere wie beim
        # Store-Lauf, damit die Paare vergleichbar bleiben.
        sim("spawn", udid, "defaults", "write", BUNDLE, "hand",
            "-string", "left")
        for schluessel, wert in einstellungen.items():
            sim("spawn", udid, "defaults", "write", BUNDLE, schluessel,
                "-string", wert)

        umwelt = {"SIMCTL_CHILD_SEED_DEMO": "1",
                  "SIMCTL_CHILD_START_DAY": VERSATZ,
                  "SIMCTL_CHILD_DEMO_MEALS": "|".join(MAHLZEITEN),
                  "SIMCTL_CHILD_DEMO_COFFEE": KAFFEE,
                  **{f"SIMCTL_CHILD_{k}": v for k, v in umgebung.items()}}
        subprocess.run(
            ["xcrun", "simctl", "launch", udid, BUNDLE,
             "-AppleLanguages", "(de)", "-AppleLocale", "de_CH"],
            capture_output=True, check=True,
            env={**dict(__import__("os").environ), **umwelt})
        time.sleep(4)
        ziel = ZIEL / f"{name}.png"
        sim("io", udid, "screenshot", str(ziel))
        print(f"  {ziel.relative_to(WURZEL)}")

    sim("terminate", udid, BUNDLE, pruefen=False)
    sim("status_bar", udid, "clear", pruefen=False)


if __name__ == "__main__":
    main()
