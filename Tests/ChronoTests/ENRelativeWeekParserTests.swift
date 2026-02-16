import XCTest
@testable import Chrono

final class ENRelativeWeekParserTests: XCTestCase {
    
    func testThisWeekPatternAndExtract() {
        let parser = ENRelativeWeekParser()
        let referenceDate = Date() // Current date for testing
        
        // Create test context
        let context = ParsingContext(
            text: "this week",
            reference: ReferenceWithTimezone(instant: referenceDate),
            options: ParsingOptions()
        )
        
        // Verify pattern is valid
        let pattern = parser.pattern(context: context)
        XCTAssertFalse(pattern.isEmpty)
        
        // Create regex and find match
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            XCTFail("Failed to create regex from pattern")
            return
        }
        
        let nsString = context.text as NSString
        let matches = regex.matches(in: context.text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        XCTAssertEqual(matches.count, 1)
        
        // Test extraction
        if matches.count > 0 {
            let match = TextMatch(match: matches[0], text: context.text)
            guard let result = parser.extract(context: context, match: match) as? ParsedResult else {
                XCTFail("Extraction failed")
                return
            }
            
            XCTAssertEqual(result.text, "this week")
            
            // The parsed date should be in the current week
            let calendar = Calendar(identifier: .iso8601)
            let currentWeek = calendar.component(.weekOfYear, from: referenceDate)
            let currentWeekYear = calendar.component(.yearForWeekOfYear, from: referenceDate)
            
            let parsedWeek = calendar.component(.weekOfYear, from: result.start.date)
            let parsedWeekYear = calendar.component(.yearForWeekOfYear, from: result.start.date)
            
            XCTAssertEqual(parsedWeek, currentWeek)
            XCTAssertEqual(parsedWeekYear, currentWeekYear)
            XCTAssertEqual(result.start.get(.isoWeek), currentWeek)
            XCTAssertEqual(result.start.get(.isoWeekYear), currentWeekYear)
            XCTAssertTrue(result.start.isCertain(.isoWeek))
            XCTAssertTrue(result.start.isCertain(.isoWeekYear))
        }
    }
    
