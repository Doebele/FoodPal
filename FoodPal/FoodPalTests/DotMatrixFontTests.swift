import Testing
@testable import FoodPal

/// Die Glyphen sind aus Figma übertragene Daten, kein Code. Diese Tests
/// prüfen deshalb nicht Verhalten, sondern **Unversehrtheit** — ein
/// Kopierfehler fände sich sonst erst am Bildschirm, und dort sieht man einer
/// Ziffer nicht an, ob sie so gemeint war.
struct DotMatrixFontTests {

    @Test func zehnZiffernMitGleicherHoehe() {
        #expect(DotMatrixFont.glyphs.count == 10)
        #expect(DotMatrixFont.glyphs.allSatisfy { $0.count == DotMatrixFont.rows })
    }

    /// Keine Ziffer darf über ihre zwanzig Spalten hinausragen — sonst
    /// leuchtete sie in die Trennspalte oder in die Nachbarziffer hinein.
    @Test func keineZifferRagtHinaus() {
        let outside = ~UInt32(0) << UInt32(DotMatrixFont.columns)
        for (digit, glyph) in DotMatrixFont.glyphs.enumerated() {
            #expect(glyph.allSatisfy { $0 & outside == 0 }, "Ziffer \(digit)")
        }
    }

    /// Vier Ziffern, drei Trennspalten und die Füllung links ergeben genau die
    /// Breite des Zeitstrahls. Geht das nicht auf, sitzt die Anzeige nicht mehr
    /// im selben Raster wie das Diagramm darüber — und das ist der ganze Punkt.
    @Test func feldPasstAufDasRasterDesZeitstrahls() {
        let block = 4 * DotMatrixFont.columns + 3
        #expect(block == 83)
        #expect(Grid.columns - block == 13)
    }

    @Test func alleZehnSindVerschieden() {
        let shapes = DotMatrixFont.glyphs.map { $0.map(String.init).joined(separator: "-") }
        #expect(Set(shapes).count == 10)
    }

    /// Jede Ziffer hat Punkte — eine leere Glyphe wäre ein stiller Ausfall.
    @Test func keineZifferIstLeer() {
        for (digit, glyph) in DotMatrixFont.glyphs.enumerated() {
            #expect(glyph.contains { $0 != 0 }, "Ziffer \(digit)")
        }
    }
}
