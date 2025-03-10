// CustomParserTests.swift - Tests for custom parser registration
import Testing
import Foundation
@testable import Chrono

/// Custom date parser for testing
final class ChristmasParser: Parser {
    public func pattern(context: ParsingContext) -> String {
        return "\\bChristmas\\b|\\bXmas\\b"
    }
    
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let component = context.createParsingComponents()
        
        // Christmas is on December 25th
        component.assign(.month, value: 12)
        component.assign(.day, value: 25)
        
        // Year is from reference date
        let calendar = Calendar.current
        let year = calendar.component(.year, from: context.refDate)
        component.assign(.year, value: year)
        
        component.addTag("ChristmasParser")
        return component
    }
}

/// Tests for custom parser registration
@Test func customParserRegistrationTest() async throws {
    // Create a custom parser based on the Chrono.casual configuration
    var customParser = Chrono.casual.clone()
    customParser.addParser(ChristmasParser())
    
    // Reference date: August 10, 2012
    let refDate = makeTestDate(year: 2012, month: 8, day: 10)
    
    // Test parsing "Christmas"
    let christmasResults = customParser.parse(text: "Let's meet on Christmas", referenceDate: refDate)
    #expect(christmasResults.count == 1)
    #expect(christmasResults[0].text == "Christmas")
    
    // Christmas should be December 25th of the reference year
    let expectedDate = makeTestDate(year: 2012, month: 12, day: 25)
    let calendar = Calendar.current
    #expect(calendar.isDate(christmasResults[0].start.date, inSameDayAs: expectedDate))
    
    // Also test "Xmas" variant
    let xmasResults = customParser.parse(text: "Let's meet on Xmas", referenceDate: refDate)
    #expect(xmasResults.count == 1)
    #expect(xmasResults[0].text == "Xmas")
    #expect(calendar.isDate(xmasResults[0].start.date, inSameDayAs: expectedDate))
    
    // The standard parser should not recognize "Christmas"
    let standardResults = Chrono.casual.parse(text: "Let's meet on Christmas", referenceDate: refDate)
    #expect(standardResults.count == 0)
}

/// Custom refiner for testing
final class EveningTimeAdjustRefiner: Refiner {
    public func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        // For each result, if the time is between 1:00 and 4:00 with no meridiem specified,
        // assume it's PM (13:00 - 16:00)
        for result in results {
            if !result.start.isCertain(.meridiem) &&
               result.start.isCertain(.hour) {
                if let hour = result.start.get(.hour),
                   hour >= 1 && hour < 4 {
                    // Set meridiem to PM
                    result.start.assign(.meridiem, value: Meridiem.pm.rawValue)
                    
                    // Convert to 24-hour format (add 12 to get PM time)
                    result.start.assign(.hour, value: hour + 12)
                }
            }
        }
        
        return results
    }
}

/// Tests for custom refiner registration
@Test func customRefinerRegistrationTest() async throws {
    // Create a custom parser with our evening time adjust refiner
    var customParser = Chrono.casual.clone()
    customParser.addRefiner(EveningTimeAdjustRefiner())
    
    // Reference date: August 10, 2012
    let refDate = makeTestDate(year: 2012, month: 8, day: 10)
    
    // Test time "at 2:30" - should be adjusted to 14:30 with our custom refiner
    let timeResults = customParser.parse(text: "Let's meet at 2:30", referenceDate: refDate)
    #expect(timeResults.count == 1)
    
    let calendar = Calendar.current
    let timeComponents = calendar.dateComponents([.hour, .minute], from: timeResults[0].start.date)
    #expect(timeComponents.hour == 14) // Should be adjusted to PM (2 PM = 14:00)
    #expect(timeComponents.minute == 30)
    
    // The standard parser would interpret "at 2:30" as 2:30 AM
    let standardResults = Chrono.casual.parse(text: "Let's meet at 2:30", referenceDate: refDate)
    #expect(standardResults.count == 1)
    
    let standardTimeComponents = calendar.dateComponents([.hour, .minute], from: standardResults[0].start.date)
    #expect(standardTimeComponents.hour == 2) // Standard behavior: assume AM
    #expect(standardTimeComponents.minute == 30)
    
    // Add a separate test for explicitly specifying AM
    // Create a custom parser for testing AM time recognition
    let amCustomParser = Chrono.casual.clone()
    
    let amTimeResults = amCustomParser.parse(text: "Let's meet at 2:30 AM", referenceDate: refDate)
    #expect(amTimeResults.count == 1)
    
    let amTimeComponents = calendar.dateComponents([.hour, .minute], from: amTimeResults[0].start.date)
    #expect(amTimeComponents.hour == 2) // Should be AM 
    #expect(amTimeComponents.minute == 30)
}
