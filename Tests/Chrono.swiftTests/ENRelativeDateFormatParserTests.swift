import Testing
import Foundation
@testable import Chrono_swift

/// Tests for EN relative date format parser
@Test func enRelativeDateFormatParserTest() async throws {
    
    // Test parser directly with "2 days ago"
    let parser = ENRelativeDateFormatParser()
    let context = ParsingContext(
        text: "2 days ago",
        reference: ReferenceWithTimezone(),
        options: ParsingOptions()
    )
    
    // Direct extraction
    let regex = try! NSRegularExpression(pattern: parser.pattern(context: context), options: [])
    let match = TextMatch(
        match: regex.firstMatch(in: "2 days ago", options: [], range: NSRange(location: 0, length: "2 days ago".utf16.count))!,
        text: "2 days ago"
    )
    
    let component = parser.extract(context: context, match: match) as! ParsingComponents
    guard let parsedDate = component.date() else {
        #expect(false, "Failed to get date from component")
        return
    }
    
    // Check if the date is approximately 2 days ago
    let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
    #expect(Calendar.current.isDate(parsedDate, inSameDayAs: twoDaysAgo))
    
    // Test parser directly with "3 weeks from now"
    let parser2 = ENRelativeDateFormatParser()
    let context2 = ParsingContext(
        text: "3 weeks from now",
        reference: ReferenceWithTimezone(),
        options: ParsingOptions()
    )
    
    // Direct extraction
    let regex2 = try! NSRegularExpression(pattern: parser2.pattern(context: context2), options: [])
    let match2 = TextMatch(
        match: regex2.firstMatch(in: "3 weeks from now", options: [], range: NSRange(location: 0, length: "3 weeks from now".utf16.count))!,
        text: "3 weeks from now"
    )
    
    let component2 = parser2.extract(context: context2, match: match2) as! ParsingComponents
    guard let parsedDate2 = component2.date() else {
        #expect(false, "Failed to get date from component")
        return
    }
    
    // Check if the date is approximately 3 weeks in the future
    let threeWeeksLater = Calendar.current.date(byAdding: .day, value: 21, to: Date())!
    #expect(Calendar.current.isDate(parsedDate2, inSameDayAs: threeWeeksLater))
    
    // Test parser directly with "one month later"
    let parser3 = ENRelativeDateFormatParser()
    let context3 = ParsingContext(
        text: "one month later",
        reference: ReferenceWithTimezone(),
        options: ParsingOptions()
    )
    
    // Direct extraction
    let regex3 = try! NSRegularExpression(pattern: parser3.pattern(context: context3), options: [])
    let match3 = TextMatch(
        match: regex3.firstMatch(in: "one month later", options: [], range: NSRange(location: 0, length: "one month later".utf16.count))!,
        text: "one month later"
    )
    
    let component3 = parser3.extract(context: context3, match: match3) as! ParsingComponents
    guard let parsedDate3 = component3.date() else {
        #expect(false, "Failed to get date from component")
        return
    }
    
    // Check if the date is approximately 1 month in the future
    let oneMonthLater = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
    #expect(Calendar.current.isDate(parsedDate3, inSameDayAs: oneMonthLater))
}