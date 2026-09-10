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
| **V1** | **Tazzina**, die italienische Espressotasse: klein und schwer, dickwandiges weisses Porzellan, der Körper ein Kegelstumpf, der sich zu einem kleinen massiven Fuss verjüngt, der Rand leicht ausgestellt und dick gewulstet, ein kleiner runder Ohrhenkel, durch den gerade ein Finger passt. 6 cm hoch, 60 ml |
| **V1o** | dieselbe Grösse **ohne Henkel** — der türkische *fincan*: gerade, leicht konische Wandung, dickes Porzellan, steht auf seinem Boden |
| **V2** | Tasse, 180 ml: gerader, leicht konischer Körper, kleiner runder Ohrhenkel, niedriger massiver Fuss, kein Dekor, kein Goldrand |
| **V3** | dieselbe Form in 300 ml |
| **G1** | Glas, 100 ml: gerade Wandung, dünnes klares Glas, ohne Schliff, ohne Stiel, ohne Henkel |
| **G2** | Becherglas, 250 ml, dieselbe Machart |
| **G3** | hohes Glas, 350 ml, dieselbe Machart |

Ausnahmen, wo das Gefäss die Sorte *ist*: Stielglas (Einspänner, Irish Coffee),
Schale ohne Henkel (Café au Lait), Phin-Filter (Cà phê sữa đá).

## Der Produktionsprompt

Kurz gehalten: was Flux nachweislich befolgt, steht drin, der Rest ist Ballast.
Nur die `SUBJECT`-Zeile wechselt.

```
CAMERA 25 degrees above the rim plane, vessel upright and square to camera,
base in frame. SUBJECT: {{DRINK}}. GROUND: one flat warm off-white tone
#FAFAF8, empty in every direction, no horizon, no gradient, no visible
surface. LIGHT: one large soft light from the upper left; exactly one soft
shadow, on the ground to the lower right, about one vessel-width long, fading
out. Matte throughout, no gloss, no reflection, no rim light. 85mm, whole
vessel sharp, centred, alone in frame. Palette: off-white, near-black, roasted
brown. Quiet Braun-catalogue product photography, blank undecorated surfaces.
```

**Warum 25° und nicht 10°.** Bei 10° liegt der Rand als schmale Ellipse da und
vom Getränk sieht man nichts — beim Ristretto, der nur zu einem Drittel steht,
gar nichts. 25° schaut weit genug hinein, dass die Fläche liest, und lässt dem
Gefäss seine Silhouette. Bei 32° wird die Tasse gedrungen; nachgemessen an
genau diesen drei Fassungen.

**Vier Varianten je Sorte, eine wird genommen.** Nicht weil das Modell schlecht
wäre, sondern weil es bei Schatten und Schaum streut — und der Satz lebt davon,
dass alle vierzig dieselbe Hand haben.

## Reihenfolge, damit der Satz ein Satz wird

**Ein Hero je Gefäss, nicht einer für alles.** Das ist am zweiten Durchgang
gelernt: eine Referenz überträgt Kamera, Licht und Grund tadellos — und
**überschreibt das Gefäss**. Mit einer Tasse als Referenz kamen Barraquito und
Vanilla Latte, die in Gläsern stehen, als dieselbe Tasse zurück; die Anweisung
im Text half nicht. Also:

1. Je Gefäss aus der Tabelle **einen Hero erzeugen**, jeweils in mehreren
   Anläufen, bis Form, Winkel und Schatten sitzen. Sieben Bilder, die den
   ganzen Satz tragen.
2. Jede Sorte dann aus **ihrem** Hero, mit ihm als Referenz: „Match the
   reference exactly … only the drink changes."
3. Seed festhalten, wo die Fassung ihn hergibt, und je Gruppe in einer
   Sitzung erzeugen.
4. Am Ende alle nebeneinander ansehen, nicht einzeln. Was auffällt, fällt nur
   im Vergleich auf.

**Positiv beschreiben, nicht verneinen.** Das ist der zweite harte Befund:
`no text, no logo, no print` wurde dreimal überlesen — eine Tasse trug am Ende
„kaffee", eine andere einen erfundenen Röstereinamen, eine dritte bekam den
ausdrücklich ausgeschlossenen Goldrand. Was hilft, ist die Fläche zu
**beschreiben**, statt ihren Inhalt zu verbieten: *„its whole surface is one
uniform plain white glaze from rim to foot, blank and undecorated"* — damit kam
die Tazzina auf Anhieb blank. Dieselbe Regel gilt für alles, was fehlen soll:
lieber „empty in every direction" als „no table, no edge, no horizon".

