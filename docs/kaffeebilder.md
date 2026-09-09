# Bilder für die Kaffeesorten

Mahlzeiten tragen ein Foto, Kaffee trägt bisher nichts — im Eintrag bleibt der
Platz oben rechts leer. Diese Akte beschreibt, wie dieser Platz gefüllt wird:
**ein Bild je Sorte**, alle aus einer Hand, alle im Satz der App.

Erzeugt werden sie mit Higgsfield (Soul). Die Prompts stehen auf **Englisch** —
die Modelle antworten darauf genauer als auf Deutsch.

---

## Das Format

Das Bild sitzt in der rechten Spalte, dort wo beim Eintrag das Foto steht:
**213 × 220 pt** im Eintrag, **212 × 212 pt** beim Bestätigen. Also **1 : 1**,
gerechnet auf 636 px (212 @3×). Erzeugen in der höchsten Auflösung, die
Higgsfield hergibt, dann auf **640 × 640** herunterrechnen und als JPEG bei
Qualität 80 ablegen — rund 80 kB je Bild, bei 40 Sorten gut 3 MB im Bündel.

**Der Grund ist Papier**, `#FAFAF8`. Das hat einen Grund über die Einheit
hinaus: im Hellmodus **löst sich das Bild in der Seite auf**, und stehen bleibt
nur die Tasse mit ihrem Schatten. Im Dunkelmodus wird daraus eine helle Karte —
so verhält sich ein Foto, und die Mahlzeitenfotos tun dasselbe. Wer es lieber
umgekehrt hätte, tauscht im Stilblock `#FAFAF8` gegen `#161614`; dann
verschwindet die Karte dunkel und leuchtet hell. Beides ist stimmig, gemischt
ist es das nicht — **eine** Entscheidung für alle vierzig Bilder.

## Das Gefäss ist die Klammer

Was einen Satz zusammenhält, ist nicht der Prompt, sondern das **Geschirr**.
Sechs Gefässe, mehr nicht; jede Sorte verweist auf eines davon:

| | Gefäss |
|---|---|
| **V1** | Espressotasse, 60 ml, dickwandig, mattes warmweisses Porzellan, gerade Wandung, kleiner Henkel, kein Dekor, kein Goldrand |
| **V2** | Tasse, 180 ml, dieselbe Familie |
| **V3** | Grosse Tasse, 300 ml, dieselbe Familie |
| **G1** | Glas, 90 ml, dünnwandig, gerade, ungeschliffen |
| **G2** | Becherglas, 250 ml, dieselbe Familie |
| **G3** | Hohes Glas, 350 ml, dieselbe Familie |

Ausnahmen, wo das Gefäss die Sorte *ist*: Stielglas (Einspänner, Irish Coffee),
Schale ohne Henkel (Café au Lait), Phin-Filter (Cà phê sữa đá).

## Der Stilblock

Steht **unverändert** unter jedem Prompt. Nur die erste Zeile wechselt.

```
Still-life product photograph of {{DRINK}}.

Camera straight on at eye level, tilted 10° above the rim so the surface reads
as a thin ellipse. 85 mm lens, no perspective distortion, deep focus, the whole
vessel sharp. Single vessel, centred, alone in frame.

Seamless warm off-white background, hex #FAFAF8, no horizon line, no table
edge, no surface texture. One large soft light from the upper left, gentle fill
from the right, a single soft shadow falling short to the lower right. Matte
surfaces throughout, no specular hotspots, no rim light, no reflections.

Palette limited to off-white, near-black and roasted browns between #3D1C0E and
#C9793A. No other hue anywhere.

Restrained Swiss product photography in the spirit of a 1960s Braun catalogue:
quiet, exact, unstyled, nothing decorative. Square 1:1, high resolution.
```

**Negativ**, ebenfalls unverändert:

```
text, letters, numbers, logo, branding, label, packaging, watermark, hands,
people, coffee beans, scattered grounds, spoon, saucer, napkin, plant, flower,
book, wood, marble, linen, fabric, steam, splash, drips, bokeh, vignette,
gradient backdrop, colored background, blue tint, teal, pink, neon, glare,
lens flare, tilted horizon, multiple cups, cropped vessel
```

