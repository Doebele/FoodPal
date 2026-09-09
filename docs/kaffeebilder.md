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

## Werte

Recherchiert am 9. September 2026. **Zwei Herkünfte, sauber getrennt** — was
belegt ist, ist belegt, und was gerechnet ist, steht mit seiner Rechnung da.
Erfunden ist nichts.

### Kettenkaffee — Herstellerangabe

Aus der offiziellen Tabelle *Starbucks Coffee Company · Beverage Nutrition
Information*. **Bezugsgrösse: Grande, 473 ml, 2 % Milch, mit Sahne, wo sie zum
Getränk gehört** (Mocha, White Chocolate Mocha, Pumpkin Spice Latte, Frappé).
Tall ist rund zwei Drittel davon.

| Sorte | kcal | mg |
|---|---|---|
| Caramel Macchiato | 250 | 150 |
| Vanilla Latte | 250 | 150 |
| Caffè Mocha | 360 | 175 |
| White Chocolate Mocha | 470 | 150 |
| Pumpkin Spice Latte | 390 | 150 |
| Frappé (Caramel Frappuccino) | 410 | 100 |
| Iced Latte | 130 | 150 |
| Iced Americano | 15 | 225 |
| Nitro Cold Brew | 5 | 280 |
| Cold Brew mit Süssrahm | 110 | 185 |

Zwei Dinge, die dabei auffielen: der Espresso einer Kette ist **kein**
europäischer Espresso — Starbucks rechnet mit rund 75 mg je Shot statt 63, und
eine Grande trägt zwei davon. Und der Unterschied zwischen *mit* und *ohne*
Sahne ist beim Mocha 70 kcal, beim White Chocolate Mocha ebenfalls 70. Wer die
Sorte ohne bestellt, korrigiert den Wert im Bestätigen-Schirm.

### Bausteine — für alles Übrige

| Baustein | Wert |
|---|---|
| Espresso, 25 ml | 2 kcal · 63 mg |
| Vollmilch 3,5 % | 64 kcal/100 ml |
| Kaffeerahm 15 %, Portion 12 g | 19 kcal |
| Gezuckerte Kondensmilch | 321 kcal/100 g |
| Schlagrahm, ungesüsst | 340 kcal/100 g |
| Zucker | 4 kcal/g |
| Whiskey 40 % vol, 40 ml | 90 kcal |
| Vanilleeis | 200 kcal/100 g |
| Tonic Water | 35 kcal/100 ml |
| Türkischer Kaffee, 60 ml | 51–60 mg (Studie Ege-Universität, 858 mg/l) |
| Phin-Kaffee, Robusta, 70 ml | 80–130 mg |

### Schweiz und Exoten — gerechnet

| Sorte | kcal | mg | Rechnung |
|---|---|---|---|
| Kaffee Crème | 20 | 80 | 110 ml Kaffee + eine Portion Kaffeerahm |
| Schale | 80 | 80 | 120 ml Kaffee + 120 ml Vollmilch |
| Türkischer Mokka | 20 | 55 | 60 ml, *orta* — mit einem Teelöffel Zucker |
| Barraquito | 105 | 63 | Espresso + 20 g Kondensmilch + 60 ml Milch |
| Café Bombón | 80 | 63 | Espresso + 25 g Kondensmilch |
| Marocchino | 30 | 63 | Espresso + 2 g Kakao + 30 ml Milchschaum |
| Einspänner | 105 | 126 | doppelter Espresso + 30 ml Schlagrahm |
| Wiener Melange | 55 | 63 | Espresso + 60 ml Milch + Schaum |
| Café au Lait | 100 | 95 | 150 ml Filterkaffee + 150 ml Vollmilch |
| Carajillo | 50 | 63 | Espresso + 20 ml Brandy |
| Irish Coffee | 225 | 80 | Kaffee + 40 ml Whiskey + Zucker + 30 ml Schlagrahm |
| Affogato | 100 | 63 | Espresso + 50 g Vanilleeis |
| Freddo Espresso | 5 | 126 | doppelter Espresso, geschüttelt, ungesüsst |
| Freddo Cappuccino | 55 | 126 | dazu 80 ml kalter Milchschaum |
| Cà phê sữa đá | 100 | 130 | Phin-Kaffee + 30 g Kondensmilch |
| Espresso Tonic | 55 | 63 | Espresso + 150 ml Tonic |

