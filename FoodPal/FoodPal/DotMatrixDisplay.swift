import SwiftUI

/// Die Tagessumme als Punktmatrix — im **selben Raster wie der Zeitstrahl**.
///
/// Das ist der Grund, warum diese Darstellung anders sitzt als Flip und
/// 7-Segment: sie ist keine Schrift auf einer Fläche, sondern dieselben
/// 96 Spalten, nur mit anderen Punkten beleuchtet. Deshalb läuft sie wie das
/// Diagramm bis an den Rand.
///
/// Die Ziffern stehen **rechtsbündig**, links wird mit leeren Rasterspalten
/// aufgefüllt — rechts bleiben zwei stehen, damit die letzte Ziffer nicht an
/// der Kante klebt:
///
/// ```
/// 11 Füller │ 20 Ziffer │ 1 │ 20 │ 1 │ 20 │ 1 │ 20 │ 2  =  96
/// ```
///
/// Die Einsen sind Trennspalten. Ohne sie stossen zwei Ziffern mit je einer
/// leeren Randspalte aneinander, und eine 11 sähe aus wie ein breiter Balken.
///
/// Rechtsbündig ist nicht nur Konvention: so bleibt die Einerstelle beim
/// Wechsel von 1849 auf 74 an ihrem Platz, statt dass die ganze Zahl springt.
///
/// **Senkrecht mittig**: die Vorlage hat oben eine und unten sechs leere
/// Reihen. Uebernaehme man den Kasten, saessen die Ziffern sichtbar zu hoch;
/// gezeichnet werden deshalb nur die Reihen mit Punkten, mit gleich viel
/// Rand darueber und darunter.
struct DotMatrixDisplay: View {
    let value: Int
    var tint: Color = Palette.ink
    /// Wechselt der Schlüssel, ist es ein Moduswechsel und kein Zählschritt.
    let resetKey: String

    /// Der zeilenweise Aufbau ist Bewegung; bei „Bewegung reduzieren" wird
    /// stattdessen ohne Welle ueberblendet.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var shown: Reading?
    @State private var shownKey = ""
    @State private var sweep: Double = 1
    @State private var settled = 0
    /// Beim Moduswechsel faengt die Anzeige dunkel an und schreibt sich neu;
    /// beim Zaehlschritt blendet sie von der alten Zahl auf die neue. Die
    /// Unterscheidung kostet nichts — `resetKey` sagt ohnehin, was vorliegt.
    @State private var fromDark = false

    private static let places = 4
    /// Breite aller Ziffern samt Trennspalten.
    private static let block = places * DotMatrixFont.columns + (places - 1)
    /// Zwei Spalten Luft rechts, damit die Einerstelle nicht an der Kante
    /// klebt — mit der leeren Randspalte der Ziffer selbst sind es drei.
    private static let trailing = 2
    private static let leading = Grid.columns - block - trailing
    /// Rand ueber und unter den Ziffern, in Reihen. Gleich viel auf beiden
    /// Seiten; das ist der ganze Zweck.
    private static let padding = 3
    /// **Vier Räder, und ein fünftes gibt es nicht.** Vier Ziffern zu zwanzig
    /// Spalten samt Trennspalten sind exakt die 96 des Zeitstrahls; eine
    /// fünfte Stelle hiesse ein anderes Raster, und dasselbe Raster ist der
    /// ganze Grund, warum diese Anzeige so aussieht.
    ///
    /// Darüber zeigt sie deshalb nicht die Zahl, sondern die **Aussage**:
    /// mehr als das. Ein Grösser-als steht links vor den vier Neunen. Über
    /// zehntausend hat die genaue Zahl ohnehin aufgehört zu interessieren —
    /// und wer sie braucht, stellt auf Flipkarte oder Sieben-Segment um. Die
    /// wachsen mit, weil sie Schrift auf einer Fläche sind und kein Raster.
    ///
    /// Vorher stand hier eine stille Deckelung: über 9999 zeigte die Anzeige
    /// 9999 und sagte nicht dazu, dass sie das tut.
    static let ceiling = 9999

    /// Was auf den Rädern steht, und ob davor ein „mehr als" gehört.
    struct Reading: Equatable {
        var digits: [Int]
        var overflow: Bool
    }

