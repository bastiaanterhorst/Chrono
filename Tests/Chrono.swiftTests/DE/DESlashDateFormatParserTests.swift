import Testing
import Foundation
@testable import Chrono_swift

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
    
    // Test without "am" prefix
    let results4 = Chrono.de.casual.parse(text: "Sehen Sie sich den Bericht vom 31/01/2022 an")
    
    #expect(results4.count == 1)
    #expect(results4[0].text == "31/01/2022")
    
    let date4 = results4[0].start.date
    #expect(calendar.component(.day, from: date4) == 31)
    #expect(calendar.component(.month, from: date4) == 1)
    #expect(calendar.component(.year, from: date4) == 2022)
}