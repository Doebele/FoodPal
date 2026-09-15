#!/usr/bin/env python3
"""Web-Kopien der Schirme für die Promo-Seite.

Die Store-Bilder sind 1320 px breit — fürs Netz reicht eine Breite, die
grossste Galerie-Kachel ist 6 Spalten auf der 1280er-Buehne, also 1240 px
bei Doppel-Pixeldichte. Alles wird auf diese eine Breite gebracht; kleinere
Kacheln skaliert der Browser herunter. Ein Format, ein Rhythmus.

    python3 tools/webbilder.py

Legt an (ueberschreibt bestaehende):
    web/bilder/galerie/<name>.png   — die acht deutschen Store-Schirme
    web/bilder/galerie/hand-*.png   — die zwei Bedienhand-Schirme
"""
import shutil
import subprocess
from pathlib import Path

WURZEL = Path(__file__).resolve().parent.parent
BREITE = 1240

QUELLEN = {
    "tag": "bilder/store/de/01-tagesverlauf.png",
    "koffein": "bilder/store/de/02-koffein.png",
    "kaffee": "bilder/store/de/03-kaffee.png",
    "eintrag": "bilder/store/de/04-eintrag.png",
    "sorte": "bilder/store/de/05-sorte.png",
    "warenkunde": "bilder/store/de/06-warenkunde.png",
    "einstellungen": "bilder/store/de/07-einstellungen.png",
    "jetzt": "bilder/store/de/08-jetzt.png",
    "hand-rechts": "bilder/promo/heute-rechts.png",
    "hand-links": "bilder/promo/links-heute.png",
    "hand-eintrag-rechts": "bilder/promo/eintrag-rechts.png",
    "hand-eintrag-links": "bilder/promo/links-eintrag.png",
}


def main():
    ziel = WURZEL / "web" / "bilder" / "galerie"
    ziel.mkdir(parents=True, exist_ok=True)
    for name, relativ in QUELLEN.items():
        quelle = WURZEL / relativ
        ausgabe = ziel / f"{name}.png"
        subprocess.run(["sips", "--resampleWidth", str(BREITE),
                        str(quelle), "--out", str(ausgabe)],
                       capture_output=True, check=True)
        groesse = ausgabe.stat().st_size // 1024
        print(f"  {ausgabe.relative_to(WURZEL)}  ({groesse} kB)")
    # Das Icon als Favicon bereithalten.
    shutil.copy(WURZEL / "bilder" / "icon" / "icon.svg",
                WURZEL / "web" / "bilder" / "icon.svg")


if __name__ == "__main__":
    main()
