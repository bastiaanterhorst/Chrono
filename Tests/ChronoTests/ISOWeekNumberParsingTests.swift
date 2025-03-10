import XCTest
@testable import Chrono

final class ISOWeekNumberParsingTests: XCTestCase {
    
    // Test adding ISO week number components
    func testISOWeekComponents() {
        let referenceDate = ReferenceWithTimezone(instant: Date())
        let components = ParsingComponents(reference: referenceDate)
        
        // Test assigning ISO week number
        components.assign(.isoWeek, value: 45)
        XCTAssertEqual(components.get(.isoWeek), 45)
        XCTAssertTrue(components.isCertain(.isoWeek))
        
        // Test assigning ISO week year
        components.assign(.isoWeekYear, value: 2023)
        XCTAssertEqual(components.get(.isoWeekYear), 2023)
        XCTAssertTrue(components.isCertain(.isoWeekYear))
        
        // Test implied values
        let components2 = ParsingComponents(reference: referenceDate)
        components2.imply(.isoWeek, value: 22)
        components2.imply(.isoWeekYear, value: 2024)
        
        XCTAssertEqual(components2.get(.isoWeek), 22)
        XCTAssertEqual(components2.get(.isoWeekYear), 2024)
        XCTAssertFalse(components2.isCertain(.isoWeek))
        XCTAssertFalse(components2.isCertain(.isoWeekYear))
        
        // Test clone preserves ISO week properties
        let cloned = components.clone()
        XCTAssertEqual(cloned.get(.isoWeek), 45)
        XCTAssertEqual(cloned.get(.isoWeekYear), 2023)
        XCTAssertTrue(cloned.isCertain(.isoWeek))
        XCTAssertTrue(cloned.isCertain(.isoWeekYear))
    }
    
    // Test conversion between ISO week and date
    func testISOWeekToDate() {
        // Create a components object for ISO week 1 of 2023
        let referenceDate = ReferenceWithTimezone(instant: Date())
        let components = ParsingComponents(reference: referenceDate)
        
        components.assign(.isoWeekYear, value: 2023)
        components.assign(.isoWeek, value: 1)
        
        // Week 1 of 2023 should start on Monday, January 2, 2023
        guard let date = components.date() else {
            XCTFail("Failed to convert components to date")
            return
        }
        
        let calendar = Calendar(identifier: .iso8601)
        let dateComponents = calendar.dateComponents([.year, .month, .day, .weekday], from: date)
        
        XCTAssertEqual(dateComponents.year, 2023)
        XCTAssertEqual(dateComponents.month, 1)
        XCTAssertEqual(dateComponents.day, 2)
        XCTAssertEqual(dateComponents.weekday, 2) // Monday is 2 in ISO calendar
    }
    
    // Test converting a date to ISO week components
    func testDateToISOWeek() {
        // Create a date for December 31, 2023 (which is in week 52 of 2023)
        let calendar = Calendar(identifier: .iso8601)
        var dateComponents = DateComponents()
        dateComponents.year = 2023
        dateComponents.month = 12
        dateComponents.day = 31
        
        guard let testDate = calendar.date(from: dateComponents) else {
            XCTFail("Failed to create test date")
            return
        }
        
        let reference = ReferenceWithTimezone(instant: testDate)
        let components = ParsingComponents(reference: reference)
        
        // The components should correctly imply the ISO week values
        XCTAssertEqual(components.get(.isoWeek), 52)
        XCTAssertEqual(components.get(.isoWeekYear), 2023)
        
        // Create a date for January 1, 2024 (which is in week 1 of 2024)
        dateComponents.year = 2024
        dateComponents.month = 1
        dateComponents.day = 1
        
        guard let testDate2 = calendar.date(from: dateComponents) else {
            XCTFail("Failed to create test date")
            return
        }
        
        let reference2 = ReferenceWithTimezone(instant: testDate2)
        let components2 = ParsingComponents(reference: reference2)
        
        // The components should correctly imply the ISO week values
        XCTAssertEqual(components2.get(.isoWeek), 1)
        XCTAssertEqual(components2.get(.isoWeekYear), 2024)
    }
    
    // Test edge cases: last few days of year that fall in week 1 of next year
    func testISOWeekEdgeCases() {
        // December 30, 2019 is in week 1 of 2020
        let calendar = Calendar(identifier: .iso8601)
        var dateComponents = DateComponents()
        dateComponents.year = 2019
        dateComponents.month = 12
        dateComponents.day = 30
        
        guard let testDate = calendar.date(from: dateComponents) else {
            XCTFail("Failed to create test date")
            return
        }
        
        let reference = ReferenceWithTimezone(instant: testDate)
        let components = ParsingComponents(reference: reference)
        
        // The components should correctly imply the ISO week values
        XCTAssertEqual(components.get(.isoWeek), 1)
        XCTAssertEqual(components.get(.isoWeekYear), 2020)
    }
}