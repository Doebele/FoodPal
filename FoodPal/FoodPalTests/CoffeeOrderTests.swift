import Testing
@testable import FoodPal

/// **Die Leiter.** Drei Sprossen: zwei grosse unten an der Bedienhand, sechs
/// laengliche in der Mitte, der Rest als kleine Quadrate oben. Ein Tipp hebt
/// ein Getraenk um genau eine Sprosse.
///
/// Das ist die Regel, auf die es ankommt, und sie ist reine Logik — die
/// Anordnung im Feld prueft `HandTests`.
struct CoffeeOrderTests {

    /// Zwanzig Namen: zwei gross, sechs mittel, zwoelf klein.
    private var leiter: [String] { (0..<20).map { "S\($0)" } }

    @Test func ausDenKleinenInDieMitte() {
        let neu = CoffeeCapture.promoted(leiter, choosing: "S12")
        #expect(neu[2] == "S12")
        // Nie in einem Zug zu den zwei grossen.
        #expect(neu[0] == "S0")
        #expect(neu[1] == "S1")
    }

    @Test func ausDerMitteZuDenGrossen() {
        let neu = CoffeeCapture.promoted(leiter, choosing: "S5")
        #expect(neu[0] == "S5")
    }

    /// Wer verdraengt wird, faellt genau eine Sprosse, nicht weiter.
    @Test func derVerdraengteFaelltEineSprosse() {
        let mitte = CoffeeCapture.promoted(leiter, choosing: "S12")
        // Der letzte Mittelplatz war S7, er steht jetzt auf dem ersten
        // kleinen Platz.
        #expect(mitte[7] == "S6")
        #expect(mitte[8] == "S7")

        let gross = CoffeeCapture.promoted(leiter, choosing: "S5")
        // Die zweite grosse Kachel war S1, sie steht jetzt vorne in der Mitte.
        #expect(gross[1] == "S0")
        #expect(gross[2] == "S1")
    }

    /// Zweimal dasselbe, und es liegt unter dem Daumen — aber keinen Tipp
    /// frueher.
    @Test func zweiTippsBisUnterDenDaumen() {
        let einmal = CoffeeCapture.promoted(leiter, choosing: "S19")
        #expect(einmal[0] != "S19")
        let zweimal = CoffeeCapture.promoted(einmal, choosing: "S19")
        #expect(zweimal[0] == "S19")
    }

    @Test func dieZweiteGrosseRuecktAnDenDaumen() {
        #expect(CoffeeCapture.promoted(leiter, choosing: "S1")[0] == "S1")
    }

    /// Wer schon am Daumen liegt, bleibt liegen, und was die Liste nicht
    /// kennt, ruehrt sie nicht an.
    @Test func nichtsZuTun() {
        #expect(CoffeeCapture.promoted(leiter, choosing: "S0") == leiter)
        #expect(CoffeeCapture.promoted(leiter, choosing: "gibtsnicht") == leiter)
    }
}
