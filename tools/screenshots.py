#!/usr/bin/env python3
"""Bilder für den App Store, aus dem Simulator.

Fünf Schirme in fünf Sprachen, ein Lauf. Angesteuert werden sie über die
Startvarianten, die ohnehin im Debug-Build stecken — **kein einziger Tipp auf
den Bildschirm**. Was man antippen muss, geht beim nächsten Lauf anders aus;
was über eine Umgebungsvariable kommt, sieht jedes Mal gleich aus.

    python3 tools/screenshots.py            # alle Sprachen
    python3 tools/screenshots.py de en      # nur diese

Ausgabe nach `bilder/store/<sprache>/`. Die Bilder liegen **nicht** im
Repository: sie sind aus diesem Skript reproduzierbar, und 25 Stück zu
1320 × 2868 wären fünfzig Megabyte Ausguss.

Voraussetzung ist ein Build für den Simulator. Das Skript baut selbst, wenn es
keinen findet.
"""
import json
import subprocess
import sys
import time
from pathlib import Path

WURZEL = Path(__file__).resolve().parent.parent
ZIEL = WURZEL / "bilder" / "store"
BUNDLE = "com.clausmedvesek.kk26"
# 1320 × 2868 — die 6,9 Zoll, die App Store Connect verlangt. Alles Kleinere
# rechnet Apple selbst daraus.
GERAET = "iPhone 17 Pro Max"
# **Ein vergangener Tag, und die Uhr darf stehen, wo sie will.**
#
# Die Statusleiste laesst sich setzen, die Jetzt-Linie folgt aber `Date.now` —
# die eine zeigte neun Uhr, die andere den echten Nachmittag. Die Linie auf
# dieselbe Zeit zu nageln half nur halb: dann duerfte kein Eintrag nach dieser
# Zeit im Tag stehen, und `simctl --time` nimmt ohnehin nur Zwoelfstundenzeiten
# — `9:41` geht, `20:00` wird abgewiesen. Ein Tag mit vollem Zeitstrahl und
# frueher Uhrzeit ist also gar nicht zu haben.
#
# Ein **vergangener** Tag loest beides: er ist fertig gelaufen und traegt alle
# Eintraege, und er hat kein Jetzt — also keine Linie, die widersprechen
# koennte. Die Uhr steht auf 9:41 wie in Apples eigenen Bildern.
#
# Zwei Tage zurueck und nicht einer: dort steht im Kopf ein Datum statt des
# Wortes „gestern". Im ersten Bild, das jemand von der App sieht, ist ein
# Datum eine Angabe und „gestern" eine Frage.
UHRZEIT = "9:41"
VERSATZ = "-2"

# Je Sprache: Gebietsschema, die sechs Beispielmahlzeiten, und **die
# Kaffeesorte fuer den Detailschirm**. Die Warenkunde ist das Herzstueck der
# App, und sie zeigt sich am besten an einer Sorte, die der jeweilige Markt
# kennt: ein Barraquito auf Spanisch, ein Espresso auf Italienisch, ein
# Filterkaffee auf Deutsch.
SPRACHEN = {
    "de": ("de_CH", "Filterkaffee",
           ["Porridge", "Linsensuppe", "Pasta",
            "Porridge mit Beeren", "Bowl mit Lachs", "Ofengemüse"]),
    "en": ("en_US", "Flat White",
           ["Porridge", "Lentil soup", "Pasta",
            "Porridge with berries", "Salmon bowl", "Roast vegetables"]),
    "fr": ("fr_FR", "Café au Lait",
           ["Porridge", "Soupe de lentilles", "Pâtes",
            "Porridge aux fruits rouges", "Bowl au saumon", "Légumes rôtis"]),
    "it": ("it_IT", "Espresso",
           ["Porridge", "Zuppa di lenticchie", "Pasta",
            "Porridge ai frutti di bosco", "Bowl al salmone", "Verdure al forno"]),
    "es": ("es_ES", "Barraquito",
           ["Porridge", "Sopa de lentejas", "Pasta",
            "Porridge con frutos rojos", "Bowl de salmón", "Verduras al horno"]),
}

# Je Schirm: Dateiname, Umgebung, und was in den Einstellungen stehen soll.
# Die Ziffernstile wechseln bewusst durch — sie sind das Eigenste an der App.
SCHIRME = [
    ("01-tagesverlauf",         {}, {"numberStyle": "flip", "captureMode": "meal"}),
    ("02-koffein",       {}, {"numberStyle": "dotMatrix", "captureMode": "coffee"}),
    ("03-kaffee",        {"START_SHEET": "1"}, {"captureMode": "coffee"}),
    ("04-eintrag",       {"START_ENTRY": "coffee"}, {}),
    ("05-sorte",         {"START_ENTRY": "coffee", "START_LORE": "bild"}, {}),
    ("06-warenkunde",    {"START_ENTRY": "coffee", "START_LORE": "1"}, {}),
    ("07-einstellungen", {"START_SETTINGS": "1"}, {"numberStyle": "sevenSegment"}),
]