    static func reading(of value: Int) -> Reading {
        Reading(digits: digits(of: value), overflow: value > ceiling)
    }

    static let rows = 2 * padding + DotMatrixFont.inkRows.count
    static let naturalHeight = CGFloat(rows) * Grid.pitch - Grid.gap

    var body: some View {
        Matrix(sweep: sweep, target: Self.reading(of: value),
               shown: shown ?? Self.reading(of: value),
               fromDark: fromDark, tint: tint)
            .aspectRatio(Grid.naturalWidth / Self.naturalHeight, contentMode: .fit)
            .haptic(trigger: settled)
            .accessibilityLabel("\(value)")
            .task(id: "\(value)|\(resetKey)") {
                await update(to: Self.reading(of: value), key: resetKey)
            }
    }

    /// **`Animatable`, und das ist der ganze Punkt.** Ein `Canvas` zeichnet
    /// einmal je Auswertung des Rumpfs; eine animierte Zahl, die nur im
    /// Zeichenblock gelesen wird, kommt dort fertig an und nie dazwischen.
    /// SwiftUI interpoliert `animatableData` und wertet den Rumpf je Bild neu
    /// aus — erst damit laeuft die Welle wirklich ueber die Flaeche.
    ///
    /// Vorher stand `sweep` als `@State` direkt im `Canvas`. Der diagonale
    /// Durchlauf, den das ergeben sollte, hat nie stattgefunden: die Anzeige
    /// sprang. Aufgefallen ist es erst, als eine Bildschirmaufnahme Bild fuer
    /// Bild danebenlag.
    private struct Matrix: View, Animatable {
        var sweep: Double
        let target: Reading
        let shown: Reading
        let fromDark: Bool
        let tint: Color

        var animatableData: Double {
            get { sweep }
            set { sweep = newValue }
        }

        var body: some View {
            Canvas { ctx, size in
                let s = Grid.scale(forWidth: size.width)
                let d = Grid.dot * s

                for row in 0..<DotMatrixDisplay.rows {
                    // Eine Zeile, ein Wert: die Welle laeuft waagrecht, also
                    // aendert sich innerhalb der Zeile nichts mehr.
                    let p = progress(row: row)
                    for column in 0..<Grid.columns {
                        let rect = CGRect(
                            x: Grid.x(column) * s,
                            y: CGFloat(row) * Grid.pitch * s,
                            width: d, height: d
                        )
                        let neu = DotMatrixDisplay.isLit(row: row, column: column,
                                                        reading: target) ? tint : Palette.matrix
                        guard p < 1 else {
                            ctx.fill(Path(rect), with: .color(neu))
                            continue
                        }
                        // Erst der alte Zustand, dann der neue mit steigender
                        // Deckkraft darueber: das ergibt die Ueberblendung,
                        // ohne zwei Farben von Hand zu mischen.
                        let hell = !fromDark && DotMatrixDisplay.isLit(
                            row: row, column: column, reading: shown)
                        ctx.fill(Path(rect), with: .color(hell ? tint : Palette.matrix))
                        if p > 0 { ctx.fill(Path(rect), with: .color(neu.opacity(p))) }
                    }
                }
            }
        }

        /// Der zeilenweise Aufbau: eine Welle laeuft von oben nach unten, und
        /// jede Zeile blendet um, waehrend die Front ueber sie hinweggeht.
        ///
        /// Das **Fenster** ist der Punkt. Ohne es schaltet jede Zeile hart um,
        /// und bei 27 Zeilen in einer halben Sekunde sieht das nach Bildfehler
        /// aus statt nach Aufbau. Mit gut einem Viertel wandert ein weiches
        /// Band nach unten.
        private func progress(row: Int) -> Double {
            guard sweep < 1 else { return 1 }
            let window = 0.28
            let start = Double(row) / Double(DotMatrixDisplay.rows) * (1 - window)
            return min(1, max(0, (sweep - start) / window))
        }
    }

