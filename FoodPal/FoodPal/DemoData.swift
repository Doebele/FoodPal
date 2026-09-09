#if DEBUG
import SwiftData
import Foundation
import UIKit

/// Beispieltag für die Sichtprüfung, solange es keinen Erfassungs-Screen gibt.
/// Läuft nur im Debug-Build und nur, wenn der Speicher leer ist.
enum DemoData {
    static func seedIfEmpty(_ context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<Entry>())) ?? 0
        guard existing == 0 else { return }

        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        // Zwei zurueckliegende Tage, damit sich Wischen und Pfeile pruefen lassen.
        for back in 1...2 {
            guard let day = cal.date(byAdding: .day, value: -back, to: today) else { continue }
            func past(_ hour: Int, _ minute: Int) -> Date {
                day.addingTimeInterval(TimeInterval(hour * 3600 + minute * 60))
            }
            let offset = Double(back) * 40
            context.insert(Entry(date: past(7, 20), name: "Espresso", kind: .coffee, kcal: 2, caffeineMg: 63))
            context.insert(Entry(date: past(8, 40), name: "Porridge", kind: .meal, kcal: 390 + offset,
                                 proteinG: 11, carbsG: 58, fatG: 8))
            context.insert(Entry(date: past(13, 10), name: "Linsensuppe", kind: .meal, kcal: 540 - offset,
                                 proteinG: 22, carbsG: 61, fatG: 14))
            context.insert(Entry(date: past(16, 0), name: "Cappuccino", kind: .coffee, kcal: 74, caffeineMg: 63))
            context.insert(Entry(date: past(19, 30), name: "Pasta", kind: .meal, kcal: 700 + offset,
                                 proteinG: 24, carbsG: 96, fatG: 19))
        }

        let day = today
        func at(_ hour: Int, _ minute: Int) -> Date {
            day.addingTimeInterval(TimeInterval(hour * 3600 + minute * 60))
        }

        let samples = [
            Entry(date: at(7, 10), name: "Espresso", kind: .coffee, kcal: 2, caffeineMg: 63),
            Entry(date: at(8, 25), name: "Porridge mit Beeren", kind: .meal, kcal: 410,
                  proteinG: 12, carbsG: 62, fatG: 9),
            Entry(date: at(10, 30), name: "Cappuccino", kind: .coffee, kcal: 74, caffeineMg: 63),
            Entry(date: at(12, 40), name: "Bowl mit Lachs", kind: .meal, kcal: 620,
                  proteinG: 34, carbsG: 52, fatG: 21),
            Entry(date: at(15, 5), name: "Espresso", kind: .coffee, kcal: 2, caffeineMg: 63),
            Entry(date: at(19, 15), name: "Ofengemüse", kind: .meal, kcal: 741,
                  proteinG: 18, carbsG: 74, fatG: 33)
        ]
        for entry in samples { context.insert(entry) }

        // Je ein Eintrag mit Bild, damit sich die Detailansicht mit Foto und
        // mit erzeugtem Bild pruefen laesst.
        samples[1].photo = placeholder(0xC9793A)
        samples[3].photo = placeholder(0x7A3A1B)
        samples[3].generatedImage = true
        // Steht fuer das mitgelieferte Sortenbild, solange es keins gibt —
        // nur damit sich Aufspreizen und Warenkunde pruefen lassen.
        samples[2].photo = placeholder(0x9A4A22)
    }

    /// Kein echtes Foto, nur eine Flaeche in Roestungsfarbe — es geht um das
    /// Layout, nicht um den Inhalt.
    private static func placeholder(_ hex: UInt32) -> Data? {
        let size = CGSize(width: 900, height: 600)
        let colour = UIColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
        return UIGraphicsImageRenderer(size: size).image { context in
            colour.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }.jpegData(compressionQuality: 0.7)
    }
}
#endif
