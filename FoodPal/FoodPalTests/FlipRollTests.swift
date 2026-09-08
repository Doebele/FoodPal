import Foundation
import Testing
@testable import FoodPal

/// Ein Zählwerk dreht vorwärts und alle Räder zugleich: von 4 auf 8 über 5, 6
/// und 7, und wer weniger Weg hat, steht früher still.
struct FlipRollTests {

    @Test func alleStellenRueckenJeWelleGleichzeitig() {
        // 0000 → 1849: die 9 hat den weitesten Weg und gibt die Länge vor.
        let plan = FlipDisplay.waves(from: [0, 0, 0, 0], to: [1, 8, 4, 9])
        #expect(plan.count == 9)
        #expect(plan.first == [1, 1, 1, 1])
        #expect(plan.last == [1, 8, 4, 9])
    }

    /// Der Kern der Sache: die kurzen Wege sind zuerst fertig und rühren sich
    /// danach nicht mehr, während die langen weiterzählen.
    @Test func fertigeStellenBleibenStehen() {
        let plan = FlipDisplay.waves(from: [0, 0], to: [2, 5])
        #expect(plan == [[1, 1], [2, 2], [2, 3], [2, 4], [2, 5]])
    }

    /// Vorwärts heißt auch über die Null hinweg — sonst liefe die Anzeige
    /// rückwärts, und ein Zählwerk tut das nicht.
    @Test func ueberDieNullHinwegStattZurueck() {
        #expect(FlipDisplay.waves(from: [8], to: [1]) == [[9], [0], [1]])
    }

    /// Keine Stelle braucht mehr als neun Klappen, egal wie weit der Sprung
    /// ist. Genau deshalb ist die frühere Deckelung entbehrlich.
    @Test func hoechstensNeunWellen() {
        for from in 0...9 {
            for to in 0...9 {
                #expect(FlipDisplay.waves(from: [from], to: [to]).count <= 9)
            }
        }
    }

    @Test func gleicherWertBewegtNichts() {
        #expect(FlipDisplay.waves(from: [1, 8, 4, 9], to: [1, 8, 4, 9]).isEmpty)
    }

    /// Jede Stelle erreicht ihr Ziel **genau** mit ihrer letzten Klappe und
    /// steht danach still. Darauf stützt sich die langsamere Aufsetz-Dauer in
    /// `roll`: sie erkennt die letzte Klappe daran, dass der Zielwert steht.
    @Test func zielWirdErstMitDerLetztenKlappeErreicht() {
        let target = [1, 8, 4, 9]
        let plan = FlipDisplay.waves(from: [0, 5, 4, 2], to: target)
        for place in target.indices {
            let treffer = plan.indices.filter { plan[$0][place] == target[place] }
            #expect(treffer == Array(treffer.first!...(plan.count - 1)))
        }
    }
}
