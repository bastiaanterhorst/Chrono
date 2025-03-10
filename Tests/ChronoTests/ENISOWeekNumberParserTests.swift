import XCTest
@testable import Chrono

final class ENISOWeekNumberParserTests: XCTestCase {
    
    func testBasicWeekNumberParsing() {
        let parser = ENISOWeekNumberParser()
        
        // Test "Week 1"
        let resultWeek1 = parser.execute(text: "Week 1", ref: ReferenceWithTimezone(instant: Date(), timezone: nil))
        XCTAssertEqual(resultWeek1.count, 1)
        XCTAssertEqual(resultWeek1[0].text, "Week 1")
        XCTAssertEqual(resultWeek1[0].start.get(.isoWeek), 1)
        XCTAssertTrue(resultWeek1[0].start.isCertain(.isoWeek))
        
        // Test "Week 52"
        let resultWeek52 = parser.execute(text: "Week 52", ref: ReferenceWithTimezone(instant: Date(), timezone: nil))
        XCTAssertEqual(resultWeek52.count, 1)
        XCTAssertEqual(resultWeek52[0].text, "Week 52")
        XCTAssertEqual(resultWeek52[0].start.get(.isoWeek), 52)
        XCTAssertTrue(resultWeek52[0].start.isCertain(.isoWeek))
    }
    
    func testWeekNumberWithYear() {
        let parser = ENISOWeekNumberParser()
        
        // Test "Week 15 2023"
        let result1 = parser.execute(text: "Week 15 2023", ref: ReferenceWithTimezone(instant: Date(), timezone: nil))
        XCTAssertEqual(result1.count, 1)
        XCTAssertEqual(result1[0].text, "Week 15 2023")
        XCTAssertEqual(result1[0].start.get(.isoWeek), 15)
        XCTAssertEqual(result1[0].start.get(.isoWeekYear), 2023)
        XCTAssertTrue(result1[0].start.isCertain(.isoWeek))
        XCTAssertTrue(result1[0].start.isCertain(.isoWeekYear))
        
        // Test "Week 42, 2024"
        let result2 = parser.execute(text: "Week 42, 2024", ref: ReferenceWithTimezone(instant: Date(), timezone: nil))
        XCTAssertEqual(result2.count, 1)
        XCTAssertEqual(result2[0].text, "Week 42, 2024")
        XCTAssertEqual(result2[0].start.get(.isoWeek), 42)
        XCTAssertEqual(result2[0].start.get(.isoWeekYear), 2024)
        
        // Test "Week 30 of 2022"
        let result3 = parser.execute(text: "Week 30 of 2022", ref: ReferenceWithTimezone(instant: Date(), timezone: nil))
        XCTAssertEqual(result3.count, 1)
        XCTAssertEqual(result3[0].text, "Week 30 of 2022")
        XCTAssertEqual(result3[0].start.get(.isoWeek), 30)
        XCTAssertEqual(result3[0].start.get(.isoWeekYear), 2022)
    }
    
    func testISOFormats() {
        let parser = ENISOWeekNumberParser()
        
        // Test "2023-W15"
        let result1 = parser.execute(text: "2023-W15", ref: ReferenceWithTimezone(instant: Date(), timezone: nil))
        XCTAssertEqual(result1.count, 1)
        XCTAssertEqual(result1[0].text, "2023-W15")
        XCTAssertEqual(result1[0].start.get(.isoWeek), 15)
        XCTAssertEqual(result1[0].start.get(.isoWeekYear), 2023)
        
        // Test "2024W42"
        let result2 = parser.execute(text: "2024W42", ref: ReferenceWithTimezone(instant: Date(), timezone: nil))
        XCTAssertEqual(result2.count, 1)
        XCTAssertEqual(result2[0].text, "2024W42")
        XCTAssertEqual(result2[0].start.get(.isoWeek), 42)
        XCTAssertEqual(result2[0].start.get(.isoWeekYear), 2024)
        
        // Test "W15-2023"
        let result3 = parser.execute(text: "W15-2023", ref: ReferenceWithTimezone(instant: Date(), timezone: nil))
        XCTAssertEqual(result3.count, 1)
        XCTAssertEqual(result3[0].text, "W15-2023")
        XCTAssertEqual(result3[0].start.get(.isoWeek), 15)
        XCTAssertEqual(result3[0].start.get(.isoWeekYear), 2023)
        
        // Test "W42/2024"
        let result4 = parser.execute(text: "W42/2024", ref: ReferenceWithTimezone(instant: Date(), timezone: nil))
        XCTAssertEqual(result4.count, 1)
        XCTAssertEqual(result4[0].text, "W42/2024")
        XCTAssertEqual(result4[0].start.get(.isoWeek), 42)
        XCTAssertEqual(result4[0].start.get(.isoWeekYear), 2024)
    }
    