**Rechne mit zwei bis drei Anläufen je Sorte.** Von acht Bildern des dritten
Durchgangs waren fünf brauchbar; von vier Tazzina-Versuchen einer. Für vierzig
Sorten heisst das rund hundert Erzeugungen und eine Sichtung — nicht vierzig.

**Der Kamerastand gehört nach vorn.** Hinten im Prompt wird er überlesen —
vier von sechs Bildern kamen von oben. In Grossbuchstaben und als erster Satz
(`SIDE VIEW AT CUP HEIGHT …`) sass er auf Anhieb bei allen vieren.

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

### Kaffee mit Schnaps

| Sorte | `{{DRINK}}` |
|---|---|
| Schümli Pflümli | a schümli pflümli in a warmed stemmed glass, light brown coffee filling it to a finger below the rim, a thick dome of whipped cream on top, a light dusting of cocoa |
| Kafi Fertig | a kafi fertig in a small straight coffee glass with a handle, the coffee so pale and thin that the sugar cubes at the bottom show through it, no cream, no foam |
| Café Baileys | a café baileys in a warmed stemmed glass, pale caramel coffee below, a layer of half-whipped cream floating on top, a light dusting of cocoa |

Für alle drei gilt: **keine Flasche, kein Etikett, kein Markenzeichen im Bild** —
das Getränk steht allein, wie bei allen anderen.

---

## Erster Durchgang, und was er zeigte

Sechs Bilder mit **Soul v2** (Higgsfield), 2048 × 2048, aus den Prompts oben:
Espresso, Türkischer Mokka, Barraquito, Vanilla Latte, Wiener Melange, Kaffee
Crème. Was daraus zu lernen war:

**Was hält:** Palette, Licht und Leere. Kein Requisit, keine Bohne, kein Dampf,
kein Löffel — die Negativliste greift. Der Barraquito kam auf Anhieb richtig,
mit vier Bändern und Zimtstaub.

**Was nicht hält — und das ist der eigentliche Befund:**

- **Der Kamerastand wird überlesen.** „Eye level, tilted 10°" stand in jedem
  Prompt; vier von sechs Bildern kamen von oben, eins schräg. Aus Text allein
  entsteht kein Satz.
- **Das Geschirr wechselt von Bild zu Bild.** Genau dagegen war die
  Gefäss-Tabelle gedacht — sie wirkt nur als **Referenzbild**, nicht als Wort.
- **„No text" reicht nicht.** In einer Tasse stand am Ende „kaffee".
- **Der Grund ist nicht immer nahtlos**; in drei Bildern schneidet eine Kante
  durchs Feld.

**Folgerung: die Reihenfolge in dieser Akte ist nicht Zierat, sondern die
halbe Miete.** Ein Hero-Bild, das sitzt, dann alle weiteren mit ihm als
Stilreferenz — was Soul aus Text nicht zuverlässig nimmt, nimmt es aus einem
Bild. Für den zweiten Durchgang also: den Espresso so lange wiederholen, bis
Tasse, Winkel und Schatten stimmen, und ihn danach jedem weiteren Prompt als
Referenz mitgeben.

## Das Modell: Flux 2, nicht Soul

Vier Modelle, zwei Motive, derselbe Prompt — Espresso in der Tazzina und
Vanilla Latte im hohen Glas, weil das Gefäss, der Schatten und der Grund
zusammen die Probe sind.

| Modell | Gefäss | Schatten | Grund | Credits/Bild |
|---|---|---|---|---|
| **Flux 2 pro** | **beide richtig** | **weich, kurz, rechts unten** | warm, gleichmässig | 1,00 |
| Recraft V4.1 utility | Tasse verfehlt, Glas gut | weich | sehr sauber, aber **kühl** | 1,25 |
| Soul 2 | brauchbar | **hart, schwarz** | Fleck in der Ecke | 0,12 |
| Seedream 4.5 | gut | **hart, lang, diagonal** | **Verlauf**, dunkle Ecke | 1,00 |

