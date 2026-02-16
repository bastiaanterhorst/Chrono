import XCTest
@testable import Chrono

final class ENISOWeekNumberParserTests: XCTestCase {
    
    func testBasicWeekNumberPatternAndExtract() {
        let parser = ENISOWeekNumberParser()
        
        // Create a test context
        let referenceDate = Date()
        let context = ParsingContext(
            text: "Week 42",
            reference: ReferenceWithTimezone(instant: referenceDate),
            options: ParsingOptions()
        )
        
        // Verify the pattern is valid
        let pattern = parser.pattern(context: context)
        XCTAssertFalse(pattern.isEmpty)
        
        // Create a regex and find a match
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
            
            XCTAssertEqual(result.text, "Week 42")
            XCTAssertEqual(result.start.get(.isoWeek), 42)
            XCTAssertTrue(result.start.isCertain(.isoWeek))
        }
    }
    
    func testBasicAbbreviatedWeekNumberPatternAndExtract() {
        let parser = ENISOWeekNumberParser()
        
        // Create a test context
        let referenceDate = Date()
        let context = ParsingContext(
            text: "Wk 42",
            reference: ReferenceWithTimezone(instant: referenceDate),
            options: ParsingOptions()
        )
        
        // Verify the pattern is valid
        let pattern = parser.pattern(context: context)
        XCTAssertFalse(pattern.isEmpty)
        
        // Create a regex and find a match
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
            
            XCTAssertEqual(result.text, "Wk 42")
            XCTAssertEqual(result.start.get(.isoWeek), 42)
            XCTAssertTrue(result.start.isCertain(.isoWeek))
        }
    }
    
    func testWeekNumberWithYearPatternAndExtract() {
        let parser = ENISOWeekNumberParser()
        
        // Create a test context
        let referenceDate = Date()
        let context = ParsingContext(
            text: "Week 15 2023",
            reference: ReferenceWithTimezone(instant: referenceDate),
            options: ParsingOptions()
        )
        
        // Create a regex and find a match
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
            
            XCTAssertEqual(result.text, "Week 15 2023")
            XCTAssertEqual(result.start.get(.isoWeek), 15)
            XCTAssertEqual(result.start.get(.isoWeekYear), 2023)
            XCTAssertTrue(result.start.isCertain(.isoWeek))
            XCTAssertTrue(result.start.isCertain(.isoWeekYear))
        }
    }
    
    func testWeekNumberWithShortYearPatternAndExtract() {
        let parser = ENISOWeekNumberParser()
        
        // Create a test context
        let referenceDate = Date()
        let context = ParsingContext(
            text: "Week 15 27",
            reference: ReferenceWithTimezone(instant: referenceDate),
            options: ParsingOptions()
        )
        
        // Create a regex and find a match
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
            
            XCTAssertEqual(result.start.get(.isoWeek), 15)
            XCTAssertEqual(result.start.get(.isoWeekYear), 2027)
            XCTAssertTrue(result.start.isCertain(.isoWeek))
            XCTAssertTrue(result.start.isCertain(.isoWeekYear))
        }
    }
    
    func testWeekNumberWithAlternateShortYearPatternAndExtract() {
        let parser = ENISOWeekNumberParser()
        
        // Create a test context
        let referenceDate = Date()
        let context = ParsingContext(
            text: "Wk 15 '23",
            reference: ReferenceWithTimezone(instant: referenceDate),
            options: ParsingOptions()
        )
        
        // Create a regex and find a match
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
            
            XCTAssertEqual(result.start.get(.isoWeek), 15)
            XCTAssertEqual(result.start.get(.isoWeekYear), 2023)
            XCTAssertTrue(result.start.isCertain(.isoWeek))
            XCTAssertTrue(result.start.isCertain(.isoWeekYear))
        }
    }
    
    func testISOFormatPatternAndExtract() {
        let testCases = [
            "2023-W15",
            "2024W42",
            "W15-2023",
            "W42/2024"
        ]
        
        let parser = ENISOWeekNumberParser()
        
        for testText in testCases {
            // Create a test context
            let context = ParsingContext(
                text: testText,
                reference: ReferenceWithTimezone(instant: Date()),
                options: ParsingOptions()
            )
            
            // Create a regex and find a match
            guard let regex = try? NSRegularExpression(pattern: parser.pattern(context: context), options: []) else {
                XCTFail("Failed to create regex from pattern for \(testText)")
                continue
            }
            
            let nsString = context.text as NSString
            let matches = regex.matches(in: context.text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            XCTAssertEqual(matches.count, 1, "Failed to match: \(testText)")
            
            // Test extraction
            if matches.count > 0 {
                let match = TextMatch(match: matches[0], text: context.text)
                guard let result = parser.extract(context: context, match: match) as? ParsedResult else {
                    XCTFail("Extraction failed for \(testText)")
                    continue
                }
                
                XCTAssertEqual(result.text, testText)
                
                switch testText {
                case "2023-W15", "W15-2023":
                    XCTAssertEqual(result.start.get(.isoWeek), 15)
                    XCTAssertEqual(result.start.get(.isoWeekYear), 2023)
                case "2024W42", "W42/2024":
                    XCTAssertEqual(result.start.get(.isoWeek), 42)
                    XCTAssertEqual(result.start.get(.isoWeekYear), 2024)
                default:
                    break
                }
            }
        }
    }
    
    func testPartialISOFormats() {
        let parser = ENISOWeekNumberParser()
        let currentYear = Calendar(identifier: .iso8601).component(.yearForWeekOfYear, from: Date())
        
        // Create a test context
        let context = ParsingContext(
            text: "W15",
            reference: ReferenceWithTimezone(instant: Date()),
            options: ParsingOptions()
        )
        
        // Create a regex and find a match
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
            
            XCTAssertEqual(result.text, "W15")
            XCTAssertEqual(result.start.get(.isoWeek), 15)
            XCTAssertEqual(result.start.get(.isoWeekYear), currentYear)
            XCTAssertTrue(result.start.isCertain(.isoWeek))
            XCTAssertFalse(result.start.isCertain(.isoWeekYear)) // Year is implied, not certain
        }
    }
    
    func testContextExtraction() {
        let parser = ENISOWeekNumberParser()
        
        // Create a test context
        let context = ParsingContext(
            text: "The meeting is scheduled for Week 15 of 2023",
            reference: ReferenceWithTimezone(instant: Date()),
            options: ParsingOptions()
        )
        
        // Create a regex and find a match
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
            
            XCTAssertEqual(result.text, "Week 15 of 2023")
            XCTAssertEqual(result.index, 27) // Position where "Week 15 of 2023" starts
            XCTAssertEqual(result.start.get(.isoWeek), 15)
            XCTAssertEqual(result.start.get(.isoWeekYear), 2023)
        }
    }
    
    func testDateGeneration() {
        let parser = ENISOWeekNumberParser()
        
        // Create a test context
        let context = ParsingContext(
            text: "Week 1 2023",
            reference: ReferenceWithTimezone(instant: Date()),
            options: ParsingOptions()
        )
        
        // Create a regex and find a match
        guard let regex = try? NSRegularExpression(pattern: parser.pattern(context: context), options: []) else {
            XCTFail("Failed to create regex from pattern")
            return
        }
        
        let nsString = context.text as NSString
        let matches = regex.matches(in: context.text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        XCTAssertEqual(matches.count, 1)
        
        // Test extraction and date generation
        if matches.count > 0 {
            let match = TextMatch(match: matches[0], text: context.text)
            guard let result = parser.extract(context: context, match: match) as? ParsedResult else {
                XCTFail("Extraction failed")
                return
            }
            
            let calendar = Calendar(identifier: .iso8601)
            let components = calendar.dateComponents([.year, .month, .day, .weekday], from: result.start.date)
            
            // Week 1 of 2023 should start on Monday, January 2, 2023
            XCTAssertEqual(components.year, 2023)
            XCTAssertEqual(components.month, 1)
            XCTAssertEqual(components.day, 2)
            XCTAssertEqual(components.weekday, 2) // Monday is 2 in ISO 8601
        }
    }
    
    func testInvalidInputs() {
        let parser = ENISOWeekNumberParser()
        
        // Test cases with invalid input
        let testCases = ["Week 0", "Week 54", "Week ABC"]
        
        for testText in testCases {
            // Create a test context
            let context = ParsingContext(
                text: testText,
                reference: ReferenceWithTimezone(instant: Date()),
                options: ParsingOptions()
            )
            
            // Create a regex and find a match
            guard let regex = try? NSRegularExpression(pattern: parser.pattern(context: context), options: []) else {
                XCTFail("Failed to create regex from pattern for \(testText)")
                continue
            }
            
            let nsString = context.text as NSString
            let matches = regex.matches(in: context.text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if matches.count > 0 {
                let match = TextMatch(match: matches[0], text: context.text)
                let result = parser.extract(context: context, match: match)
                
                // For invalid week numbers, extract should return nil
                XCTAssertNil(result, "Should return nil for invalid input: \(testText)")
            }
        }
    }
}
