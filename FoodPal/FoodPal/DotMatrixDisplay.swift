import SwiftUI

/// Die Tagessumme als Punktmatrix — im **selben Raster wie der Zeitstrahl**.
///
/// Das ist der Grund, warum diese Darstellung anders sitzt als Flip und
/// 7-Segment: sie ist keine Schrift auf einer Fläche, sondern dieselben
/// 96 Spalten, nur mit anderen Punkten beleuchtet. Deshalb läuft sie wie das
/// Diagramm bis an den Rand.
///
/// Die Ziffern stehen **rechtsbündig**, links wird mit leeren Rasterspalten
/// aufgefüllt:
///
/// ```
/// 13 Füller │ 20 Ziffer │ 1 │ 20 │ 1 │ 20 │ 1 │ 20  =  96
/// ```
///
/// Die Einsen sind Trennspalten. Ohne sie stossen zwei Ziffern mit je einer
/// leeren Randspalte aneinander, und eine 11 sähe aus wie ein breiter Balken.
///
/// Rechtsbündig ist nicht nur Konvention: so bleibt die Einerstelle beim
/// Wechsel von 1849 auf 74 an ihrem Platz, statt dass die ganze Zahl springt.
struct DotMatrixDisplay: View {
    let value: Int
    var tint: Color = Palette.ink
    /// Wechselt der Schlüssel, ist es ein Moduswechsel und kein Zählschritt.
    let resetKey: String

    @State private var shown: [Int] = []
    @State private var shownKey = ""
    @State private var sweep: Double = 1
    @State private var settled = 0

    private static let places = 4
    /// Breite aller Ziffern samt Trennspalten.
    private static let block = places * DotMatrixFont.columns + (places - 1)
    /// Was links davon uebrig bleibt — daraus ergibt sich die Rechtsbuendigkeit.
    private static let leading = Grid.columns - block
    /// Ein Zählwerk mit vier Rädern zeigt über 9999 eben 9999.
    private static let ceiling = 9999

    static let naturalHeight = CGFloat(DotMatrixFont.rows) * Grid.pitch - Grid.gap

    var body: some View {
        Canvas { ctx, size in
            let s = Grid.scale(forWidth: size.width)
            let d = Grid.dot * s
            let target = Self.digits(of: value)

            for row in 0..<DotMatrixFont.rows {
                for column in 0..<Grid.columns {
                    let rect = CGRect(
                        x: Grid.x(column) * s,
                        y: CGFloat(row) * Grid.pitch * s,
                        width: d, height: d
                    )
                    let lit = Self.isLit(row: row, column: column,
                                         digits: reached(row: row, column: column) ? target : shown)
                    ctx.fill(Path(rect), with: .color(lit ? tint : Palette.rule))
                }
            }
        }
        .aspectRatio(Grid.naturalWidth / Self.naturalHeight, contentMode: .fit)
        .haptic(trigger: settled)
        .accessibilityLabel("\(value)")
        .task(id: "\(value)|\(resetKey)") {
            await update(to: Self.digits(of: value), key: resetKey)
        }
    }

    /// Der diagonale Durchlauf: eine Zelle nimmt den neuen Zustand an, sobald
    /// die Welle sie erreicht hat. Eine einzige animierte Zahl statt 3168
    /// einzelner Animationen — im `Canvas` gäbe es die auch gar nicht.
    private func reached(row: Int, column: Int) -> Bool {
        guard sweep < 1 else { return true }
        let front = Double(row + column) / Double(DotMatrixFont.rows + Grid.columns)
        return front <= sweep
    }

    private func update(to target: [Int], key: String) async {
        let previous = shownKey
        shownKey = key

        guard !shown.isEmpty else {
            shown = target
            sweep = 1
            return
        }
        guard shown != target else { return }

        sweep = 0
        withAnimation(.easeInOut(duration: 0.45)) { sweep = 1 }
        try? await Task.sleep(for: .seconds(0.45))
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

    private static func isLit(row: Int, column: Int, digits: [Int]) -> Bool {
        guard row < DotMatrixFont.rows,
              let slot = slot(for: column),
              slot.place < digits.count else { return false }
        return DotMatrixFont.glyphs[digits[slot.place]][row] & (1 << UInt32(slot.inner)) != 0
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
            for row in 0..<DotMatrixFont.rows {
                for column in 0..<DotMatrixFont.columns {
                    let rect = CGRect(x: Grid.x(column) * s,
                                      y: CGFloat(row) * Grid.pitch * s,
                                      width: d, height: d)
                    let lit = glyph[row] & (1 << UInt32(column)) != 0
                    ctx.fill(Path(rect), with: .color(lit ? tint : Palette.rule))
                }
            }
        }
        .aspectRatio(
            (Grid.x(DotMatrixFont.columns - 1) + Grid.dot) / DotMatrixDisplay.naturalHeight,
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
