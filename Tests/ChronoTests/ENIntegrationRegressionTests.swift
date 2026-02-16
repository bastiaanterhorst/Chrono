import XCTest
@testable import Chrono

final class ENIntegrationRegressionTests: XCTestCase {
    private let referenceDate = Date(timeIntervalSince1970: 1_735_689_600) // 2025-01-01T00:00:00Z
    private let options = ParsingOptions(forwardDate: true)

    func testCasualRegressionPhrasesAreParseable() {
        let parser = Chrono.casual
        let phrases = [
            "today",
            "in 2 weeks",
            "june 9",
            "monday",
            "in 2 days",
            "next month",
            "next year"
        ]

        for phrase in phrases {
            let results = parser.parse(text: phrase, referenceDate: referenceDate, options: options)
            XCTAssertFalse(results.isEmpty, "Expected phrase to parse in casual mode: \(phrase)")
        }
    }

    func testCasualRegressionSemantics() {
        let parser = Chrono.casual
        let calendar = Calendar.current

        let weeks = parser.parse(text: "in 2 weeks", referenceDate: referenceDate, options: options)
        XCTAssertFalse(weeks.isEmpty)
        XCTAssertTrue(weeks[0].start.isCertain(.isoWeek) || weeks[0].start.isCertain(.isoWeekYear))

        let monthDay = parser.parse(text: "june 9", referenceDate: referenceDate, options: options)
        XCTAssertFalse(monthDay.isEmpty)
        XCTAssertEqual(monthDay[0].start.get(.month), 6)
        XCTAssertEqual(monthDay[0].start.get(.day), 9)

        let monday = parser.parse(text: "monday", referenceDate: referenceDate, options: options)
        XCTAssertFalse(monday.isEmpty)
        let weekday = calendar.component(.weekday, from: monday[0].start.date)
        XCTAssertEqual(weekday, 2) // Monday in Calendar
    }

    func testStrictSupportsRelativeUnitKeywords() {
        let parser = Chrono.strict
        let phrases = [
            "in 2 weeks",
            "next month",
            "next year"
        ]

        for phrase in phrases {
            let results = parser.parse(text: phrase, referenceDate: referenceDate, options: options)
            XCTAssertFalse(results.isEmpty, "Expected phrase to parse in strict mode: \(phrase)")
        }
    }
}
