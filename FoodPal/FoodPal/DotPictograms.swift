import SwiftUI

/// Punktgrafiken über den Erfassungsschirmen. Runde Punkte, nicht quadratische:
/// sie sind kein Datenraster, sondern eine Marke — die Lochung eines
/// Braun-Lautsprechers, nicht das Tagesdiagramm.
///
/// Beide Zeichnungen stammen aus dem Entwurf; die Punktmitten sind von dort
/// abgelesen und liegen als Tabelle bereit, statt zur Laufzeit konstruiert zu
/// werden. Die Rosette ist rekursiv aufgebaut, und ihre Formel nachzubilden
/// hätte mehr Code gekostet als ihre 665 Mittelpunkte.
struct DotArt: View {
    let points: [CGPoint]
    /// Kantenlänge des Entwurfsquadrats, in dem die Punkte liegen.
    let box: CGFloat
    /// Punktdurchmesser in denselben Einheiten.
    var diameter: CGFloat = 6
    var color: Color = Palette.rule

    var body: some View {
        Canvas { ctx, size in
            let s = min(size.width, size.height) / box
            let r = diameter * s
            for p in points {
                let rect = CGRect(x: p.x * s - r / 2, y: p.y * s - r / 2, width: r, height: r)
                ctx.fill(Path(ellipseIn: rect), with: .color(color))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

extension DotArt {
    /// Das Kreuz über der Erfassung: 13 x 13 Raster, Teilung 15, Mittelreihe
    /// und Mittelspalte gesetzt. Hinzufügen, im selben Punktvokabular.
    static var plus: DotArt {
        let pitch: CGFloat = 15
        let centre = 6
        var points: [CGPoint] = []
        for i in 0..<13 where i != centre {
            points.append(CGPoint(x: 3 + CGFloat(centre) * pitch, y: 3 + CGFloat(i) * pitch))
            points.append(CGPoint(x: 3 + CGFloat(i) * pitch, y: 3 + CGFloat(centre) * pitch))
        }
        points.append(CGPoint(x: 3 + CGFloat(centre) * pitch, y: 3 + CGFloat(centre) * pitch))
        return DotArt(points: points, box: 186)
    }

    /// Info und Schliessen, aus dem Entwurf abgelesen (Node `153:327896`).
    ///
    /// **12 Spalten, 13 Reihen, Teilung 4, Punkt 3** — dasselbe Raster wie der
    /// Zeitstrahl, nur mit runden Punkten: hier ist es eine Marke, kein
    /// Datenfeld.
    ///
    /// Das i ist ein gesetztes i mit Fahne und Fuss, nicht ein Strich mit
    /// Tuepfelchen. Die erste eigene Fassung setzte den Stamm enger als seinen
    /// Durchmesser, damit er zu einer Linie zusammenfloss; der Entwurf loest
    /// dasselbe anders und besser, naemlich mit einer Serife.
    static func info(color: Color) -> DotArt {
        grid([
            "............",
            ".....##.....",
            ".....##.....",
            "............",
            "...####.....",
            ".....##.....",
            ".....##.....",
            ".....##.....",
            ".....##.....",
            ".....##.....",
            ".....##.....",
            "...######...",
            "............",
        ], color: color)
    }

    static func close(color: Color) -> DotArt {
        grid([
            "............",
            ".#........#.",
            ".##......##.",
            "..##....##..",
            "...##..##...",
            "....####....",
            ".....##.....",
            "....####....",
            "...##..##...",
            "..##....##..",
            ".##......##.",
            ".#........#.",
            "............",
        ], color: color)
    }

    /// Die Zeichnung steht als Raster da und nicht als Koordinatenliste: so
    /// sieht man die Form im Quelltext und kann sie mit dem Entwurf
    /// vergleichen, ohne etwas zu rechnen.
    ///
    /// `DotArt` zeichnet in ein Quadrat; die zwoelf Spalten sind eine
    /// schmaler als die dreizehn Reihen und werden darin mittig gesetzt.
    private static func grid(_ rows: [String], color: Color) -> DotArt {
        let pitch: CGFloat = 4, dot: CGFloat = 3
        let box = CGFloat(rows.count) * pitch - (pitch - dot)
        let breite = CGFloat(rows[0].count) * pitch - (pitch - dot)
        let links = (box - breite) / 2
        var points: [CGPoint] = []
        for (row, zeile) in rows.enumerated() {
            for (column, zeichen) in zeile.enumerated() where zeichen == "#" {
                points.append(CGPoint(x: links + CGFloat(column) * pitch + dot / 2,
                                      y: CGFloat(row) * pitch + dot / 2))
            }
        }
        return DotArt(points: points, box: box, diameter: dot, color: color)
    }

    /// Die Rosette über der Beschreibung — Sprache. Aus dem Entwurf abgelesen,
    /// Koordinaten in halben Punkten, deshalb die Division durch zwei.
    static func speaker(color: Color = Palette.rule) -> DotArt {
        DotArt(points: Self.speakerRaw, box: 187, color: color)
    }

    private static let speakerRaw: [CGPoint] = {
        var out: [CGPoint] = []
        out.reserveCapacity(speakerHalves.count / 2)
        for i in stride(from: 0, to: speakerHalves.count, by: 2) {
            out.append(CGPoint(x: CGFloat(speakerHalves[i]) / 2, y: CGFloat(speakerHalves[i + 1]) / 2))
        }
        return out
    }()

    /// Mittelpunkte in halben Entwurfspunkten, Zeile für Zeile von oben.
    /// Mittelpunkte in halben Entwurfspunkten, Zeile für Zeile von oben.
    ///
    /// Aus dem gerenderten Entwurf abgelesen, nicht aus dem Knotenbaum: die
    /// Rosette ist in Figma rekursiv aus sieben Ebenen aufgebaut, von denen
    /// die meisten übereinanderliegen. Wer den Baum ausliest, bekommt 665
    /// Punkte und ein Ringmuster; **sichtbar sind 135** auf einem gedrehten
    /// Raster. Gezählt wurde deshalb, was im Bild steht.
    private static let speakerHalves: [Int16] = [
        188,7, 216,7, 160,9, 244,14, 133,15, 270,25, 107,27, 188,37, 159,39, 217,39, 295,39, 83,41,
        130,49, 246,49, 316,58, 61,59, 103,64, 273,64, 188,67, 156,69, 219,69, 335,79, 43,81, 127,81,
        248,81, 81,82, 295,83, 188,97, 160,99, 103,101, 215,101, 273,101, 349,104, 29,105, 63,105, 313,105,
        135,113, 240,114, 293,125, 83,126, 188,127, 50,130, 326,130, 360,130, 18,131, 115,133, 157,133, 260,134,
        218,135, 71,155, 305,155, 135,156, 41,157, 188,157, 239,157, 335,157, 367,157, 11,158, 101,158, 273,159,
        163,171, 213,172, 7,186, 37,186, 67,186, 97,186, 127,186, 188,186, 247,186, 277,186, 307,186, 337,186,
        367,186, 215,201, 161,202, 273,213, 11,214, 101,214, 367,214, 40,215, 337,215, 239,216, 73,217, 135,217,
        188,217, 303,217, 217,237, 260,238, 115,239, 158,239, 17,241, 360,242, 48,243, 328,243, 85,245, 291,246,
        188,247, 240,258, 135,259, 29,267, 315,268, 349,268, 61,269, 104,270, 272,270, 215,271, 160,273, 188,277,
        128,289, 247,289, 43,291, 80,291, 297,291, 335,293, 157,301, 219,301, 188,307, 101,309, 275,309, 61,313,
        316,314, 129,325, 247,325, 83,331, 295,333, 217,334, 159,335, 188,337, 107,345, 270,347, 133,356, 244,358,
        160,363, 217,365, 188,367,
    ]
}
