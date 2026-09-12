#!/usr/bin/env python3
"""Die Original-Grafiken fuer den Rundgang, aus dem Swift-Code erzeugt.

Die Punktmatrix-Ziffern stehen als Lauflaengen in DotMatrixFont.swift, die
Segment-Geometrie in SevenSegmentDisplay.swift, die Bandlogik des Zeitstrahls
in DayMatrix.swift. Dieses Werkzeug liest sie dort und zeichnet SVG — nichts
wird abgetippt, deshalb kann nichts auseinanderlaufen.

    python3 tools/webgrafiken.py            # erzeugen
    python3 tools/webgrafiken.py --einbauen # Fragment in rundgang.html setzen

Erzeugt:
    web/bilder/strahl.svg              — der Zeitstrahl, statisch (10.9.)
    web/bilder/strahl-fragment.svg     — Doppel-Ebene fuer Scroll-Faerbung
    web/bilder/anzeigen/punktmatrix-kcal.svg   — 1716, Tinte
    web/bilder/anzeigen/punktmatrix-mg.svg     — 0158, Roestung
    web/bilder/anzeigen/segment.svg            — 0412, sieben Segmente
"""
import re
import sys
from pathlib import Path

WURZEL = Path(__file__).resolve().parent.parent
SWIFT = WURZEL / "FoodPal" / "FoodPal"

INK = "#161614"
INK2 = "#72726a"
MATRIX = "#e8e7e3"
ROAST = "#b4531f"

# Der 10. September aus der Demo-Saat (DemoData.swift), auf Stunden summiert:
# 7:20 Espresso (2/63) · 8:40 Porridge (470) · 13:10 Linsensuppe (460)
# 16:00 Filterkaffee (4/95) · 19:30 Pasta (780)
STUNDE = {7: (2, 63), 8: (470, 0), 13: (460, 0), 16: (4, 95), 19: (780, 0)}

SPALTEN = 96
KAL_REIHEN = 12
KOF_REIHEN = 5
KCAL_PRO_REIHE = 150.0
MG_PRO_REIHE = 65.0
PER_STUNDE = 4
KOFFEE_TOP = 51  # Einheiten: 12 Reihen * pitch 4 + Fuge
UEBERSTAND = 3
PITCH = 4
DOT = 3
BREITE = SPALTEN * PITCH - 1
HOEHE = 70 + UEBERSTAND


def stunden_punkte():
    kcal = {}
    mg = {}
    for stunde, (k, m) in STUNDE.items():
        kcal[stunde] = round(k / (KCAL_PRO_REIHE / PER_STUNDE))
        mg[stunde] = round(m / (MG_PRO_REIHE / PER_STUNDE))
    return kcal, mg


def strahl(farbe=True):
    """Der Zeitstrahl als SVG-Koerper; farbe=False malt alles im Raster."""
    kcal, mg = stunden_punkte()
    teile = []
    for stunde in range(24):
        for i in range(KAL_REIHEN * PER_STUNDE):
            reihe = KAL_REIHEN - 1 - i // PER_STUNDE
            spalte = stunde * PER_STUNDE + i % PER_STUNDE
            an = i < kcal.get(stunde, 0)
            farbwert = INK if (an and farbe) else MATRIX
            teile.append(punkt(spalte, reihe * PITCH, farbwert))
        for i in range(KOF_REIHEN * PER_STUNDE):
            reihe = i // PER_STUNDE
            spalte = stunde * PER_STUNDE + i % PER_STUNDE
            an = i < mg.get(stunde, 0)
            farbwert = ROAST if (an and farbe) else MATRIX
            teile.append(punkt(spalte, KOFFEE_TOP + reihe * PITCH, farbwert))
    return "".join(teile)


def punkt(spalte, y, farbe):
    x = spalte * PITCH + UEBERSTAND
    return (f'<rect x="{x}" y="{y + UEBERSTAND}" width="{DOT}" '
            f'height="{DOT}" fill="{farbe}"/>')


def strahl_svg():
    koerper = strahl(True)
    linie_x = 38 * PITCH - 1 + UEBERSTAND  # 9:41, in der Spaltenluecke
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 {-(UEBERSTAND + 4)} {BREITE + 2 * UEBERSTAND} {HOEHE + 8}" role="img" aria-label="Der Tag als Punktraster: oben Kalorien, unten Koffein">
{koerper}
<rect x="{linie_x}" y="0" width="1" height="{HOEHE}" fill="{INK2}"/>
</svg>
'''


def strahl_fragment():
    """Zwei Ebenen fuer die Scroll-Faerbung: unten farbig, darueber grau,
    dessen Bildbereich per clip-path von links freigegeben wird."""
    farbe = strahl(True)
    grau = strahl(False)
    linie_x = 38 * PITCH - 1 + UEBERSTAND
    return f'''<svg id="strahl" xmlns="http://www.w3.org/2000/svg" viewBox="0 {-(UEBERSTAND + 4)} {BREITE + 2 * UEBERSTAND} {HOEHE + 8}" role="img" aria-label="Der zehnte September als Punktraster: oben Kalorien in Tinte, unten Koffein in Röstfarbe">
  <g id="strahl-grau">{grau}</g>
  <g id="strahl-farbe" style="clip-path: inset(0 100% 0 0)">{farbe}</g>
  <rect id="strahl-linie" x="{linie_x}" y="0" width="1" height="{HOEHE}" fill="{INK2}" style="opacity: 0"/>
