import Foundation
import Testing
@testable import FoodPal

/// Open Food Facts ist crowdgesourct: Felder fehlen, Namen stehen mal deutsch
/// und mal nur englisch da, Marken doppeln sich mit dem Produktnamen. Der
/// Parser muss das aushalten, ohne Unsinn zu speichern.
struct FoodDatabaseTests {

    private func json(_ raw: String) -> Data { Data(raw.utf8) }

    @Test func vollstaendigesProdukt() throws {
        let estimate = try #require(FoodDatabase.parse(json("""
        {"code":"7610807000015","status":1,"product":{
          "product_name":"Vollmilch","brands":"Emmi",
          "nutriments":{"energy-kcal_100g":68,"proteins_100g":3.5,
                        "carbohydrates_100g":4.7,"fat_100g":3.9}}}
        """)))
        #expect(estimate.name == "Emmi Vollmilch")
        #expect(estimate.kcal == 68)
        #expect(estimate.proteinG == 3.5)
    }

    @Test func deutscherNameGehtVor() throws {
        let estimate = try #require(FoodDatabase.parse(json("""
        {"product":{"product_name":"Whole grain bread","product_name_de":"Vollkornbrot",
          "nutriments":{"energy-kcal_100g":247}}}
        """)))
        #expect(estimate.name == "Vollkornbrot")
    }

    /// Steht die Marke schon im Namen, darf sie nicht ein zweites Mal davor.
    @Test func markeNichtVerdoppeln() throws {
        let estimate = try #require(FoodDatabase.parse(json("""
        {"product":{"product_name":"Emmi Caffè Latte","brands":"Emmi",
          "nutriments":{"energy-kcal_100g":63}}}
        """)))
        #expect(estimate.name == "Emmi Caffè Latte")
    }

    @Test func nurDieErsteMarke() throws {
        let estimate = try #require(FoodDatabase.parse(json("""
        {"product":{"product_name":"Birchermüesli","brands":"Bio, Coop, Karma",
          "nutriments":{"energy-kcal_100g":174}}}
        """)))
        #expect(estimate.name == "Bio Birchermüesli")
    }

    @Test func fehlendeMakrosSindErlaubt() throws {
        let estimate = try #require(FoodDatabase.parse(json("""
        {"product":{"product_name":"Espresso","nutriments":{"energy-kcal_100g":2}}}
        """)))
        #expect(estimate.proteinG == nil)
        #expect(estimate.fatG == nil)
    }

    @Test func zahlenAlsText() throws {
        let estimate = try #require(FoodDatabase.parse(json("""
        {"product":{"product_name":"Joghurt",
          "nutriments":{"energy-kcal_100g":"56","fat_100g":"3,2"}}}
        """)))
        #expect(estimate.kcal == 56)
        #expect(estimate.fatG == 3.2)
    }

    /// Die beiden harten Bedingungen: ohne Namen und ohne Energie ist der
    /// Treffer wertlos und muss durchfallen, damit das LLM übernimmt.
    @Test func unbekanntesProdukt() {
        #expect(FoodDatabase.parse(json(#"{"code":"0000000000000","status":0}"#)) == nil)
    }

    @Test func ohneEnergieWertlos() {
        #expect(FoodDatabase.parse(json("""
        {"product":{"product_name":"Leitungswasser","nutriments":{"proteins_100g":0}}}
        """)) == nil)
    }

    @Test func ohneNamenWertlos() {
        #expect(FoodDatabase.parse(json("""
        {"product":{"product_name":"","nutriments":{"energy-kcal_100g":250}}}
        """)) == nil)
    }
}
