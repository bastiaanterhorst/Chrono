import Testing
import Foundation
@testable import Chrono

@Test func deCasualDateParserTest() async {
    // Create a fixed reference date (2023-01-10)
    let refDate = ParsingReference(instant: createTestDate(2023, 1, 10))
    
    // Test "heute" (today)
    let results1 = Chrono.de.casual.parse(text: "Treffen wir uns heute", referenceDate: refDate)
    #expect(results1.count == 1)
    #expect(results1[0].text.trimmingCharacters(in: .whitespaces) == "heute")
    #expect(results1[0].start.get(.day) == 10)
    #expect(results1[0].start.get(.month) == 1)
    #expect(results1[0].start.get(.year) == 2023)
    
    // Test "morgen" (tomorrow)
    print("Testing morgen...")
    let results2 = Chrono.de.casual.parse(text: "Ich werde morgen ankommen", referenceDate: refDate)
    print("Parsed: \(results2.count) results")
    
    // Just check it found something
    #expect(results2.count > 0, "Should find at least one result from 'morgen'")
    if results2.count > 0 {
        print("Found: \(results2[0].text)")
        #expect(results2[0].text.contains("morgen"), "Text should contain 'morgen'")
        #expect(results2[0].start.get(.day) == 11, "Day should be 11")
        #expect(results2[0].start.get(.month) == 1, "Month should be 1")
        #expect(results2[0].start.get(.year) == 2023, "Year should be 2023")
    }
    
    // Test "übermorgen" (day after tomorrow)
    let results3 = Chrono.de.casual.parse(text: "Übermorgen ist das Meeting", referenceDate: refDate)
    #expect(results3.count == 1)
    #expect(results3[0].text.trimmingCharacters(in: .whitespaces) == "Übermorgen")
    #expect(results3[0].start.get(.day) == 12)
    #expect(results3[0].start.get(.month) == 1)
    #expect(results3[0].start.get(.year) == 2023)
}

// Helper method to create a date
private func createTestDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    
    return Calendar.current.date(from: components)!
}