**Flux 2 pro** nimmt als einziges alle drei Angaben gleichzeitig an. Recraft
setzt den Hintergrund über einen **Parameter** (`background_color`) statt über
den Prompt — technisch der sauberste Weg, nur trifft es die Gefässe nicht und
rendert kühl statt warm. Soul ist achtmal billiger, liefert aber harte
Schlagschatten und Flecken im Grund; für vierzig Bilder aus einer Hand
zu unruhig.

## Der Grund wird nicht erzeugt, er wird gezogen

Kein Modell trifft `#FAFAF8` zweimal gleich — Flux lag bei (241, 233, 218),
(247, 237, 218), Seedream hatte eine Ecke bei (73, 58, 35). Darauf zu hoffen
ist der falsche Weg: **`tools/kaffeebilder.py`** misst den Randstreifen, nimmt
sein oberes Quartil (damit ein Schatten am Rand nicht mitzählt) und skaliert
die drei Kanäle so, dass der Grund auf Papier landet. Die Tasse dreht mit —
sie soll ja unter demselben Licht stehen wie ihr Grund. Danach auf **1600 px**.

```bash
python3 tools/kaffeebilder.py bild.png    # -> bild-1600.jpg
```

**Warum 1600.** Aufgespreizt läuft das Bild über die volle Breite: auf einem
iPhone 17 Pro Max sind das 440 pt, also **1320 px** auf @3x. 1600 gibt gut ein
Fünftel Reserve und wiegt rund 285 kB — vierzig Sorten also **etwa 10 MB** im
Bündel.

## Stand der Produktion

**Alle 43 Sorten erzeugt, je vier Varianten — 172 Bilder.** Flux 2 pro, 25°,
Grund auf `#FAFAF8` gezogen, 1600 px, rund 285 kB je Bild.

Die Trefferquote lag mit dem endgültigen Prompt bei nahezu vier von vier: der
Satz hält Gefäss, Winkel, Licht und Schatten über alle Sorten durch. Was jetzt
noch fehlt, ist die **Auswahl** — eine Variante je Sorte — und die Ablage als
`coffee/<sorte>` im Asset-Katalog.

Ausgewählt wird nach drei Dingen, in dieser Reihenfolge: **kurzer weicher
Schatten** (ein paar Varianten werfen einen langen harten), **blankes Gefäss**
ohne Dekor, und **das Getränk muss lesbar sein** — beim Ristretto die Tiefe,
beim Kafi Fertig die durchscheinenden Zuckerwürfel, beim Barraquito die vier
Bänder.

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
| Obstbrand 40 % vol, 2 cl | 44 kcal |
| Irish Cream, 17 % vol, 4 cl | 131 kcal |
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
| Schümli Pflümli | 130 | 80 | Kaffee + 2 cl Pflümli + 1 TL Zucker + 20 ml Schlagrahm |
| Kafi Fertig | 95 | 40 | dünner Kaffee + 3 Würfelzucker + 2 cl Träsch |
| Café Baileys | 200 | 80 | Kaffee + 4 cl Irish Cream + 20 ml Schlagrahm |

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

### Makros — dieselben Rezepte, dieselbe Rechnung

Kalorien und Koffein standen zuerst; Eiweiss, Kohlenhydrate und Fett kamen am
10. September 2026 dazu. **Keine zweite Recherche**: die Kettenkaffees bringen
ihre Makros aus derselben Herstellertabelle mit, alles Übrige entsteht aus den
Rezepten, die oben schon die Kalorien tragen. Was fehlte, waren nur die
Nährwertspalten der Bausteine.

| Baustein | kcal | Eiweiss | KH | Fett |
|---|---|---|---|---|
| Vollmilch 3,5 %, 100 ml | 64 | 3,3 | 4,8 | 3,6 |
| Filterkaffee, 100 ml | 2 | 0,1 | 0,3 | – |
| Kaffeerahm 15 %, Portion 12 g | 19 | 0,3 | 0,5 | 1,8 |
| Gezuckerte Kondensmilch, 100 g | 321 | 7,9 | 54,4 | 8,7 |
| Schlagrahm 35 %, 100 ml | 333 | 2,1 | 2,8 | 35,3 |
| Irish Cream, 100 ml | 327 | 3,0 | 24,9 | 13,0 |
| Vanilleeis, 100 g | 200 | 3,5 | 23,6 | 11,0 |
| Tonic Water, 100 ml | 35 | – | 8,8 | – |
| Kakaopulver, 100 g | 228 | 19,6 | 57,9 | 13,7 |
| Zucker, 1 g | 4 | – | 1,0 | – |
| Obstbrand und Whiskey, 40 % vol | 2,25/ml | – | – | – |

