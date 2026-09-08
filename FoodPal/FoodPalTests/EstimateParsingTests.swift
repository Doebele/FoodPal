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

/// Gesprochene Einträge liefern **mehrere** Gerichte und oft einen Zeitpunkt.
/// Modelle sind sich uneins, ob sie ein Array, ein Objekt mit `items` oder —
/// bei nur einem Gericht — doch ein einzelnes Objekt schicken. Alle drei
/// müssen durchgehen, sonst scheitert ein Nachtrag an der Verpackung.
struct SpokenParsingTests {

    @Test func arrayMitZweiGerichten() {
        let items = VisionEstimator.parseList("""
        [{"name":"Spaghetti Bolognese","kcal":620,"proteinG":28,"carbsG":72,"fatG":22},
         {"name":"Minestrone, klein","kcal":95,"proteinG":4,"carbsG":14,"fatG":2}]
        """)
        #expect(items.count == 2)
        #expect(items[0].name == "Spaghetti Bolognese")
        #expect(items[1].kcal == 95)
    }

    @Test func objektMitItems() {
        let items = VisionEstimator.parseList(#"{"items":[{"name":"Ramen","kcal":450}]}"#)
        #expect(items.map(\.name) == ["Ramen"])
    }

    @Test func einzelnesObjektGehtAuch() {
        let items = VisionEstimator.parseList(#"{"name":"Apfel","kcal":95}"#)
        #expect(items.map(\.kcal) == [95])
    }

    @Test func inCodeblockUndMitGeplauder() {
        let items = VisionEstimator.parseList("""
        Gern, hier die Schätzung:
        ```json
        [{"name":"Baguette mit Butter","kcal":210}]
        ```
        Die Mengen sind geschätzt.
        """)
        #expect(items.map(\.name) == ["Baguette mit Butter"])
    }

    /// Der Zeitpunkt kommt in Ortszeit ohne Zone zurück — so verlangt es der
    /// Prompt, und nur so trifft ein Nachtrag den richtigen Tag.
    ///
    /// **Ohne Sekunden**, denn genau danach fragt der Prompt. Der frühere Test
    /// prüfte mit Sekunden und ging deshalb durch, während die Zeitangabe in
    /// der App stillschweigend verloren ging — ein Test, der dem Code recht
    /// gab statt der Wirklichkeit.
    @Test(arguments: [
        "2026-09-07T21:00",
        "2026-09-07T21:00:00",
        "2026-09-07 21:00"
    ])
    func zeitpunktInJederSchreibweise(_ raw: String) throws {
        let items = VisionEstimator.parseList(
            #"[{"name":"Ramen","kcal":450,"date":"\#(raw)"}]"#
        )
        let date = try #require(items.first?.date, "nicht geparst: \(raw)")
        let parts = Calendar.current.dateComponents([.day, .hour], from: date)
        #expect(parts.day == 7)
        #expect(parts.hour == 21)
    }

    /// Nur ein Datum ohne Uhrzeit ist besser als gar nichts — der Eintrag
    /// landet dann am richtigen Tag, die Uhrzeit korrigiert man von Hand.
    @Test func nurDatumGehtAuch() throws {
        let items = VisionEstimator.parseList(#"[{"name":"Brot","kcal":180,"date":"2026-09-07"}]"#)
        let date = try #require(items.first?.date)
        #expect(Calendar.current.component(.day, from: date) == 7)
    }

    @Test func unbrauchbarerZeitpunktBleibtOffen() {
        #expect(VisionEstimator.localDate("gestern Abend") == nil)
        #expect(VisionEstimator.localDate("") == nil)
    }

    @Test func ohneZeitpunktBleibtOffen() {
        #expect(VisionEstimator.parseList(#"[{"name":"Ramen","kcal":450}]"#).first?.date == nil)
    }

    /// Ein Gericht ohne kcal ist wertlos und darf die anderen nicht mitreissen.
    @Test func eintragOhneKcalFaelltRaus() {
        let items = VisionEstimator.parseList(
            #"[{"name":"Wasser"},{"name":"Brot","kcal":180}]"#
        )
        #expect(items.map(\.name) == ["Brot"])
    }

    @Test func ohneJSONLeereListe() {
        #expect(VisionEstimator.parseList("Ich habe das nicht verstanden.").isEmpty)
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