**Warum überhaupt rechnen.** Für einen Barraquito gibt es keine
Herstellerangabe, und es wird auch nie eine geben — er entsteht in einer Bar auf
Teneriffa, nicht in einer Fabrik. Die Alternative wäre, ein Modell zu fragen,
und genau das ist die Sache, die diese App nicht tut: die Zahlen zu Cola und Red
Bull stehen deshalb in `Caffeine.swift` und nicht im Prompt. Eine offengelegte
Rechnung kann man nachrechnen und korrigieren; eine geratene Zahl sieht genauso
aus und ist es nicht.

**Was jede dieser Zahlen ist: eine Standardportion, kein Messwert.** Zucker,
Sahne und Milchmenge schwanken von Haus zu Haus — der Bestätigen-Schirm steht
genau deshalb vor jedem Speichern.

### Nachtrag zum Bestand

**Der Cortado steht jetzt auf einem Doppio: 126 mg statt 63, 30 kcal statt 45.**
Die Quellen sind einig — 30 bis 40 ml Espresso auf gleich viel Milch, im Glas
von 60 bis 70 ml —, und diese Menge kommt aus einem doppelten Sieb. Die
Kalorien folgen derselben Rechnung: 4 für den Doppio, 26 für 40 ml Vollmilch.
Bestehende Einträge behalten ihre Werte; das Preset gilt für neue.

### Quellen

- Starbucks Coffee Company, *Beverage Nutrition Information* (offizielle Tabelle, Kalorien und Koffein je Grösse und Milchsorte)
- [Caffeine Informer — Complete Guide to Starbucks Caffeine](https://www.caffeineinformer.com/the-complete-guide-to-starbucks-caffeine) (Koffein je Grösse; deckt sich mit der Herstellertabelle)
- [Nitro Cold Brew, Grande: 5 kcal · 280 mg](https://www.caffeineinformer.com/caffeine-content/starbucks-nitro-cold-brew)
- [Vanilla Latte, Grande, 2 % Milch: 250 kcal](https://www.nutritionix.com/i/starbucks/vanilla-latte-with-2-milk-grande/5266a0fa9f05a39eb30076fc)
- [Pumpkin Spice Latte, Grande: 390 kcal](https://www.tasteofhome.com/article/nutrition-in-a-starbucks-pumpkin-spice-latte/)
- [Türkischer Kaffee, Koffeingehalt](https://www.caffeineinformer.com/caffeine-content/turkish-coffee) und [Studie der Ege-Universität](https://sakiproducts.com/blogs/turkish-coffee/turkish-coffee-caffeine-more-than-you-think)
- [Gezuckerte Kondensmilch, 321 kcal/100 g (USDA FoodData Central 171275)](https://tools.myfooddata.com/nutrition-facts/171275/wt1)
- [Kaffeerahm-Portion, Emmi](https://fddb.info/db/de/lebensmittel/emmi_kaffeerahm_portion/index.html)
- [Phin-Kaffee, Koffein](https://hanoidrip.coffee/blog/caffeine-in-vietnamese-coffee)

## Auf die App

**Die Warenkunde steht schon.** Jede der 14 Sorten im Bestand trägt Zutaten und
einen Satz zur Zubereitung, in fünf Sprachen (`CoffeeInfo.swift`); im
aufgespreizten Bild erscheint unten rechts ein Info-Zeichen, und ein Tipper
legt den Text als Glas darüber. Sichtbar wird das erst mit den Bildern — ohne
Bild gibt es nichts aufzuspreizen.

Die Bilder gehören als `coffee/<sorte>` in den Asset-Katalog; die Namen sind die
`rawValue` aus `CoffeeInfo` — `espresso`, `ristretto`, `doppio`, `lungo`,
`americano`, `filter`, `mokka`, `macchiato`, `cortado`, `cappuccino`, `latte`,
`latteMacchiato`, `flatWhite`, `coldBrew`. Neue Sorten brauchen dort einen Fall
mehr, samt Zutaten und Satz.


Ein Bild je Sorte, benannt nach der Sorte, in den Asset-Katalog; der
Eintragsschirm zeigt es dort, wo bei einer Mahlzeit das Foto steht. Damit trägt
**jeder** Eintrag oben rechts ein Bild — fotografiert oder mitgeliefert — und
der Weissraum links bleibt, wie er ist.

**Offen bleibt der Umfang.** Vierzig Sorten in einem Raster, das heute vierzehn
trägt und nach Häufigkeit sortiert, wird eine lange Liste. Bevor die neuen
Sorten Presets werden, braucht es eine Trennung zwischen den paar, die man
täglich tippt, und dem Rest — sonst kostet der Espresso am Morgen plötzlich
Scrollen.