def sim(*args, pruefen=True):
    return subprocess.run(["xcrun", "simctl", *args], capture_output=True, text=True,
                          check=pruefen).stdout.strip()


def geraet_id():
    daten = json.loads(sim("list", "devices", "--json"))
    for liste in daten["devices"].values():
        for g in liste:
            if g["name"] == GERAET and g["isAvailable"]:
                return g["udid"]
    sys.exit(f"Simulator {GERAET} nicht gefunden")


def app_pfad():
    treffer = sorted(Path.home().glob(
        "Library/Developer/Xcode/DerivedData/FoodPal-*/Build/Products/"
        "Debug-iphonesimulator/FoodPal.app"))
    if treffer:
        return treffer[-1]
    print("Kein Simulator-Build gefunden, baue …")
    subprocess.run(
        ["xcodebuild", "-project", str(WURZEL / "FoodPal/FoodPal.xcodeproj"),
         "-scheme", "FoodPal", "-destination",
         f"platform=iOS Simulator,name={GERAET}", "build"],
        check=True, capture_output=True)
    return app_pfad()


def main():
    gewuenscht = sys.argv[1:] or list(SPRACHEN)
    unbekannt = [s for s in gewuenscht if s not in SPRACHEN]
    if unbekannt:
        sys.exit("unbekannte Sprache: " + ", ".join(unbekannt))

    udid = geraet_id()
    app = app_pfad()
    if "Booted" not in sim("list", "devices", GERAET):
        sim("boot", udid, pruefen=False)
        time.sleep(20)
    sim("install", udid, str(app))
    # Neun Uhr einundvierzig, volle Balken, kein Ladesymbol: so macht es Apple
    # in jedem eigenen Bild, und ohne das steht auf jedem Schirm eine andere
    # Uhrzeit — im fertigen Satz faellt das sofort auf.
    sim("status_bar", udid, "override", "--time", UHRZEIT,
        "--cellularMode", "active", "--cellularBars", "4",
        "--wifiMode", "active", "--wifiBars", "3",
        "--batteryState", "discharging", "--batteryLevel", "100", pruefen=False)

    gemacht = 0
    for sprache in gewuenscht:
        locale, kaffee, mahlzeiten = SPRACHEN[sprache]
        ordner = ZIEL / sprache
        ordner.mkdir(parents=True, exist_ok=True)

        # **Frisch installieren je Sprache.** `seedIfEmpty` saet nur in einen
        # leeren Speicher; ohne das Loeschen behielte Englisch die deutschen
        # Bezeichnungen aus dem Lauf davor. Gekostet hat mich das einen
        # Durchgang mit „Ofengemuese" in der englischen Fassung.
        sim("uninstall", udid, BUNDLE, pruefen=False)
        sim("install", udid, str(app))

        for name, umgebung, einstellungen in SCHIRME:
            sim("terminate", udid, BUNDLE, pruefen=False)
            time.sleep(0.5)
            # **Vor** dem Start schreiben, nicht danach: die App legt ihre
            # eigenen Werte beim Beenden ab und ueberschriebe sonst diese hier.
            for schluessel, wert in einstellungen.items():
                sim("spawn", udid, "defaults", "write", BUNDLE, schluessel, "-string", wert)

            umwelt = {"SIMCTL_CHILD_SEED_DEMO": "1",
                      "SIMCTL_CHILD_START_DAY": VERSATZ,
                      "SIMCTL_CHILD_DEMO_MEALS": "|".join(mahlzeiten),
                      "SIMCTL_CHILD_DEMO_COFFEE": kaffee,
                      **{f"SIMCTL_CHILD_{k}": v for k, v in umgebung.items()}}
            subprocess.run(
                ["xcrun", "simctl", "launch", udid, BUNDLE,
                 "-AppleLanguages", f"({sprache})", "-AppleLocale", locale],
                capture_output=True, check=True,
                env={**dict(__import__("os").environ), **umwelt})
            # Vier Sekunden: das Sheet muss oben sein und die Anzeige stehen.
            time.sleep(4)
            ziel = ordner / f"{name}.png"
            sim("io", udid, "screenshot", str(ziel))
            gemacht += 1
            print(f"  {sprache}/{name}.png")

    sim("terminate", udid, BUNDLE, pruefen=False)
    sim("status_bar", udid, "clear", pruefen=False)
    print(f"\n{gemacht} Bilder in {ZIEL.relative_to(WURZEL)}/")
    print("Format prüfen:  sips -g pixelWidth -g pixelHeight "
          f"{ZIEL.relative_to(WURZEL)}/de/01-heute.png")


if __name__ == "__main__":
    main()
