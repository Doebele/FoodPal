#!/usr/bin/env python3
"""Die 43 Sorten fuer die Promo-Seite — aus dem Bestand der App.

Drei Quellen, ein Laufband: die Werte aus Entry.swift (CoffeePreset.all),
die Warenkunde aus CoffeeInfo.swift (Beschreibung und Herkunft) und die
gewaehlten Bilder aus tools/kaffeeauswahl.txt. Nichts wird gepflegt —
geaendert die App ihre Sorten, laeuft dieses Werkzeug erneut.

    python3 tools/websorten.py            # Bilder + Fragment erzeugen
    python3 tools/websorten.py --einbauen # Fragment in rundgang.html setzen

Erzeugt:
    web/bilder/kaffee/<slug>.jpg   — die Gewinner-Bilder, 480 px, JPEG 80
    web/sorten-fragment.html       — das Laufband als HTML-Baustein
"""
import re
import subprocess
import sys
import unicodedata
from pathlib import Path

WURZEL = Path(__file__).resolve().parent.parent
SWIFT = WURZEL / "FoodPal" / "FoodPal"

# Die sechs erzaehlten Kacheln: Schweizer Bar-Kultur, Wien und Exoten —
# Sorten, deren Geschichte man nicht erraet.
ERZAEHLT = ["Kafi Fertig", "Schümli Pflümli", "Einspänner",
            "Barraquito", "Cà phê sữa đá", "Affogato"]


def slug(name):
    """Der Bilddatei-Slug: deutsche Umlaute aufgeloest, Rest gefaltet,
    Leerzeichen zu Bindestrichen — so heissen die Dateien in bilder/kaffee."""
    text = name.lower()
    for umlaut, klar in [("ä", "ae"), ("ö", "oe"), ("ü", "ue"), ("ß", "ss"),
                         ("đ", "d")]:
        text = text.replace(umlaut, klar)
    text = unicodedata.normalize("NFD", text)
    text = "".join(c for c in text if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z0-9]+", "-", text).strip("-")


def werte():
    roh = (SWIFT / "Entry.swift").read_text()
    out = {}
    for name, kcal, mg in re.findall(
            r'\.init\(name: "([^"]+)", kcal: (\d+), caffeineMg: (\d+)', roh):
        out[name] = (int(kcal), int(mg))
    return out


def _lokale_strings(roh):
    """case .xyz: String(localized: "...") — Beschreibung und Herkunft."""
    fund = {}
    for case, text in re.findall(
            r'case \.(\w+):\s*\n\s*String\(localized: "((?:[^"\\]|\\.)*)"\)',
            roh):
        text = text.replace('\\u{201C}', "\u201C").replace('\\u{201D}', "\u201D")
        text = text.replace('\\"', '"')
        fund[case] = text
    return fund


def warenkunde():
    roh = (SWIFT / "CoffeeInfo.swift").read_text()
    # Der Text-Koerper und die Herkunft sind zwei Switches; nimm je den
    # ersten String je case — das ist die Beschreibung, danach der Ort.
    texte = {}
    herkunft = {}
    text_block = re.search(r"var preparation: String \{.*?switch self \{(.*?)\n    \}",
                           roh, re.S)
    origin_block = re.search(r"var origin: String\? \{.*?switch self \{(.*?)\n    \}",
                             roh, re.S)
    if text_block:
        texte = dict(re.findall(
            r'case \.(\w+):\s*\n\s*String\(localized: "((?:[^"\\]|\\.)*)"\)',
            text_block.group(1)))
    if origin_block:
        herkunft = dict(re.findall(
            r'case \.(\w+):\s*\n\s*String\(localized: "((?:[^"\\]|\\.)*)"\)',
            origin_block.group(1)))
    for map_ in (texte, herkunft):
        for key in map_:
            map_[key] = (map_[key].replace('\\u{201C}', "\u201C")
                         .replace('\\u{201D}', "\u201D").replace('\\"', '"'))
    return texte, herkunft


