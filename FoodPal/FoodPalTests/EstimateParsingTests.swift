import Testing
@testable import FoodPal

/// Der eine Test, der hier fällig ist. Der Parser muss mit dem umgehen, was
/// die drei Anbieter tatsächlich zurückgeben — blankes JSON, in Codeblöcke
/// gewickeltes, mit vorangestelltem Geplauder, mit Zahlen als Text. Der Rest
/// der App ist zu dünn für Tests.
struct EstimateParsingTests {

    @Test func blankesJSON() throws {
        let estimate = try VisionEstimator.parse(
            #"{"name":"Bowl mit Lachs","kcal":620,"proteinG":34,"carbsG":52,"fatG":21}"#
        )
        #expect(estimate.name == "Bowl mit Lachs")
        #expect(estimate.kcal == 620)
        #expect(estimate.proteinG == 34)
    }

    @Test func inCodeblockGewickelt() throws {
        let estimate = try VisionEstimator.parse("""
        ```json
        {"name":"Porridge","kcal":410,"proteinG":12,"carbsG":62,"fatG":9}
        ```
        """)
        #expect(estimate.name == "Porridge")
        #expect(estimate.kcal == 410)
    }

    @Test func mitGeplauderDavorUndDanach() throws {
        let estimate = try VisionEstimator.parse("""
        Gern! Hier meine Schätzung:
        {"name":"Ofengemüse","kcal":741,"proteinG":18,"carbsG":74,"fatG":33}
        Die Portionsgröße ist geschätzt.
        """)
        #expect(estimate.name == "Ofengemüse")
        #expect(estimate.kcal == 741)
    }

    /// Kleinere Modelle liefern Zahlen gern als Text — daran ist ein
    /// strenger `Decodable` gescheitert, deshalb der zweite Anlauf im Parser.
    @Test func zahlenAlsText() throws {
        let estimate = try VisionEstimator.parse(
            #"{"name":"Espresso","kcal":"2","proteinG":"0","carbsG":"0,4","fatG":"0"}"#
        )
        #expect(estimate.kcal == 2)
        #expect(estimate.carbsG == 0.4)
    }

    @Test func fehlendeMakrosSindErlaubt() throws {
        let estimate = try VisionEstimator.parse(#"{"name":"Apfel","kcal":95}"#)
        #expect(estimate.kcal == 95)
        #expect(estimate.proteinG == nil)
    }

    @Test func ohneJSONWirdGeworfen() {
        #expect(throws: (any Error).self) {
            try VisionEstimator.parse("Ich kann auf diesem Bild kein Essen erkennen.")
        }
    }
}
