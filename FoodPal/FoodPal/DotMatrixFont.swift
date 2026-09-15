import Foundation

/// Die zehn Ziffern im Punktraster, so wie sie in Figma gezeichnet sind
/// (Node `101:253908`, Bauteil `Dot Matrix`).
///
/// Jede Ziffer ist **20 Spalten breit und 33 Reihen hoch**, gleich breit
/// wie jede andere — die Anzeige rastert damit wie ein Zählwerk und nicht wie
/// ein Schriftsatz.
///
/// Gespeichert als Lauflängen, weil die Ziffern in Bändern gezeichnet sind:
/// gleiche Zeilen wiederholen sich drei- bis sechsmal. Das hält die Vorlage
/// lesbar — man sieht die Form im Quelltext — und ist trotzdem kurz genug,
/// um sie beim nächsten Entwurf ohne Werkzeug zu vergleichen.
enum DotMatrixFont {
    static let columns = 20
    static let rows = 33

    /// Die Reihen, in denen ueberhaupt Punkte liegen. Die Vorlage hat oben
    /// **eine** leere Reihe und unten **sechs** — wer den Kasten unbesehen
    /// nimmt, bekommt Ziffern, die im Feld nach oben rutschen. Berechnet und
    /// nicht eingetragen, damit es beim naechsten Entwurf von selbst stimmt.
    static let inkRows: ClosedRange<Int> = {
        let filled = (0..<rows).filter { row in glyphs.contains { $0[row] != 0 } }
        guard let first = filled.first, let last = filled.last else { return 0...(rows - 1) }
        return first...last
    }()

    /// Je Ziffer eine Reihe von Bitmasken; Bit *n* ist Spalte *n* von links.
    static let glyphs: [[UInt32]] = shapes.map { runs in
        runs.flatMap { run in Array(repeating: mask(run.1), count: run.0) }
    }

    /// Das **Grösser-als** für den Überlauf. Es steht in den Spalten eins bis
    /// neun — die elf Füllerspalten links der ersten Ziffer waren ohnehin
    /// leer, und Spalte zehn bleibt als Trennspalte frei.
    ///
    /// Kürzer als eine Ziffer: dreizehn Reihen gegen sechsundzwanzig, mittig
    /// gesetzt. Ein Rechenzeichen steht neben Zahlen, nicht unter ihnen.
    ///
    /// **Die Treppe geht Reihe für Reihe**, nicht in 3×3-Stufen wie die
    /// Diagonalen der Ziffern. Bei denen läuft die Schräge über zwölf Reihen
    /// und liest sich als Linie; über sechs Reihen wird aus derselben Stufung
    /// ein Zickzack, das nach Blitz aussieht statt nach Zeichen. Ausprobiert
    /// und verworfen.
    static let greater: [UInt32] = greaterShape.flatMap { run in
        Array(repeating: mask(run.1), count: run.0)
    }

    private static let greaterShape: [(Int, String)] = [
        (7,  "...................."),
        (1,  ".###................"),
        (1,  "..###..............."),
        (1,  "...###.............."),
        (1,  "....###............."),
        (1,  ".....###............"),
        (1,  "......###..........."),
        (1,  ".......###.........."),
        (1,  "......###..........."),
        (1,  ".....###............"),
        (1,  "....###............."),
        (1,  "...###.............."),
        (1,  "..###..............."),
        (1,  ".###................"),
        (13, "...................."),
    ]

    private static func mask(_ pattern: String) -> UInt32 {
        var bits: UInt32 = 0
        for (index, character) in pattern.enumerated() where character == "#" {
            bits |= 1 << UInt32(index)
        }
        return bits
    }

    private static let shapes: [[(Int, String)]] = [
        [ // 0
            (1, "...................."),
            (3, "....############...."),
            (4, ".###............###."),
            (3, ".###.........######."),
            (3, ".###......###...###."),
            (3, ".###...###......###."),
            (3, ".######.........###."),
            (4, ".###............###."),
            (3, "....############...."),
            (6, "...................."),
        ],
        [ // 1
            (1, "...................."),
            (3, "........###........."),
            (3, ".....######........."),
            (17, "........###........."),
            (3, ".....#########......"),
            (6, "...................."),
        ],
        [ // 2
            (1, "...................."),
            (3, "....############...."),
            (3, ".###............###."),
            (5, "................###."),
            (3, ".............###...."),
            (3, "..........###......."),
            (3, ".......###.........."),
            (3, "....###............."),
            (3, ".##################."),
            (6, "...................."),
        ],
        [ // 3
            (1, "...................."),
            (3, ".###############...."),
            (8, "................###."),
            (3, ".....###########...."),
            (9, "................###."),
            (3, ".###############...."),
            (6, "...................."),
        ],
        [ // 4
            (1, "...................."),
            (11, ".###............###."),
            (3, ".##################."),
            (12, "................###."),
            (6, "...................."),
        ],
        [ // 5
            (1, "...................."),
            (3, ".##################."),
            (8, ".###................"),
            (3, ".###############...."),
            (9, "................###."),
            (3, ".###############...."),
            (6, "...................."),
        ],
        [ // 6
            (1, "...................."),
            (3, "....############...."),
            (8, ".###................"),
            (3, ".###############...."),
            (9, ".###............###."),
            (3, "....############...."),
            (6, "...................."),
        ],
        [ // 7
            (1, "...................."),
            (3, ".##################."),
            (8, "................###."),
            (3, ".............###...."),
            (3, "..........###......."),
            (9, ".......###.........."),
            (6, "...................."),
        ],
        [ // 8
            (1, "...................."),
            (3, "....############...."),
            (8, ".###............###."),
            (3, "....############...."),
            (9, ".###............###."),
            (3, "....############...."),
            (6, "...................."),
        ],
        [ // 9
            (1, "...................."),
            (3, "....############...."),
            (8, ".###............###."),
            (3, "....###############."),
            (6, "................###."),
            (3, ".###............###."),
            (3, "....############...."),
            (6, "...................."),
        ],
    ]
}