def case_fuer(name, roh):
    """preset → case-Name, ueber den preset-Switch."""
    treffer = re.search(
        r'case \.(\w+): "' + re.escape(name) + '"', roh)
    return treffer.group(1) if treffer else None


def bilder_waehlen():
    """Die Gewinner je Sorte aus kaffeeauswahl.txt."""
    roh = (WURZEL / "tools" / "kaffeeauswahl.txt").read_text()
    return [zeile.strip() for zeile in roh.splitlines()
            if zeile.strip() and not zeile.startswith("#")]


def fragment():
    roh_info = (SWIFT / "CoffeeInfo.swift").read_text()
    kcal_mg = werte()
    texte, herkunft = warenkunde()
    namen = [n for n in kcal_mg if n != "Espresso"]  # Espresso erzaehlt woanders
    # Erzaehlte zuerst, dann der Rest in Bestandsreihenfolge.
    folge = [n for n in ERZAEHLT if n in kcal_mg]
    folge += [n for n in kcal_mg if n not in ERZAEHLT and n != "Espresso"]
    teile = []
    for name in folge:
        s = slug(name)
        kcal, mg = kcal_mg[name]
        if name in ERZAEHLT:
            case = case_fuer(name, roh_info)
            text = texte.get(case, "")
            ort = herkunft.get(case, "")
            teile.append(f'''<li class="sorte gross">
  <figure>
    <img src="bilder/kaffee/{s}.jpg" width="480" height="480" loading="lazy"
      alt="Generiertes Bild der Sorte {name}.">
    <figcaption>
      <p class="sortenname">{name}</p>
      <p class="sortenwerte"><span class="zahl">{kcal}</span> kcal ·
        <span class="zahl roast">{mg}</span> mg</p>
      <p class="sortentext">{text}</p>
      <p class="sortenort">{ort}</p>
    </figcaption>
  </figure>
</li>''')
        else:
            teile.append(f'''<li class="sorte">
  <figure>
    <img src="bilder/kaffee/{s}.jpg" width="480" height="480" loading="lazy"
      alt="Generiertes Bild der Sorte {name}.">
    <figcaption>
      <p class="sortenname">{name}</p>
      <p class="sortenwerte"><span class="zahl">{kcal}</span> ·
        <span class="zahl roast">{mg}</span> mg</p>
    </figcaption>
  </figure>
</li>''')
    return "\n".join(teile)


def main():
    einbauen = "--einbauen" in sys.argv
    if not einbauen:
        ziel = WURZEL / "web" / "bilder" / "kaffee"
        ziel.mkdir(parents=True, exist_ok=True)
        for name in bilder_waehlen():
            quelle = WURZEL / "bilder" / "kaffee" / f"{name}.jpg"
            ohne_wahl = re.sub(r"-\d+$", "", name)
            ausgabe = ziel / f"{ohne_wahl}.jpg"
            if not quelle.exists():
                print("  fehlt:", quelle.name)
                continue
            subprocess.run(["sips", "--resampleWidth", "480",
                            "-s", "formatOptions", "80",
                            str(quelle), "--out", str(ausgabe)],
                           capture_output=True, check=True)
        print(f"  {len(list(ziel.glob('*.jpg')))} Bilder in web/bilder/kaffee/")
    fragment_text = fragment()
    (WURZEL / "web" / "sorten-fragment.html").write_text(fragment_text)
    print(f"  sorten-fragment.html ({len(fragment_text) // 1024} kB)")
    if einbauen:
        seite = WURZEL / "web" / "rundgang.html"
        roh = seite.read_text()
        neu = re.sub(r"(<!--sorten-start-->).*?(<!--sorten-ende-->)",
                     lambda m: m.group(1) + "\n" + fragment_text + "\n  "
                     + m.group(2), roh, flags=re.S)
        seite.write_text(neu)
        print("  sorten eingebaut in", seite.relative_to(WURZEL))


if __name__ == "__main__":
    main()
