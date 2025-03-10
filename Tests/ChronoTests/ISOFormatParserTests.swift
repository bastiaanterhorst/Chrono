import Testing
import Foundation
@testable import Chrono

@Test func isoFormatParserTest() async {
    // Test basic ISO format (YYYY-MM-DD)
    let results1 = Chrono.parse(text: "Meeting on 2023-01-15")
    
    #expect(results1.count == 1)
    #expect(results1[0].text.trimmingCharacters(in: .whitespaces) == "2023-01-15")
    #expect(results1[0].start.get(.day) == 15)
    #expect(results1[0].start.get(.month) == 1)
    #expect(results1[0].start.get(.year) == 2023)
    
    // Test ISO format with time (YYYY-MM-DDThh:mm)
    let results2 = Chrono.parse(text: "Meeting at 2023-01-15T14:30")
    
    #expect(results2.count == 1)
    #expect(results2[0].text.trimmingCharacters(in: .whitespaces) == "2023-01-15T14:30")
    #expect(results2[0].start.get(.day) == 15)
    #expect(results2[0].start.get(.month) == 1)
    #expect(results2[0].start.get(.year) == 2023)
    #expect(results2[0].start.get(.hour) == 14)
    #expect(results2[0].start.get(.minute) == 30)
    
    // Test ISO format with seconds (YYYY-MM-DDThh:mm:ss)
    let results3 = Chrono.parse(text: "Meeting at 2023-01-15T14:30:45")
    
    #expect(results3.count == 1)
    #expect(results3[0].text.trimmingCharacters(in: .whitespaces) == "2023-01-15T14:30:45")
    #expect(results3[0].start.get(.day) == 15)
    #expect(results3[0].start.get(.month) == 1)
    #expect(results3[0].start.get(.year) == 2023)
    #expect(results3[0].start.get(.hour) == 14)
    #expect(results3[0].start.get(.minute) == 30)
    #expect(results3[0].start.get(.second) == 45)
    
    // Test ISO format with timezone (YYYY-MM-DDThh:mm:ssZ)
    let results4 = Chrono.parse(text: "Meeting at 2023-01-15T14:30:45Z")
    
    #expect(results4.count == 1)
    #expect(results4[0].text.trimmingCharacters(in: .whitespaces) == "2023-01-15T14:30:45Z")
    #expect(results4[0].start.get(.day) == 15)
    #expect(results4[0].start.get(.month) == 1)
    #expect(results4[0].start.get(.year) == 2023)
    #expect(results4[0].start.get(.hour) == 14)
    #expect(results4[0].start.get(.minute) == 30)
    #expect(results4[0].start.get(.second) == 45)
    #expect(results4[0].start.get(.timezoneOffset) == 0)
    
    // Test ISO format with timezone offset (YYYY-MM-DDThh:mm:ss+hh:mm)
    let results5 = Chrono.parse(text: "Meeting at 2023-01-15T14:30:45+02:00")
    
    #expect(results5.count == 1)
    #expect(results5[0].text.trimmingCharacters(in: .whitespaces) == "2023-01-15T14:30:45+02:00")
    #expect(results5[0].start.get(.day) == 15)
    #expect(results5[0].start.get(.month) == 1)
    #expect(results5[0].start.get(.year) == 2023)
    #expect(results5[0].start.get(.hour) == 14)
    #expect(results5[0].start.get(.minute) == 30)
    #expect(results5[0].start.get(.second) == 45)
    #expect(results5[0].start.get(.timezoneOffset) == 120) // +02:00 = 120 minutes
    
    // Test ISO format with negative timezone offset (YYYY-MM-DDThh:mm:ss-hh:mm)
    let results6 = Chrono.parse(text: "Meeting at 2023-01-15T14:30:45-05:30")
    
    #expect(results6.count == 1)
    #expect(results6[0].text.trimmingCharacters(in: .whitespaces) == "2023-01-15T14:30:45-05:30")
    #expect(results6[0].start.get(.day) == 15)
    #expect(results6[0].start.get(.month) == 1)
    #expect(results6[0].start.get(.year) == 2023)
    #expect(results6[0].start.get(.hour) == 14)
    #expect(results6[0].start.get(.minute) == 30)
    #expect(results6[0].start.get(.second) == 45)
    #expect(results6[0].start.get(.timezoneOffset) == -330) // -05:30 = -330 minutes
    
    // Test parsing milliseconds
    let results7 = Chrono.parse(text: "Timestamp: 2023-01-15T14:30:45.123Z")
    
    #expect(results7.count == 1)
    #expect(results7[0].text.trimmingCharacters(in: .whitespaces) == "2023-01-15T14:30:45.123Z")
    #expect(results7[0].start.get(.day) == 15)
    #expect(results7[0].start.get(.month) == 1)
    #expect(results7[0].start.get(.year) == 2023)
    #expect(results7[0].start.get(.hour) == 14)
    #expect(results7[0].start.get(.minute) == 30)
    #expect(results7[0].start.get(.second) == 45)
    #expect(results7[0].start.get(.millisecond) == 123)
    #expect(results7[0].start.get(.timezoneOffset) == 0)
}
