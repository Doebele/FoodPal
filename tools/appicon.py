#!/usr/bin/env python3
"""Vorlaeufiges App-Icon im Punktraster: Tasse mit Unterteller.

Gerastert wie die Ziffern des Zaehlwerks. Der Punkt misst 0,6 der Teilung —
dasselbe Verhaeltnis wie im Zeitstrahl, wo auf 3 pt Punkt 2 pt Luft folgen.

Schreibt die drei Fassungen in den Asset-Katalog (hell, dunkel, getoent) und
daneben eine SVG samt Punktliste, aus der sich die Form in Figma weiterbauen
laesst.

    python3 tools/appicon.py
"""
import json
from pathlib import Path

WURZEL = Path(__file__).resolve().parent.parent
KATALOG = WURZEL / "FoodPal/FoodPal/Assets.xcassets/AppIcon.appiconset"
ENTWURF = WURZEL / "bilder/icon"

KANTE = 1024
RAND = 128                       # Abstand zur Maske, ein Achtel der Kante

# Papier, Ink und die Roestung „Hell" — die Vorgabe der App.
HELL = {"grund": "#FAFAF8", "ink": "#161614", "akzent": "#B4531F"}
DUNKEL = {"grund": None, "ink": "#F0F0EA", "akzent": "#E08A4E"}
GETOENT = {"grund": None, "ink": "#FFFFFF", "akzent": "#B8B8B8"}


def zellen():
    """Tasse mit Unterteller, Zeile fuer Zeile.

    Die Breite steht ausgeschrieben statt gerechnet: eine Verjuengung trifft
    bei so wenigen Zellen entweder keine Rasterlinie oder gleich zwei und wird
    zum Trichter.

    **Acht Zellen breit und nicht mehr.** Auf dem Home-Bildschirm steht das
    Icon 60 pt gross, also 120 px. Ein feineres Raster faellt dort unter fuenf
    Pixel je Punkt und wird zur Textur — nachgemessen an einer ersten Fassung
    mit zwoelf Zellen, die als Streumuster ankam statt als Tasse.
    """
    KAFFEE = "kaffee"
    zeilen = [
        (6, "rand"),       # der Tassenrand
        (6, KAFFEE),
        (6, KAFFEE),
        (6, "wand"),
        (4, "fuss"),       # der Fuss zieht sich ein
        (8, "teller"),     # und der Teller steht darunter heraus
    ]
    z = {}
    for r, (breite, art) in enumerate(zeilen):
        for c in range(8 - breite // 2, 8 + (breite + 1) // 2):
            z[(c, r)] = art == KAFFEE
    return z


Z = zellen()
C0, C1 = min(c for c, _ in Z), max(c for c, _ in Z)
R0, R1 = min(r for _, r in Z), max(r for _, r in Z)
# Teilung aus dem tatsaechlich belegten Feld: die Form sitzt mittig und fuellt
# die Flaeche, egal wie die Zeichnung sich noch aendert.
TEILUNG = (KANTE - 2 * RAND) / (max(C1 - C0, R1 - R0) + 0.6)
D = TEILUNG * 0.6
BREIT, HOCH = (C1 - C0 + 0.6) * TEILUNG, (R1 - R0 + 0.6) * TEILUNG


def mitte(c, r):
    return ((KANTE - BREIT) / 2 + D / 2 + (c - C0) * TEILUNG,
            (KANTE - HOCH) / 2 + D / 2 + (r - R0) * TEILUNG)


def punkte(farben):
    return [(*mitte(c, r), farben["akzent"] if kaffee else farben["ink"])
            for (c, r), kaffee in sorted(Z.items(), key=lambda p: (p[0][1], p[0][0]))]


def png(pfad, farben):
    from PIL import Image, ImageDraw
    ueber = 4                                 # Ueberabtastung statt Kantenglaettung
    grund = farben["grund"] or (0, 0, 0, 0)
    bild = Image.new("RGBA", (KANTE * ueber,) * 2, grund)
    stift = ImageDraw.Draw(bild)
    for x, y, farbe in punkte(farben):
        stift.ellipse([(x - D / 2) * ueber, (y - D / 2) * ueber,
                       (x + D / 2) * ueber, (y + D / 2) * ueber], fill=farbe)
    bild = bild.resize((KANTE, KANTE), Image.LANCZOS)
    if farben["grund"]:
        bild = bild.convert("RGB")
    bild.save(pfad)


def svg(farben):
    kreise = "\n".join(
        f'  <circle cx="{x:.2f}" cy="{y:.2f}" r="{D / 2:.2f}" fill="{f}"/>'
        for x, y, f in punkte(farben))
    grund = (f'  <rect width="{KANTE}" height="{KANTE}" fill="{farben["grund"]}"/>\n'
             if farben["grund"] else "")
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{KANTE}" '
            f'height="{KANTE}" viewBox="0 0 {KANTE} {KANTE}">\n{grund}{kreise}\n</svg>\n')


def main():
    ENTWURF.mkdir(parents=True, exist_ok=True)
    for name, farben in [("hell", HELL), ("dunkel", DUNKEL), ("getoent", GETOENT)]:
        png(KATALOG / f"icon-{name}.png", farben)
    (KATALOG / "Contents.json").write_text(json.dumps({
        "images": [
            {"filename": "icon-hell.png", "idiom": "universal",
             "platform": "ios", "size": "1024x1024"},
            {"appearances": [{"appearance": "luminosity", "value": "dark"}],
             "filename": "icon-dunkel.png", "idiom": "universal",
             "platform": "ios", "size": "1024x1024"},
            {"appearances": [{"appearance": "luminosity", "value": "tinted"}],
             "filename": "icon-getoent.png", "idiom": "universal",
             "platform": "ios", "size": "1024x1024"},
        ],
        "info": {"author": "xcode", "version": 1},
    }, indent=2) + "\n", encoding="utf-8")

    (ENTWURF / "icon.svg").write_text(svg(HELL), encoding="utf-8")
    (ENTWURF / "icon-punkte.json").write_text(json.dumps({
        "kante": KANTE, "durchmesser": round(D, 2), "grund": HELL["grund"],
        "punkte": [{"x": round(x - D / 2, 2), "y": round(y - D / 2, 2), "farbe": f}
                   for x, y, f in punkte(HELL)],
    }, indent=1), encoding="utf-8")
    print(f"{len(Z)} Punkte, Teilung {TEILUNG:.1f}, Punkt {D:.1f}")
    print(f"Katalog: {KATALOG.relative_to(WURZEL)}")
    print(f"Entwurf: {ENTWURF.relative_to(WURZEL)}/icon.svg")


if __name__ == "__main__":
    main()