**Unter einem Gramm steht keine Zahl.** Ein Espresso trägt 0,86 g Kohlenhydrat.
Als „1 g" hingeschrieben wäre das eine Genauigkeit, die eine Standardportion
nicht hat — und in der Tagessumme Rauschen. Sorten ohne jede Angabe sind
deshalb Espresso, Filterkaffee, Lungo, Americano, Ristretto, Doppio, Mokka, Cold Brew, Nitro Cold Brew, Carajillo, Freddo Espresso: schwarzer Kaffee, sonst nichts.

| Sorte | kcal | Eiweiss | KH | Fett | Herkunft |
|---|---|---|---|---|---|
| Cappuccino | 74 | 4 | 6 | 4 | gerechnet |
| Kaffee Crème | 20 | – | – | 2 | gerechnet |
| Caffè Latte | 135 | 7 | 10 | 8 | gerechnet |
| Flat White | 155 | 8 | 12 | 9 | gerechnet |
| Macchiato | 13 | – | 1 | – | gerechnet |
| Cortado | 30 | 1 | 3 | 2 | gerechnet |
| Latte Macchiato | 120 | 6 | 9 | 7 | gerechnet |
| Schale | 80 | 4 | 6 | 4 | gerechnet |
| Wiener Melange | 55 | 3 | 4 | 3 | gerechnet |
| Café au Lait | 100 | 5 | 8 | 5 | gerechnet |
| Espresso Tonic | 55 | – | 14 | – | gerechnet |
| Iced Latte | 130 | 8 | 13 | 5 | Herstellertabelle |
| Iced Americano | 15 | 1 | 3 | – | Herstellertabelle |
| Cold Brew Süssrahm | 110 | 1 | 14 | 6 | Herstellertabelle |
| Caramel Macchiato | 250 | 10 | 35 | 7 | Herstellertabelle |
| Vanilla Latte | 250 | 12 | 37 | 6 | Herstellertabelle |
| Caffè Mocha | 360 | 14 | 43 | 15 | Herstellertabelle |
| White Chocolate Mocha | 470 | 15 | 62 | 19 | Herstellertabelle |
| Pumpkin Spice Latte | 390 | 14 | 52 | 14 | Herstellertabelle |
| Frappé | 410 | 5 | 64 | 15 | Herstellertabelle |
| Türkischer Mokka | 20 | – | 4 | – | gerechnet |
| Barraquito | 105 | 4 | 14 | 4 | gerechnet |
| Café Bombón | 80 | 2 | 14 | 2 | gerechnet |
| Marocchino | 30 | 1 | 3 | 1 | gerechnet |
| Einspänner | 105 | – | 2 | 11 | gerechnet |
| Irish Coffee | 225 | – | 9 | 11 | gerechnet |
| Affogato | 100 | 2 | 12 | 6 | gerechnet |
| Freddo Cappuccino | 55 | 3 | 5 | 3 | gerechnet |
| Cà phê sữa đá | 100 | 2 | 17 | 3 | gerechnet |
| Schümli Pflümli | 130 | – | 5 | 7 | gerechnet |
| Kafi Fertig | 95 | – | 12 | – | gerechnet |
| Café Baileys | 200 | 2 | 11 | 12 | gerechnet |

**Die Gegenprobe, und was sie ans Licht brachte.** Eiweiss und Kohlenhydrate
tragen 4 kcal je Gramm, Fett 9 — die Summe muss die hinterlegte Kalorienzahl
treffen. Sie tat es überall auf ein paar Kilokalorien genau, **ausser bei fünf
Sorten**: Carajillo, Irish Coffee, Schümli Pflümli, Kafi Fertig, Café Baileys.

Das ist kein Fehler, sondern der Beweis, dass die Rechnung greift: **Alkohol
trägt 7 kcal je Gramm und ist weder Eiweiss noch Kohlenhydrat noch Fett.** Die
Lücken waren exakt die Schnapsmengen — 45 kcal für 2 cl Brand, 90 für 4 cl
Whiskey, 38 für den Alkohol in 4 cl Irish Cream. Bei einem Irish Coffee bleiben
damit zwei Fünftel der Kalorien ausserhalb der Makros, und das ist richtig so.