    private func update(to target: Reading, key: String) async {
        let previous = shownKey
        shownKey = key

        guard shown != nil else {
            shown = target
            sweep = 1
            return
        }
        // Ein Moduswechsel baut auch dann neu auf, wenn zufaellig dieselben
        // Ziffern stehen: gewechselt hat die Einheit, und das soll man sehen.
        let wechsel = previous != key
        guard shown != target || wechsel else { return }

        // Der Aufbau aus dem Dunkeln darf laenger dauern als ein Zaehlschritt —
        // er schreibt die ganze Zahl, nicht nur eine Stelle.
        fromDark = wechsel
        let duration = reduceMotion ? 0.2 : (wechsel ? 0.55 : 0.45)
        sweep = reduceMotion ? 1 : 0
        withAnimation(.linear(duration: duration)) { sweep = 1 }
        try? await Task.sleep(for: .seconds(duration))
        shown = target

        // Ein Impuls, wenn der Wert steht — nicht je Punkt. Beim Nullen des
        // Moduswechsels bleibt es still, dort aendert sich nur die Einheit.
        if previous == key { settled += 1 }
    }

    // MARK: - Raster

    private static func digits(of value: Int) -> [Int] {
        let text = String(min(max(0, value), ceiling))
        return Array(repeating: 0, count: max(0, places - text.count))
            + text.compactMap(\.wholeNumberValue)
    }

    /// Spalte im Feld → welche Ziffer, welche Spalte in ihr. Trennspalten und
    /// Füller liefern `nil` und bleiben damit immer unbeleuchtet.
    private static func slot(for column: Int) -> (place: Int, inner: Int)? {
        let offset = column - leading
        guard offset >= 0 else { return nil }
        let pitch = DotMatrixFont.columns + 1
        let place = offset / pitch
        let inner = offset % pitch
        guard place < places, inner < DotMatrixFont.columns else { return nil }
        return (place, inner)
    }

    fileprivate static func isLit(row: Int, column: Int, reading: Reading) -> Bool {
        let glyphRow = row - padding + DotMatrixFont.inkRows.lowerBound
        guard DotMatrixFont.inkRows.contains(glyphRow) else { return false }
        // Links der ersten Ziffer steht im Überlauf das Grösser-als. Die
        // Spaltennummer ist dort zugleich die Spalte in der Glyphe — sie
        // beginnt ja am Rand des Feldes.
        guard let slot = slot(for: column) else {
            guard reading.overflow, column < leading else { return false }
            return DotMatrixFont.greater[glyphRow] & (1 << UInt32(column)) != 0
        }
        guard slot.place < reading.digits.count else { return false }
        return DotMatrixFont.glyphs[reading.digits[slot.place]][glyphRow]
            & (1 << UInt32(slot.inner)) != 0
    }
}

/// Eine einzelne Ziffer — fuer die Auswahl in den Einstellungen, wo man
/// sehen soll, was man waehlt.
struct DotMatrixDigit: View {
    let digit: Int
    var tint: Color = Palette.ink

    var body: some View {
        Canvas { ctx, size in
            let s = size.width / (Grid.x(DotMatrixFont.columns - 1) + Grid.dot)
            let d = Grid.dot * s
            let glyph = DotMatrixFont.glyphs[min(9, max(0, digit))]
            for (index, row) in DotMatrixFont.inkRows.enumerated() {
                for column in 0..<DotMatrixFont.columns {
                    let rect = CGRect(x: Grid.x(column) * s,
                                      y: CGFloat(index) * Grid.pitch * s,
                                      width: d, height: d)
                    let lit = glyph[row] & (1 << UInt32(column)) != 0
                    ctx.fill(Path(rect), with: .color(lit ? tint : Palette.matrix))
                }
            }
        }
        .aspectRatio(
            (Grid.x(DotMatrixFont.columns - 1) + Grid.dot)
                / (CGFloat(DotMatrixFont.inkRows.count) * Grid.pitch - Grid.gap),
            contentMode: .fit
        )
    }
}

#Preview {
    @Previewable @State var value = 1849
    return VStack(spacing: 24) {
        DotMatrixDisplay(value: value, resetKey: "kcal")
        Button("1849 / 74") { value = value == 1849 ? 74 : 1849 }
    }
    .padding(.vertical, 40)
    .background(Palette.paper)
}
