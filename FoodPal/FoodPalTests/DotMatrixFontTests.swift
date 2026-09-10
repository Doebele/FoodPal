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

/// Über 9999 hat die Dot-Matrix kein fünftes Rad. Sie darf deshalb vieles —
/// nur nicht so tun, als wäre die Zahl kleiner als sie ist.
struct OverflowTests {

    @Test func flipUndSiebenSegmentWachsenMit() {
        // `Digits.of` schneidet nichts ab: die beiden Stile sind Schrift auf
        // einer Fläche und bekommen einfach eine Karte mehr.
        #expect(Digits.of(63303) == [6, 3, 3, 0, 3])
        #expect(Digits.of(1849) == [1, 8, 4, 9])
        #expect(Digits.of(74) == [0, 0, 7, 4])
    }

    @Test func dieDotMatrixSagtEsStattZuDecken() {
        #expect(DotMatrixDisplay.reading(of: 9_999).overflow == false)
        #expect(DotMatrixDisplay.reading(of: 10_000).overflow)
        // Die Räder stehen dann auf 9999 — und davor das Zeichen.
        #expect(DotMatrixDisplay.reading(of: 63_303).digits == [9, 9, 9, 9])
    }

    /// Das Zeichen muss in die elf Füllerspalten links passen, sonst schöbe
    /// es die erste Ziffer aus dem Raster des Zeitstrahls.
    @Test func dasZeichenPasstInDieFreienSpalten() {
        var belegt: UInt32 = 0
        for zeile in DotMatrixFont.greater { belegt |= zeile }
        #expect(belegt != 0, "das Grösser-als ist leer")

        var letzte = 0
        for spalte in 0..<32 where belegt & (1 << UInt32(spalte)) != 0 { letzte = spalte }
        #expect(letzte < 10, "das Zeichen reicht bis Spalte \(letzte), erlaubt sind 0 bis 9")
        #expect(DotMatrixFont.greater.count == DotMatrixFont.rows)
    }
}