`saucer` steht bewusst im Negativ: eine Untertasse verdoppelt die Silhouette und
macht aus vierzig ruhigen Bildern vierzig unruhige. Wo eine Sorte ohne sie
falsch aussähe, steht sie in der Zeile der Sorte — sonst nicht.

## Reihenfolge, damit der Satz ein Satz wird

1. **Espresso zuerst.** Er ist das einfachste Bild und legt Geschirr, Licht und
   Schattenlänge fest. So lange wiederholen, bis er sitzt.
2. Diesen einen als **Stilreferenz** in Higgsfield hinterlegen und für alle
   weiteren mitgeben, mittlere Gewichtung — stark genug fürs Geschirr, schwach
   genug, dass ein Glas ein Glas wird.
3. **Seed festhalten**, falls die Fassung ihn hergibt, und alles in *einer*
   Sitzung erzeugen. Ein Modellwechsel zwischendurch bricht den Satz.
4. Am Ende alle vierzig **nebeneinander** ansehen, nicht einzeln. Was auffällt,
   fällt nur im Vergleich auf: eine Tasse zu gross, ein Schatten zu lang.

---

## Die Sorten

`{{DRINK}}` je Zeile einsetzen. Die Angabe zum Füllstand ist nicht Zierrat —
sie unterscheidet Ristretto von Espresso und Lungo von Americano.

### Im Bestand (14)

| Sorte | `{{DRINK}}` |
|---|---|
| Espresso | a single espresso in a small thick-walled matte warm-white porcelain cup (V1), filled two thirds, dense hazelnut crema with a fine ring of tiny bubbles at the edge |
| Ristretto | a ristretto in the same small porcelain cup, filled only one third, very dark dense crema |
| Doppio | a double espresso in a slightly larger porcelain cup of the same family, filled two thirds, thick even crema |
| Lungo | a lungo in a 120 ml porcelain cup of the same family, filled three quarters, thin pale crema covering only the centre |
| Americano | an americano in a 180 ml porcelain cup, filled three quarters, black surface with a small island of pale crema in the middle |
| Filterkaffee | filter coffee in a 180 ml porcelain cup, filled three quarters, matte black surface, no crema at all |
| Macchiato | an espresso macchiato in the small porcelain cup, dark coffee with a single small dollop of white milk foam in the centre, a brown ring around it |
| Cortado | a cortado in a small straight glass (G1), exactly half dark espresso below, half steamed milk above, one clear horizontal boundary, thin foam collar |
| Cappuccino | a cappuccino in a 180 ml porcelain cup, foam level with the rim, one simple symmetric rosetta in the microfoam |
| Caffè Latte | a caffè latte in a 300 ml porcelain cup, pale milky surface, thin foam, a small rosetta |
| Latte Macchiato | a latte macchiato in a tall straight glass (G3), three clearly separated bands from bottom to top: white milk, dark coffee, white foam |
| Flat White | a flat white in a 180 ml porcelain cup, flat glossy microfoam surface level with the rim, one small tight rosetta |
| Cold Brew | cold brew in a straight tumbler (G2), deep black-brown, three clear ice cubes, no condensation droplets |
| Mokka | moka-pot coffee in a 180 ml porcelain cup, filled two thirds, near-black matte surface, no crema |

### Schweiz

| Sorte | `{{DRINK}}` |
|---|---|
| Kaffee Crème | a Swiss kaffee crème in a 180 ml porcelain cup, filled three quarters, hazelnut brown, thin even crema |
| Schale | a Swiss schale in a 300 ml porcelain cup, half coffee half steamed milk stirred together, matte light brown surface, no latte art |

### Kettenkaffee

Die Namen sind die **Gattungsnamen**, nicht die Markennamen einer Kette, und im
Negativ stehen `logo` und `branding`: die Bilder zeigen Getränke, keine Becher
einer Firma. Das ist nicht nur sauberer, es hält sie auch haltbar.