    func testNextWeekPatternAndExtract() {
        let parser = ENRelativeWeekParser()
        let referenceDate = Date()
        
        // Create test context
        let context = ParsingContext(
            text: "next week",
            reference: ReferenceWithTimezone(instant: referenceDate),
            options: ParsingOptions()
        )
        
        // Create regex and find match
        guard let regex = try? NSRegularExpression(pattern: parser.pattern(context: context), options: []) else {
            XCTFail("Failed to create regex from pattern")
            return
        }
        
        let nsString = context.text as NSString
        let matches = regex.matches(in: context.text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        XCTAssertEqual(matches.count, 1)
        
        // Test extraction
        if matches.count > 0 {
            let match = TextMatch(match: matches[0], text: context.text)
            guard let result = parser.extract(context: context, match: match) as? ParsedResult else {
                XCTFail("Extraction failed")
                return
            }
            
            XCTAssertEqual(result.text, "next week")
            
            // Calculate expected next week
            let calendar = Calendar(identifier: .iso8601)
            let nextWeekDate = calendar.date(byAdding: .weekOfYear, value: 1, to: referenceDate)!
            let expectedWeek = calendar.component(.weekOfYear, from: nextWeekDate)
            let expectedWeekYear = calendar.component(.yearForWeekOfYear, from: nextWeekDate)
            
            // The parsed date should be in the next week
            XCTAssertEqual(result.start.get(.isoWeek), expectedWeek)
            XCTAssertEqual(result.start.get(.isoWeekYear), expectedWeekYear)
        }
    }
    
    func testLastWeekPatternAndExtract() {
        let parser = ENRelativeWeekParser()
        let referenceDate = Date()
        
        // Create test context
        let context = ParsingContext(
            text: "last week",
            reference: ReferenceWithTimezone(instant: referenceDate),
            options: ParsingOptions()
        )
        
        // Create regex and find match
        guard let regex = try? NSRegularExpression(pattern: parser.pattern(context: context), options: []) else {
            XCTFail("Failed to create regex from pattern")
            return
        }
        
        let nsString = context.text as NSString
        let matches = regex.matches(in: context.text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        XCTAssertEqual(matches.count, 1)
        
        // Test extraction
        if matches.count > 0 {
            let match = TextMatch(match: matches[0], text: context.text)
            guard let result = parser.extract(context: context, match: match) as? ParsedResult else {
                XCTFail("Extraction failed")
                return
            }
            
            XCTAssertEqual(result.text, "last week")
            
            // Calculate expected last week
            let calendar = Calendar(identifier: .iso8601)
            let lastWeekDate = calendar.date(byAdding: .weekOfYear, value: -1, to: referenceDate)!
            let expectedWeek = calendar.component(.weekOfYear, from: lastWeekDate)
            let expectedWeekYear = calendar.component(.yearForWeekOfYear, from: lastWeekDate)
            
            // The parsed date should be in the last week
            XCTAssertEqual(result.start.get(.isoWeek), expectedWeek)
            XCTAssertEqual(result.start.get(.isoWeekYear), expectedWeekYear)
        }
    }
    
    func testWeeksAgoPatternAndExtract() {
        let parser = ENRelativeWeekParser()
        let referenceDate = Date()
        
        // Test "2 weeks ago"
        let context = ParsingContext(
            text: "2 weeks ago",
            reference: ReferenceWithTimezone(instant: referenceDate),
            options: ParsingOptions()
        )
        
        // Create regex and find match
        guard let regex = try? NSRegularExpression(pattern: parser.pattern(context: context), options: []) else {
            XCTFail("Failed to create regex from pattern")
            return
        }
        
        let nsString = context.text as NSString
        let matches = regex.matches(in: context.text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        XCTAssertEqual(matches.count, 1)
        
        // Test extraction
        if matches.count > 0 {
            let match = TextMatch(match: matches[0], text: context.text)
            guard let result = parser.extract(context: context, match: match) as? ParsedResult else {
                XCTFail("Extraction failed")
                return
            }
            
            XCTAssertEqual(result.text, "2 weeks ago")
            
            // Calculate expected week
            let calendar = Calendar(identifier: .iso8601)
            let expectedDate = calendar.date(byAdding: .weekOfYear, value: -2, to: referenceDate)!
            let expectedWeek = calendar.component(.weekOfYear, from: expectedDate)
            let expectedWeekYear = calendar.component(.yearForWeekOfYear, from: expectedDate)
            
            // The parsed date should be the correct number of weeks ago
            XCTAssertEqual(result.start.get(.isoWeek), expectedWeek)
            XCTAssertEqual(result.start.get(.isoWeekYear), expectedWeekYear)
        }
    }
    
    func testWeeksLaterPatternAndExtract() {
        let parser = ENRelativeWeekParser()
        let referenceDate = Date()
        
        // Test "in 2 weeks"
        let context = ParsingContext(
            text: "in 2 weeks",
            reference: ReferenceWithTimezone(instant: referenceDate),
            options: ParsingOptions()
        )
        
        // Create regex and find match
        guard let regex = try? NSRegularExpression(pattern: parser.pattern(context: context), options: []) else {
            XCTFail("Failed to create regex from pattern")
            return
        }
        
        let nsString = context.text as NSString
        let matches = regex.matches(in: context.text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        XCTAssertEqual(matches.count, 1)
        
        // Test extraction
        if matches.count > 0 {
            let match = TextMatch(match: matches[0], text: context.text)
            guard let result = parser.extract(context: context, match: match) as? ParsedResult else {
                XCTFail("Extraction failed")
                return
            }
            
            XCTAssertEqual(result.text, "in 2 weeks")
            
            // Calculate expected week
            let calendar = Calendar(identifier: .iso8601)
            let expectedDate = calendar.date(byAdding: .weekOfYear, value: 2, to: referenceDate)!
            let expectedWeek = calendar.component(.weekOfYear, from: expectedDate)
            let expectedWeekYear = calendar.component(.yearForWeekOfYear, from: expectedDate)
            
            // The parsed date should be the correct number of weeks in the future
            XCTAssertEqual(result.start.get(.isoWeek), expectedWeek)
            XCTAssertEqual(result.start.get(.isoWeekYear), expectedWeekYear)
        }
    }
    
    func testWeekSpecificWithReference() {
        let parser = ENRelativeWeekParser()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Use January 15, 2023 (Week 2) as reference date
        guard let referenceDate = dateFormatter.date(from: "2023-01-15") else {
            XCTFail("Failed to create reference date")
            return
        }
        
        // Test "the week before last"
        let context1 = ParsingContext(
            text: "the week before last",
            reference: ReferenceWithTimezone(instant: referenceDate),
            options: ParsingOptions()
        )
        
        // Create regex and find match
        guard let regex1 = try? NSRegularExpression(pattern: parser.pattern(context: context1), options: []) else {
            XCTFail("Failed to create regex from pattern")
            return
        }
        
        let nsString1 = context1.text as NSString
        let matches1 = regex1.matches(in: context1.text, options: [], range: NSRange(location: 0, length: nsString1.length))
        
        XCTAssertEqual(matches1.count, 1)
        
        if matches1.count > 0 {
            let match = TextMatch(match: matches1[0], text: context1.text)
            guard let result = parser.extract(context: context1, match: match) as? ParsedResult else {
                XCTFail("Extraction failed")
                return
            }
            
            XCTAssertEqual(result.text, "the week before last")
            XCTAssertEqual(result.start.get(.isoWeek), 52) // Last week of 2022
            XCTAssertEqual(result.start.get(.isoWeekYear), 2022)
        }
    }
    
    func testContextExtraction() {
        let parser = ENRelativeWeekParser()
        let referenceDate = Date()
        
        // Test extraction from a sentence
        let context = ParsingContext(
            text: "Let's schedule the meeting for next week",
            reference: ReferenceWithTimezone(instant: referenceDate),
            options: ParsingOptions()
        )
        
        // Create regex and find match
        guard let regex = try? NSRegularExpression(pattern: parser.pattern(context: context), options: []) else {
            XCTFail("Failed to create regex from pattern")
            return
        }
        
        let nsString = context.text as NSString
        let matches = regex.matches(in: context.text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        XCTAssertEqual(matches.count, 1)
        
        if matches.count > 0 {
            let match = TextMatch(match: matches[0], text: context.text)
            guard let result = parser.extract(context: context, match: match) as? ParsedResult else {
                XCTFail("Extraction failed")
                return
            }
            
            XCTAssertEqual(result.text, "next week")
            XCTAssertEqual(result.index, 30) // Position where "next week" starts
        }
    }
}