import Testing
import Foundation
@testable import Chrono

/// Tests for EN time expression parser
@Test func enTimeExpressionParserTest() async throws {
    // Test "6:30pm"
    let timeParser = ENSimpleTimeParser()
    let context = ParsingContext(
        text: "6:30pm",
        reference: ReferenceWithTimezone(),
        options: ParsingOptions()
    )
    
    // Direct extraction
    let regex = try! NSRegularExpression(pattern: timeParser.pattern(context: context), options: [])
    let match = TextMatch(
        match: regex.firstMatch(in: "6:30pm", options: [], range: NSRange(location: 0, length: "6:30pm".utf16.count))!,
        text: "6:30pm"
    )
    
    let component = timeParser.extract(context: context, match: match) as! ParsingComponents
    guard let date = component.date() else {
        #expect(false, "Failed to get date from component")
        return
    }
    
    let calendar = Calendar.current
    
    #expect(calendar.component(.hour, from: date) == 18)
    #expect(calendar.component(.minute, from: date) == 30)
    
    // Through Chrono
    let results1 = Chrono.parse(text: "Let's meet at 6:30pm")
    
    // Find the result with "6:30" in it
    let timeResult = results1.first { $0.text.contains("6:30") }
    #expect(timeResult != nil)
    
    if let tr = timeResult {
        #expect(tr.start.get(.hour) == 18)
        #expect(tr.start.get(.minute) == 30)
    }
    
    // Test "noon"
    let results2 = Chrono.parse(text: "Let's meet at noon")
    
    #expect(results2.count == 1)
    #expect(results2[0].text == "at noon")
    
    #expect(results2[0].start.get(.hour) == 12)
    #expect(results2[0].start.get(.minute) == 0)
    
    // Test "midnight"
    let results3 = Chrono.parse(text: "at midnight")
    
    #expect(results3.count == 1)
    #expect(results3[0].text == "at midnight")
    
    #expect(results3[0].start.get(.hour) == 0)
    #expect(results3[0].start.get(.minute) == 0)
}