| Sorte | `{{DRINK}}` |
|---|---|
| Caramel Macchiato | a caramel macchiato in a tall glass (G3), vanilla milk below, espresso poured through it, milk foam on top with a thin caramel drizzle in a simple grid |
| Vanilla Latte | a vanilla latte in a tall glass (G3), uniform pale coffee-milk, thin foam collar |
| Caffè Mocha | a caffè mocha in a tall glass (G3), dark chocolate layer at the bottom, coffee and milk above, a dome of whipped cream dusted with cocoa |
| White Chocolate Mocha | a white chocolate mocha in a tall glass (G3), ivory coffee-milk, a dome of whipped cream, no cocoa |
| Pumpkin Spice Latte | a spiced pumpkin latte in a tall glass (G3), warm orange-brown coffee-milk, whipped cream dome, a pinch of ground spice on top |
| Frappé | a blended iced coffee in a tall glass (G3), opaque light-brown slush filling the glass, a dome of whipped cream on top, no straw, no lid |
| Iced Latte | an iced latte in a straight tumbler (G2), milk with a dark espresso swirl settling through it, three clear ice cubes |
| Iced Americano | an iced americano in a straight tumbler (G2), clear black coffee, three clear ice cubes |
| Nitro Cold Brew | a nitro cold brew in a straight tumbler (G2), very dark body with a dense pale cascading micro-foam head, no ice |
| Cold Brew mit Süssrahm | cold brew with sweet cream in a straight tumbler (G2), dark coffee with white cream falling through it in soft ribbons, three clear ice cubes |

### Exoten

| Sorte | `{{DRINK}}` |
|---|---|
| Türkischer Mokka | a Turkish coffee in a small handleless porcelain cup, filled two thirds, thick beige foam covering the whole surface, very fine grounds settled at the bottom |
| Barraquito | a barraquito in a small tall glass, four clearly separated bands from bottom to top: condensed milk, espresso, steamed milk, foam, a thin strip of lemon zest and a dusting of cinnamon on top |
| Café Bombón | a café bombón in a small straight glass (G1), two exact halves: dense condensed milk below, dark espresso above, one sharp boundary |
| Marocchino | a marocchino in a small straight glass (G1), a dusting of cocoa at the bottom, espresso above it, a cap of milk foam, cocoa dusted on top |
| Einspänner | an einspänner in a stemmed glass, black coffee below, a tall dome of whipped cream on top |
| Wiener Melange | a wiener melange in a 180 ml porcelain cup, coffee with steamed milk, a cap of milk foam, no latte art |
| Café au Lait | a café au lait in a wide handleless porcelain bowl, pale coffee filling it three quarters, matte surface |
| Carajillo | a carajillo in a small straight glass (G1), dark espresso with a thin clear layer of spirit on top |
| Irish Coffee | an irish coffee in a stemmed glass, dark coffee below, a distinct thick layer of pale cream floating on top, one sharp boundary |
| Affogato | an affogato in a small glass coupe, one scoop of vanilla ice cream with espresso poured over it, the coffee running down the sides of the scoop |
| Freddo Espresso | a freddo espresso in a straight tumbler (G2), dark coffee, a thick pale whipped coffee froth on top, clear ice cubes below |
| Freddo Cappuccino | a freddo cappuccino in a straight tumbler (G2), cold coffee below, a thick layer of cold milk foam on top, one clear boundary |
| Cà phê sữa đá | a Vietnamese iced coffee in a straight tumbler (G2), condensed milk at the bottom, dark coffee above, clear ice cubes, a small matte steel phin filter resting on the rim |
| Espresso Tonic | an espresso tonic in a straight tumbler (G2), clear tonic with fine bubbles and clear ice below, a dark espresso layer floating on top |

---

## Auf die App

Ein Bild je Sorte, benannt nach der Sorte, in den Asset-Katalog; der
Eintragsschirm zeigt es dort, wo bei einer Mahlzeit das Foto steht. Damit trägt
**jeder** Eintrag oben rechts ein Bild — fotografiert oder mitgeliefert — und
der Weissraum links bleibt, wie er ist.

Zwei Dinge, die dafür noch zu klären sind:

- **Werte.** Die neuen Sorten brauchen kcal und mg, und die kommen aus Quellen,
  nicht aus dem Modell — dieselbe Disziplin wie in `Caffeine.swift`. Bis dahin
  steht hier keine Zahl.
- **Umfang.** Vierzig Sorten in einem Raster, das heute vierzehn trägt und nach
  Häufigkeit sortiert, wird eine lange Liste. Wahrscheinlich braucht es dann
  eine Trennung zwischen den paar Sorten, die man täglich tippt, und dem Rest.
