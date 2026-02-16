import XCTest
@testable import Chrono

final class DEIntegrationRegressionTests: XCTestCase {
    private let referenceDate = Date(timeIntervalSince1970: 1_735_689_600) // 2025-01-01T00:00:00Z
    private let options = ParsingOptions(forwardDate: true)

    func testCasualRegressionPhrasesAreParseable() {
        let parser = Chrono.de.casual
        let phrases = [
            "heute",
            "in 2 wochen",
            "juni",
            "juni 9",
            "montag",
            "in 2 tagen",
            "nächsten monat",
            "nächstes jahr"
        ]

        for phrase in phrases {
            let results = parser.parse(text: phrase, referenceDate: referenceDate, options: options)
            XCTAssertFalse(results.isEmpty, "Expected phrase to parse in German casual mode: \(phrase)")
        }
    }

    func testCasualRegressionSemantics() {
        let parser = Chrono.de.casual
        let calendar = Calendar.current

        let weeks = parser.parse(text: "in 2 wochen", referenceDate: referenceDate, options: options)
        XCTAssertFalse(weeks.isEmpty)
        XCTAssertTrue(weeks[0].start.isCertain(.isoWeek) || weeks[0].start.isCertain(.isoWeekYear))

        let monthDay = parser.parse(text: "juni 9", referenceDate: referenceDate, options: options)
        XCTAssertFalse(monthDay.isEmpty)
        XCTAssertEqual(monthDay[0].start.get(.month), 6)
        XCTAssertEqual(monthDay[0].start.get(.day), 9)

        let monday = parser.parse(text: "montag", referenceDate: referenceDate, options: options)
        XCTAssertFalse(monday.isEmpty)
        let weekday = calendar.component(.weekday, from: monday[0].start.date)
        XCTAssertEqual(weekday, 2)
    }

    func testStrictRegressionPhrasesAreParseable() {
        let parser = Chrono.de.strict
        let phrases = [
            "in 2 wochen",
            "juni 9",
            "nächsten monat",
            "nächstes jahr"
        ]

        for phrase in phrases {
            let results = parser.parse(text: phrase, referenceDate: referenceDate, options: options)
            XCTAssertFalse(results.isEmpty, "Expected phrase to parse in German strict mode: \(phrase)")
        }
    }
}
