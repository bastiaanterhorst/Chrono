import XCTest
@testable import Chrono

final class ENRelativeWeekParserTests: XCTestCase {
    
    func testThisWeek() {
        let parser = ENRelativeWeekParser()
        let referenceDate = Date() // Current date for testing
        
        // Test "this week"
        let result = parser.execute(text: "this week", ref: ReferenceWithTimezone(instant: referenceDate, timezone: nil))
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].text, "this week")
        
        // The parsed date should be in the current week
        let calendar = Calendar(identifier: .iso8601)
        let currentWeek = calendar.component(.weekOfYear, from: referenceDate)
        let currentWeekYear = calendar.component(.yearForWeekOfYear, from: referenceDate)
        
        let parsedWeek = calendar.component(.weekOfYear, from: result[0].start.date)
        let parsedWeekYear = calendar.component(.yearForWeekOfYear, from: result[0].start.date)
        
        XCTAssertEqual(parsedWeek, currentWeek)
        XCTAssertEqual(parsedWeekYear, currentWeekYear)
        XCTAssertEqual(result[0].start.get(.isoWeek), currentWeek)
        XCTAssertEqual(result[0].start.get(.isoWeekYear), currentWeekYear)
        XCTAssertTrue(result[0].start.isCertain(.isoWeek))
        XCTAssertTrue(result[0].start.isCertain(.isoWeekYear))
    }
    
    func testNextWeek() {
        let parser = ENRelativeWeekParser()
        let referenceDate = Date()
        
        // Test "next week"
        let result = parser.execute(text: "next week", ref: ReferenceWithTimezone(instant: referenceDate, timezone: nil))
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].text, "next week")
        
        // Calculate expected next week
        let calendar = Calendar(identifier: .iso8601)
        let nextWeekDate = calendar.date(byAdding: .weekOfYear, value: 1, to: referenceDate)!
        let expectedWeek = calendar.component(.weekOfYear, from: nextWeekDate)
        let expectedWeekYear = calendar.component(.yearForWeekOfYear, from: nextWeekDate)
        
        // The parsed date should be in the next week
        XCTAssertEqual(result[0].start.get(.isoWeek), expectedWeek)
        XCTAssertEqual(result[0].start.get(.isoWeekYear), expectedWeekYear)
    }
    
    func testLastWeek() {
        let parser = ENRelativeWeekParser()
        let referenceDate = Date()
        
        // Test "last week"
        let result = parser.execute(text: "last week", ref: ReferenceWithTimezone(instant: referenceDate, timezone: nil))
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].text, "last week")
        
        // Calculate expected last week
        let calendar = Calendar(identifier: .iso8601)
        let lastWeekDate = calendar.date(byAdding: .weekOfYear, value: -1, to: referenceDate)!
        let expectedWeek = calendar.component(.weekOfYear, from: lastWeekDate)
        let expectedWeekYear = calendar.component(.yearForWeekOfYear, from: lastWeekDate)
        
        // The parsed date should be in the last week
        XCTAssertEqual(result[0].start.get(.isoWeek), expectedWeek)
        XCTAssertEqual(result[0].start.get(.isoWeekYear), expectedWeekYear)
    }
    
    func testWeeksAgo() {
        let parser = ENRelativeWeekParser()
        let referenceDate = Date()
        
        // Test patterns like "2 weeks ago", "3 weeks ago"
        for weeks in 1...5 {
            let text = "\(weeks) \(weeks == 1 ? "week" : "weeks") ago"
            let result = parser.execute(text: text, ref: ReferenceWithTimezone(instant: referenceDate, timezone: nil))
            
            XCTAssertEqual(result.count, 1, "Failed to parse: \(text)")
            XCTAssertEqual(result[0].text, text)
            
            // Calculate expected week
            let calendar = Calendar(identifier: .iso8601)
            let expectedDate = calendar.date(byAdding: .weekOfYear, value: -weeks, to: referenceDate)!
            let expectedWeek = calendar.component(.weekOfYear, from: expectedDate)
            let expectedWeekYear = calendar.component(.yearForWeekOfYear, from: expectedDate)
            
            // The parsed date should be the correct number of weeks ago
            XCTAssertEqual(result[0].start.get(.isoWeek), expectedWeek, "Wrong week for: \(text)")
            XCTAssertEqual(result[0].start.get(.isoWeekYear), expectedWeekYear, "Wrong year for: \(text)")
        }
    }
    
    func testWeeksLater() {
        let parser = ENRelativeWeekParser()
        let referenceDate = Date()
        
        // Test patterns like "in 2 weeks", "in 3 weeks"
        for weeks in 1...5 {
            let text = "in \(weeks) \(weeks == 1 ? "week" : "weeks")"
            let result = parser.execute(text: text, ref: ReferenceWithTimezone(instant: referenceDate, timezone: nil))
            
            XCTAssertEqual(result.count, 1, "Failed to parse: \(text)")
            XCTAssertEqual(result[0].text, text)
            
            // Calculate expected week
            let calendar = Calendar(identifier: .iso8601)
            let expectedDate = calendar.date(byAdding: .weekOfYear, value: weeks, to: referenceDate)!
            let expectedWeek = calendar.component(.weekOfYear, from: expectedDate)
            let expectedWeekYear = calendar.component(.yearForWeekOfYear, from: expectedDate)
            
            // The parsed date should be the correct number of weeks in the future
            XCTAssertEqual(result[0].start.get(.isoWeek), expectedWeek, "Wrong week for: \(text)")
            XCTAssertEqual(result[0].start.get(.isoWeekYear), expectedWeekYear, "Wrong year for: \(text)")
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
        let result1 = parser.execute(text: "the week before last", ref: ReferenceWithTimezone(instant: referenceDate, timezone: nil))
        XCTAssertEqual(result1.count, 1)
        XCTAssertEqual(result1[0].text, "the week before last")
        XCTAssertEqual(result1[0].start.get(.isoWeek), 52) // Last week of 2022
        XCTAssertEqual(result1[0].start.get(.isoWeekYear), 2022)
        
        // Test "the week after next"
        let result2 = parser.execute(text: "the week after next", ref: ReferenceWithTimezone(instant: referenceDate, timezone: nil))
        XCTAssertEqual(result2.count, 1)
        XCTAssertEqual(result2[0].text, "the week after next")
        XCTAssertEqual(result2[0].start.get(.isoWeek), 4) // Week 4 of 2023
        XCTAssertEqual(result2[0].start.get(.isoWeekYear), 2023)
    }
    
    func testContextExtraction() {
        let parser = ENRelativeWeekParser()
        let referenceDate = Date()
        
        // Test extraction from a sentence
        let result = parser.execute(text: "Let's schedule the meeting for next week", ref: ReferenceWithTimezone(instant: referenceDate, timezone: nil))
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].text, "next week")
        XCTAssertEqual(result[0].index, 30) // Position where "next week" starts
    }
}