    func testPartialISOFormats() {
        let parser = ENISOWeekNumberParser()
        let currentYear = Calendar(identifier: .iso8601).component(.yearForWeekOfYear, from: Date())
        
        // Test "W15" (should use current year)
        let result1 = parser.execute(text: "W15", ref: ReferenceWithTimezone(instant: Date(), timezone: nil))
        XCTAssertEqual(result1.count, 1)
        XCTAssertEqual(result1[0].text, "W15")
        XCTAssertEqual(result1[0].start.get(.isoWeek), 15)
        XCTAssertEqual(result1[0].start.get(.isoWeekYear), currentYear)
        XCTAssertTrue(result1[0].start.isCertain(.isoWeek))
        XCTAssertFalse(result1[0].start.isCertain(.isoWeekYear)) // Year is implied, not certain
    }
    
    func testAbbreviatedYearFormats() {
        let parser = ENISOWeekNumberParser()
        
        // Test "Week 15 '23"
        let result1 = parser.execute(text: "Week 15 '23", ref: ReferenceWithTimezone(instant: Date(), timezone: nil))
        XCTAssertEqual(result1.count, 1)
        XCTAssertEqual(result1[0].text, "Week 15 '23")
        XCTAssertEqual(result1[0].start.get(.isoWeek), 15)
        XCTAssertEqual(result1[0].start.get(.isoWeekYear), 2023)
        
        // Test "W42'24"
        let result2 = parser.execute(text: "W42'24", ref: ReferenceWithTimezone(instant: Date(), timezone: nil))
        XCTAssertEqual(result2.count, 1)
        XCTAssertEqual(result2[0].text, "W42'24")
        XCTAssertEqual(result2[0].start.get(.isoWeek), 42)
        XCTAssertEqual(result2[0].start.get(.isoWeekYear), 2024)
    }
    
    func testConversationalFormats() {
        let parser = ENISOWeekNumberParser()
        let currentYear = Calendar(identifier: .iso8601).component(.yearForWeekOfYear, from: Date())
        
        // Test "the 15th week"
        let result1 = parser.execute(text: "the 15th week", ref: ReferenceWithTimezone(instant: Date(), timezone: nil))
        XCTAssertEqual(result1.count, 1)
        XCTAssertEqual(result1[0].text, "the 15th week")
        XCTAssertEqual(result1[0].start.get(.isoWeek), 15)
        XCTAssertEqual(result1[0].start.get(.isoWeekYear), currentYear)
        
        // Test "week number 42"
        let result2 = parser.execute(text: "week number 42", ref: ReferenceWithTimezone(instant: Date(), timezone: nil))
        XCTAssertEqual(result2.count, 1)
        XCTAssertEqual(result2[0].text, "week number 42")
        XCTAssertEqual(result2[0].start.get(.isoWeek), 42)
        XCTAssertEqual(result2[0].start.get(.isoWeekYear), currentYear)
        
        // Test "week #15"
        let result3 = parser.execute(text: "week #15", ref: ReferenceWithTimezone(instant: Date(), timezone: nil))
        XCTAssertEqual(result3.count, 1)
        XCTAssertEqual(result3[0].text, "week #15")
        XCTAssertEqual(result3[0].start.get(.isoWeek), 15)
        XCTAssertEqual(result3[0].start.get(.isoWeekYear), currentYear)
    }
    
    func testContextExtraction() {
        let parser = ENISOWeekNumberParser()
        
        // Test in a sentence
        let result = parser.execute(text: "The meeting is scheduled for Week 15 of 2023", ref: ReferenceWithTimezone(instant: Date(), timezone: nil))
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].text, "Week 15 of 2023")
        XCTAssertEqual(result[0].index, 27) // Position where "Week 15 of 2023" starts
        XCTAssertEqual(result[0].start.get(.isoWeek), 15)
        XCTAssertEqual(result[0].start.get(.isoWeekYear), 2023)
    }
    
    func testDateGeneration() {
        let parser = ENISOWeekNumberParser()
        
        // Test date calculation for Week 1 of 2023
        // Week 1 of 2023 should start on Monday, January 2, 2023
        let result = parser.execute(text: "Week 1 2023", ref: ReferenceWithTimezone(instant: Date(), timezone: nil))
        XCTAssertEqual(result.count, 1)
        
        let calendar = Calendar(identifier: .iso8601)
        let date = result[0].start.date
        let components = calendar.dateComponents([.year, .month, .day, .weekday], from: date)
        
        XCTAssertEqual(components.year, 2023)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 2)
        XCTAssertEqual(components.weekday, 2) // Monday is 2 in ISO 8601
    }
    
    func testInvalidInputs() {
        let parser = ENISOWeekNumberParser()
        
        // Test invalid week number (0)
        let result1 = parser.execute(text: "Week 0", ref: ReferenceWithTimezone(instant: Date(), timezone: nil))
        XCTAssertEqual(result1.count, 0)
        
        // Test invalid week number (54)
        let result2 = parser.execute(text: "Week 54", ref: ReferenceWithTimezone(instant: Date(), timezone: nil))
        XCTAssertEqual(result2.count, 0)
        
        // Test non-numeric input
        let result3 = parser.execute(text: "Week ABC", ref: ReferenceWithTimezone(instant: Date(), timezone: nil))
        XCTAssertEqual(result3.count, 0)
    }
}