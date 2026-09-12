// CafcaLog — App-Store-Bilder (Deutsch) nach Figma importieren
//
// Ausführen in Figma:  Hauptmenü → Plugins → Development → Open Console
// → dieses Skript einfügen → Enter.
//
// Es legt auf der **aktuell offenen Seite** unterhalb des bestehenden
// Inhalts acht Rahmen (1320 × 2868, exakt die Bildmaße) an, benennt sie
// und gruppiert sie als „Store-Bilder DE · CafcaLog". Bestehende Inhalte
// werden nicht angetastet. Zwei Mal ausgeführt = doppelt vorhanden.
//
// Voraussetzung: der Bildserver lief — falls nicht:
//   python3 -m http.server 8765 --bind 127.0.0.1 --directory bilder/store/de
(async () => {
  const BILDER = [
    ["01-tagesverlauf",  "01 · Tagesverlauf"],
    ["02-koffein",       "02 · Koffein"],
    ["03-kaffee",        "03 · Kaffee-Auswahl"],
    ["04-eintrag",       "04 · Eintrag"],
    ["05-sorte",         "05 · Sorte"],
    ["06-warenkunde",    "06 · Warenkunde"],
    ["07-einstellungen", "07 · Einstellungen"],
    ["08-jetzt",         "08 · Jetzt"],
  ];
  const BASIS = "http://127.0.0.1:8765/";
  const B = 1320, H = 2868, ABSTAND = 120, PRO_ZEILE = 4;

  // Unterhalb des bisherigen Seiteninhalts beginnen — nichts überlappt.
  const kinder = figma.currentPage.children;
  let unten = 0;
  for (const k of kinder) unten = Math.max(unten, k.y + k.height);
  const offset = kinder.length ? unten + 600 : 0;

  const rahmen = [];
  for (let i = 0; i < BILDER.length; i++) {
    const [datei, titel] = BILDER[i];
    try {
      const bild = await figma.createImageAsync(BASIS + datei + ".png");
      const f = figma.createFrame();
      f.name = titel;
      f.resize(B, H);
      f.x = (i % PRO_ZEILE) * (B + ABSTAND);
      f.y = offset + Math.floor(i / PRO_ZEILE) * (H + ABSTAND);
      f.fills = [{ type: "IMAGE", scaleMode: "FILL", imageHash: bild.hash }];
      figma.currentPage.appendChild(f);
      rahmen.push(f);
    } catch (e) {
      figma.notify("✗ " + datei + " nicht geladen — läuft der Bildserver auf Port 8765?");
      throw e;
    }
  }

  const gruppe = figma.group(rahmen, figma.currentPage);
  gruppe.name = "Store-Bilder DE · CafcaLog";
  figma.viewport.scrollAndZoomIntoView(rahmen);
  figma.notify("✓ 8 Store-Bilder (de) importiert");
})();
