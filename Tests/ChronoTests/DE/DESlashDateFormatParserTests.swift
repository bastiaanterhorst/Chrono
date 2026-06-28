import Testing
import Foundation
@testable import Chrono

@Test func deSlashDateFormatTest() async throws {
    // Test DD/MM/YYYY format
    let results1 = Chrono.de.casual.parse(text: "Wir treffen uns am 28/09/2023")
    
    #expect(results1.count == 1)
    #expect(results1[0].text == "am 28/09/2023")
    
    // Check date components directly instead of relying on specific formatting
    let calendar = Calendar.current
    let date1 = results1[0].start.date
    #expect(calendar.component(.day, from: date1) == 28)
    #expect(calendar.component(.month, from: date1) == 9)
    #expect(calendar.component(.year, from: date1) == 2023)
    
    // Test DD/MM (current year)
    let results2 = Chrono.de.casual.parse(text: "Ich bin am 05/12 beschäftigt")
    
    // There may be multiple results with different parsers
    #expect(results2.count >= 1)
    
    // Find the result from our parser
    let result2 = results2.first(where: { $0.text.contains("05/12") })
    #expect(result2 != nil)
    
    if let result2 = result2 {
        let date2 = result2.start.date
        let currentYear = Calendar.current.component(.year, from: Date())
        #expect(calendar.component(.day, from: date2) == 5)
        #expect(calendar.component(.month, from: date2) == 12)
        #expect(calendar.component(.year, from: date2) == currentYear)
    }
    
    // Test DD-MM-YYYY format
    let results3 = Chrono.de.casual.parse(text: "Der Termin ist am 15-03-2024")
    
    // There may be multiple results with different parsers
    #expect(results3.count >= 1)
    
    // Find the result from our parser
    let result3 = results3.first(where: { $0.text.contains("15-03-2024") })
    #expect(result3 != nil)
    
    if let result3 = result3 {
        let date3 = result3.start.date
        #expect(calendar.component(.day, from: date3) == 15)
        #expect(calendar.component(.month, from: date3) == 3)
        #expect(calendar.component(.year, from: date3) == 2024)
    }
    
    // Test without "am" prefix. The parser now consumes the optional leading boundary space
    // (so its span aligns with the time parser's), hence the leading space in the matched text.
    let results4 = Chrono.de.casual.parse(text: "Sehen Sie sich den Bericht vom 31/01/2022 an")

    #expect(results4.count == 1)
    #expect(results4[0].text == " 31/01/2022")

    let date4 = results4[0].start.date
    #expect(calendar.component(.day, from: date4) == 31)
    #expect(calendar.component(.month, from: date4) == 1)
    #expect(calendar.component(.year, from: date4) == 2022)
}

/// Dotted dates are common in German (dd.mm). They must be parsed as dates, not times:
/// e.g. "14.9" means 14 September, NOT 14:09. A dotted token only stays a time when it cannot
/// be a valid date (e.g. "14.30" — month 30 is invalid).
@Test func deDottedDateIsDateNotTime() async throws {
    let calendar = Calendar.current

    func parseDay(_ text: String) -> (day: Int, month: Int, isDate: Bool, isTime: Bool) {
        let results = Chrono.de.casual.parse(text: text)
        guard let r = results.first(where: { $0.start.isCertain(.day) && $0.start.isCertain(.month) })
                ?? results.first else {
            return (0, 0, false, false)
        }
        let d = r.start.date
        return (calendar.component(.day, from: d),
                calendar.component(.month, from: d),
                r.start.isCertain(.day) && r.start.isCertain(.month),
                r.start.isCertain(.hour))
    }

    // "14.9" -> 14 September (date), not 14:09 (time)
    let r1 = parseDay("14.9")
    #expect(r1.isDate)
    #expect(!r1.isTime)
    #expect(r1.day == 14)
    #expect(r1.month == 9)

    // "15.6" / "15.06" -> 15 June
    for text in ["15.6", "15.06"] {
        let r = parseDay(text)
        #expect(r.isDate, "Expected \(text) to be a date")
        #expect(r.day == 15)
        #expect(r.month == 6)
    }

    // "31.12" -> 31 December
    let r2 = parseDay("31.12")
    #expect(r2.isDate)
    #expect(r2.day == 31)
    #expect(r2.month == 12)

    // Mid-sentence: "Zahnarzt 14.9" -> 14 September
    let r3 = parseDay("Zahnarzt 14.9")
    #expect(r3.isDate)
    #expect(r3.day == 14)
    #expect(r3.month == 9)

    // "14.30" is NOT a valid date (month 30) -> stays a time (14:30)
    let timeResults = Chrono.de.casual.parse(text: "14.30")
    #expect(timeResults.count >= 1)
    let timeFirst = timeResults[0]
    #expect(timeFirst.start.isCertain(.hour))
    #expect(!timeFirst.start.isCertain(.month))
    #expect(calendar.component(.hour, from: timeFirst.start.date) == 14)
    #expect(calendar.component(.minute, from: timeFirst.start.date) == 30)
}
