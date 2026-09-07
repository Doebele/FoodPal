import Foundation
import UIKit
import Vision

/// Nährwerte aus Open Food Facts.
///
/// Kein Schlüssel, keine Registrierung — Lesen ist offen, verlangt aber einen
/// eigenen User-Agent; ohne den wird die IP irgendwann gesperrt. Dort steht die
/// Repo-Adresse statt einer Mailadresse: identifiziert die App genauso, ohne
/// eine private Adresse an einen fremden Server zu geben.
enum FoodDatabase {
    private static let agent = "FoodPal/1.0 (https://github.com/Doebele/FoodPal)"

    /// Liefert die Werte **je 100 g** — so hält die Datenbank sie vor, und die
    /// Umrechnung auf die gegessene Menge gehört in die Bestätigung, wo man sie
    /// sieht und korrigieren kann.
    static func lookup(_ barcode: String) async throws -> MealEstimate? {
        let fields = "product_name,product_name_de,brands,nutriments"
        guard let url = URL(string:
            "https://world.openfoodfacts.org/api/v2/product/\(barcode)?fields=\(fields)")
        else { return nil }

        var request = URLRequest(url: url)
        request.setValue(agent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 12

        let (data, _) = try await URLSession.shared.data(for: request)
        return parse(data)
    }

    /// Nachsichtig wie beim LLM-Parser, aber mit zwei harten Bedingungen: ohne
    /// Namen und ohne Energie ist der Treffer wertlos. Alles andere darf fehlen —
    /// die Daten sind crowdgesourct, einzelne Nährwertfelder fehlen häufig.
    static func parse(_ data: Data) -> MealEstimate? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let product = root["product"] as? [String: Any],
              let nutriments = product["nutriments"] as? [String: Any],
              let kcal = number(nutriments["energy-kcal_100g"]),
              let name = [product["product_name_de"], product["product_name"]]
                  .compactMap({ $0 as? String })
                  .first(where: { !$0.isEmpty })
        else { return nil }

        // Marke nur voranstellen, wenn sie nicht ohnehin im Namen steht —
        // sonst wird aus "Emmi Vollmilch" ein "Emmi Emmi Vollmilch".
        let brand = (product["brands"] as? String)?
            .split(separator: ",").first
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .flatMap { $0.isEmpty ? nil : $0 }

        return MealEstimate(
            name: brand.map { name.localizedCaseInsensitiveContains($0) ? name : "\($0) \(name)" } ?? name,
            kcal: kcal,
            proteinG: number(nutriments["proteins_100g"]),
            carbsG: number(nutriments["carbohydrates_100g"]),
            fatG: number(nutriments["fat_100g"])
        )
    }

    private static func number(_ value: Any?) -> Double? {
        if let value = value as? Double { return value }
        if let value = value as? Int { return Double(value) }
        if let text = value as? String {
            return Double(text.replacingOccurrences(of: ",", with: "."))
        }
        return nil
    }
}

/// Barcode im aufgenommenen Foto.
///
/// Kein eigener Scanner-Screen: du fotografierst die Mahlzeit ohnehin, also
/// wird dasselbe Bild vorher geprüft. Sitzt ein lesbarer EAN darauf, kommen
/// exakte Werte aus der Datenbank statt einer Schätzung; sonst läuft der
/// gewohnte Weg über das LLM weiter.
enum Barcode {
    /// Auf dem **Originalbild**, nicht auf der verkleinerten Fassung: bei
    /// 1024 px ist ein EAN aus normalem Abstand nicht mehr aufzulösen.
    static func read(_ image: UIImage) -> String? {
        guard let cgImage = image.cgImage else { return nil }
        let request = VNDetectBarcodesRequest()
        // UPC-A liefert Vision als EAN-13 — die drei decken Handel in
        // Europa und den USA ab.
        request.symbologies = [.ean13, .ean8, .upce]
        try? VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
        return request.results?.first?.payloadStringValue
    }
}
