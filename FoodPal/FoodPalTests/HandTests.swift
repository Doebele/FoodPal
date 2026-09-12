import Testing
@testable import FoodPal

/// Die Bedienhand dreht Griffe um, und die einzige Stelle mit Rechenweg ist
/// das Kaffeeraster: es füllt von unten an der Bedienhand nach oben weg.
///
/// Der Rest der Spiegelung ist Anordnung im Aufbau der Ansichten, die prüft
/// man am Bild. Diese Reihenfolge dagegen ist Logik, und sie ist die, auf die
/// es ankommt: **die häufigste Sorte muss unter dem Daumen liegen.**
struct HandTests {

    private var sorten: [CoffeePreset] { Array(CoffeePreset.all.prefix(8)) }

    @Test func rechtshaenderFuellenVonUntenRechts() {
        let feld = CoffeeCapture.grid(sorten, columns: 4, rows: 2, hand: .right)
        #expect(feld[1][3]?.name == sorten[0].name)
        #expect(feld[1][2]?.name == sorten[1].name)
        #expect(feld[0][3]?.name == sorten[4].name)
    }

    @Test func linkshaenderFuellenVonUntenLinks() {
        let feld = CoffeeCapture.grid(sorten, columns: 4, rows: 2, hand: .left)
        #expect(feld[1][0]?.name == sorten[0].name)
        #expect(feld[1][1]?.name == sorten[1].name)
        #expect(feld[0][0]?.name == sorten[4].name)
    }

    /// Die letzte Zeile bleibt in beiden Fällen die vollste: gefüllt wird von
    /// unten, nur die Richtung dreht sich.
    @Test func obenBleibenDieLuecken() {
        for hand in Hand.allCases {
            let feld = CoffeeCapture.grid(Array(sorten.prefix(5)), columns: 4, rows: 2, hand: hand)
            #expect(feld[1].compactMap { $0 }.count == 4)
            #expect(feld[0].compactMap { $0 }.count == 1)
        }
    }

    /// Zwei grosse Kacheln: die häufigste liegt an der Bedienhand.
    @Test func dieHaeufigsteLiegtUnterDemDaumen() {
        #expect(Hand.right.order("häufig", "zweit") == ["zweit", "häufig"])
        #expect(Hand.left.order("häufig", "zweit") == ["häufig", "zweit"])
    }
}
