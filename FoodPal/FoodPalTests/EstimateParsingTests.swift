import Foundation
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

/// Die Modellliste, aus der man in den Einstellungen auswählt. Wichtig ist
/// die Dreiwertigkeit von `seesImages`: die meisten Dienste sagen nichts über
/// Bildeingänge, und „weiss nicht" darf nicht zu „nein" werden — sonst
/// verschwände die halbe Liste.
struct ModelListParsingTests {

    private func json(_ raw: String) -> Data { Data(raw.utf8) }

    @Test func openAIFormOhneAngabenSortiert() {
        let listed = VisionEstimator.parseModels(json("""
        {"object":"list","data":[{"id":"gpt-4o-mini"},{"id":"dall-e-3"},{"id":"gpt-4o"}]}
        """))
        #expect(listed.map(\.id) == ["dall-e-3", "gpt-4o", "gpt-4o-mini"])
        #expect(listed.allSatisfy { $0.seesImages == nil })
    }

    /// OpenRouter nennt die Eingabearten — dort laesst es sich wirklich sagen.
    @Test func erklaerteEingabeartenWerdenUebernommen() {
        let listed = VisionEstimator.parseModels(json("""
        {"data":[
          {"id":"a/seher","architecture":{"input_modalities":["text","image"]}},
          {"id":"b/blind","architecture":{"input_modalities":["text"]}}
        ]}
        """))
        #expect(listed.first { $0.id == "a/seher" }?.seesImages == true)
        #expect(listed.first { $0.id == "b/blind" }?.seesImages == false)
    }

    @Test func eintragOhneIDFaelltRaus() {
        let listed = VisionEstimator.parseModels(json(#"{"data":[{"name":"ohne id"},{"id":"gut"}]}"#))
        #expect(listed.map(\.id) == ["gut"])
    }

    @Test func kaputteAntwortGibtLeereListe() {
        #expect(VisionEstimator.parseModels(json("<html>Fehler</html>")).isEmpty)
        #expect(VisionEstimator.parseModels(json(#"{"error":"kaputt"}"#)).isEmpty)
    }
}