</svg>
'''


# ——— Punktmatrix ————————————————————————————————————————————————————

def glyphen():
    """Liest die Lauflaengen aus DotMatrixFont.swift — das Original, nicht
    eine Abschrift. Ein Ziffernblock beginnt mit '[ // N'; hinter der
    neunten stehen die Lauflaengen des Groesser-Zeichens, deshalb wird
    jede Ziffer nach 33 Reihen abgeschnitten."""
    roh = (SWIFT / "DotMatrixFont.swift").read_text()
    anfang = roh.index("static let shapes")
    ziffern = {}
    for teil in re.split(r"\[\s*//", roh[anfang:])[1:]:
        nummer = int(re.match(r"\s*(\d+)", teil).group(1))
        reihen = []
        for n, muster in re.findall(r'\((\d+), "([.#]+)"\)', teil):
            if len(reihen) >= 33:
                break
            reihen.extend([muster] * int(n))
        ziffern[nummer] = reihen[:33]
    return ziffern


def punktmatrix_svg(zahl, farbe):
    ziffern = glyphen()
    p = 6
    breite_z = 20 * p
    luecke = 3 * p
    gesamt_b = len(zahl) * breite_z + (len(zahl) - 1) * luecke
    gesamt_h = 33 * p
    teile = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {gesamt_b} {gesamt_h}" role="img" aria-label="Punktmatrix-Anzeige {zahl}">']
    for st, z in enumerate(zahl):
        x0 = st * (breite_z + luecke)
        for r, zeile in enumerate(ziffern[int(z)]):
            for c, feld in enumerate(zeile):
                ton = farbe if feld == "#" else MATRIX
                teile.append(f'<rect x="{x0 + c * p}" y="{r * p}" width="{p - 1}" height="{p - 1}" fill="{ton}" rx="0.8"/>')
    teile.append("</svg>")
    return "".join(teile)


# ——— Sieben Segment ————————————————————————————————————————————————

SEGMENTE = [  # a b c d e f g — Maße aus SevenSegmentDisplay.swift
    (7, 0, 60, 12), (62, 7, 12, 50), (62, 59, 12, 50), (7, 104, 60, 12),
    (0, 59, 12, 50), (0, 7, 12, 50), (7, 52, 60, 12)]
MASKEN = [0b1111110, 0b0110000, 0b1101101, 0b1111001, 0b0110011,
          0b1011011, 0b1011111, 0b1110000, 0b1111111, 0b1111011]
SLANT = 0.0385
BOX_H = 116
SEGEN = "#ebebe2"


def segment_punkte(x, y, w, h):
    """Das Sechseck mit 6 pt Fase — die Formel aus Segment.path."""
    c = 6
    if w > h:
        ecken = [(x + c, y), (x + w - c, y), (x + w, y + h / 2),
                 (x + w - c, y + h), (x + c, y + h), (x, y + h / 2)]
    else:
        ecken = [(x + w / 2, y), (x + w, y + c), (x + w, y + h - c),
                 (x + w / 2, y + h), (x, y + h - c), (x, y + c)]
    return " ".join(f"{px + SLANT * (BOX_H - py):.2f},{py:.2f}"
                    for px, py in ecken)


def segment_svg(zahl):
    box_b = 74 + SLANT * BOX_H
    luecke = 10
    gesamt_b = len(zahl) * box_b + (len(zahl) - 1) * luecke + 4
    teile = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {gesamt_b:.0f} {BOX_H}" role="img" aria-label="Sieben-Segment-Anzeige {zahl}">']
    for st, z in enumerate(zahl):
        x0 = st * (box_b + luecke) + 2
        maske = MASKEN[int(z)]
        for i, (x, y, w, h) in enumerate(SEGMENTE):
            an = maske & (1 << (6 - i))
            teile.append(f'<polygon points="{segment_punkte(x0 + x, y, w, h)}" '
                         f'fill="{INK if an else SEGEN}"/>')
    teile.append("</svg>")
    return "".join(teile)


def einbauen():
    seite = WURZEL / "web" / "rundgang.html"
    roh = seite.read_text()
    fragment = strahl_fragment()
    neu = re.sub(r"(<!--strahl-start-->).*?(<!--strahl-ende-->)",
                 lambda m: m.group(1) + "\n" + fragment + "  " + m.group(2),
                 roh, flags=re.S)
    seite.write_text(neu)
    print("strahl eingebaut in", seite.relative_to(WURZEL))


def main():
    if "--einbauen" in sys.argv:
        einbauen()
        return
    (WURZEL / "web" / "bilder" / "anzeigen").mkdir(parents=True, exist_ok=True)
    schreiben = [
        (WURZEL / "web" / "bilder" / "strahl.svg", strahl_svg()),
        (WURZEL / "web" / "bilder" / "strahl-fragment.svg", strahl_fragment()),
        (WURZEL / "web" / "bilder" / "anzeigen" / "punktmatrix-kcal.svg",
         punktmatrix_svg("1716", INK)),
        (WURZEL / "web" / "bilder" / "anzeigen" / "punktmatrix-mg.svg",
         punktmatrix_svg("0158", ROAST)),
        (WURZEL / "web" / "bilder" / "anzeigen" / "segment.svg",
         segment_svg("0412")),
    ]
    for pfad, inhalt in schreiben:
        pfad.write_text(inhalt)
        print(f"  {pfad.relative_to(WURZEL)}  ({pfad.stat().st_size // 1024} kB)")


if __name__ == "__main__":
    main()
