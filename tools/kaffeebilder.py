#!/usr/bin/env python3
"""Grund auf genau #FAFAF8 ziehen und auf 1400 rechnen.

Das Modell trifft den Hintergrundton nie zweimal gleich. Statt darauf zu
hoffen: den Rand messen, die drei Kanaele so skalieren, dass er auf Papier
liegt, und erst dann verkleinern. Die Tasse dreht dabei mit — sie soll ja
unter demselben Licht stehen wie der Grund.
"""
import sys
from PIL import Image

ZIEL = (0xFA, 0xFA, 0xF8)
KANTE = 1600


def grundton(im):
    """Median des Randstreifens — dort steht nur Hintergrund."""
    w, h = im.size
    r = max(2, w // 50)
    px = []
    for y in range(0, h, 4):
        px.append(im.getpixel((r, y)))
        px.append(im.getpixel((w - 1 - r, y)))
    for x in range(0, w, 4):
        px.append(im.getpixel((x, r)))
    px.sort(key=lambda c: sum(c))
    return px[len(px) * 3 // 4]  # oberes Quartil: Schatten am Rand faellt raus


def normalisieren(pfad, ziel_pfad):
    im = Image.open(pfad).convert("RGB")
    grund = grundton(im)
    faktor = [ZIEL[i] / max(grund[i], 1) for i in range(3)]
    tabelle = []
    for i in range(3):
        tabelle += [min(255, int(v * faktor[i] + 0.5)) for v in range(256)]
    im = im.point(tabelle)
    im = im.resize((KANTE, KANTE), Image.LANCZOS)
    im.save(ziel_pfad, quality=82, subsampling=1)
    return grund, grundton(Image.open(ziel_pfad).convert("RGB"))


if __name__ == "__main__":
    for pfad in sys.argv[1:]:
        ziel = pfad.rsplit(".", 1)[0] + "-1600.jpg"
        vorher, nachher = normalisieren(pfad, ziel)
        print(f"{pfad.split('/')[-1]:26s} {vorher} -> {nachher}")