Eine Zahl hat die Probe tatsächlich korrigiert: beim **Kafi Fertig** blieben
nach dem Alkohol noch 12 kcal offen. Drei Schweizer Würfelzucker sind **4 g**,
nicht 3 — 12 g statt 9, und die Lücke schloss sich auf null.

`CoffeeMacroTests` hält beides fest: keine Sorte trägt mehr Makros als
Kalorien, und was keinen Alkohol enthält, ist zu mindestens 85 % durch seine
Makros erklärt. Welche Sorten Alkohol enthalten, liest der Test aus
`CoffeeInfo.ingredients` — die Warenkunde prüft damit die Nährwerttabelle.

### Nachtrag zum Bestand

**Kafi Fertig und Kafi Luz sind dasselbe Getränk** — in Luzern heisst es Kafi
Luz oder Träschkaffee, in Bern Kafi Fertig, andernorts Cheli. Es steht deshalb
**einmal** im Bestand, und die Warenkunde nennt die anderen Namen. Zwei Presets
mit identischen Werten wären eine Sorte zu viel.

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
- [Kafi Luz und Kafi Fertig — Herkunft und Regel](https://www.drinkdirect.ch/de/blog/trends/kafi-luz-herkunft-rezept-zubereitung), [Volg-Rezept](https://www.volg.ch/dorfplatz/rezepte/artikel/kafi-fertig/)
- [Schümli Pflümli, Rezept](https://www.gutekueche.ch/schuemli-pfluemli-rezept-12483)
- [Irish Cream, 327 kcal/100 ml](https://www.nutritionix.com/food/baileys-irish-cream), [Zubereitung](https://www.diageobaracademy.com/de-de/home/entdecke-alle-rezepte/baileys-coffee)

## Auf die App

**Die Warenkunde steht schon.** Jede der 14 Sorten im Bestand trägt Zutaten und
einen Satz zur Zubereitung, in fünf Sprachen (`CoffeeInfo.swift`); im
aufgespreizten Bild erscheint unten rechts ein Info-Zeichen, und ein Tipper
legt den Text als Glas darüber. Sichtbar wird das erst mit den Bildern — ohne
Bild gibt es nichts aufzuspreizen.

## Vom Kandidaten zum Asset

Vier Fassungen je Sorte liegen in `bilder/kaffee/` als `sorte-1` bis `sorte-4`.
Sie sind nicht im Repository — 35 MB Auswahlmaterial, von dem ein Viertel
bleibt. Gewählt wird von Hand, notiert wird in einer Zeile:

```
python3 tools/kaffeebilder_auswahl.py     # liest tools/kaffeeauswahl.txt
```

Das Skript legt jede gewählte Datei als `Assets.xcassets/coffee/<name>.imageset`
ab. Der Name entsteht aus dem Sortennamen: Akzente weg, Leerzeichen weg, alles
klein — „Caffè Latte" wird `caffelatte`. Die Sortennamen liest es aus
`Entry.swift`, damit es keine zweite Liste gibt.

**Derselbe Name entsteht zweimal**, einmal in Python beim Ablegen und einmal in
`CoffeeInfo.fold` beim Suchen. Laufen die beiden Faltungen auseinander, findet
die App nichts und zeigt es nicht an — ein Fehler, der sich nicht meldet.
`CoffeeImageTests` prüft deshalb die vier Namen, an denen sie auseinanderlaufen
könnten: `Caffè Latte`, `Café Bombón`, `Cold Brew Süssrahm` und `Cà phê sữa đá`.

Das `đ` ist der interessante Fall. Es sieht aus wie ein d mit Strich, ist aber
ein eigener Buchstabe — Foundations `diacriticInsensitive` lässt es deshalb
stehen, wo es `è` und `ó` glattzieht. Es wird vorher ersetzt, sonst hiesse die
Datei `caphesuađa`.

**Das Bild hängt am Namen, nicht an der Warenkunde.** `CoffeeInfo.image(for:)`
ist statisch und nimmt einen String, statt an der Aufzählung zu hängen — das
war nötig, solange es Bilder für 43 Sorten gab und Warenkunde für siebzehn.
Inzwischen decken beide alle 43 ab, aber die Trennung bleibt richtig: eine neue
Sorte kann ihr Bild schon haben, bevor jemand ihren Text geschrieben hat. Wer
sie dann öffnet, sieht das Bild und keine Karte.
