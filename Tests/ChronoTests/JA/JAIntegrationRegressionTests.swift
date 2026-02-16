import XCTest
@testable import Chrono

final class JAIntegrationRegressionTests: XCTestCase {
    private let referenceDate = Date(timeIntervalSince1970: 1_735_689_600) // 2025-01-01T00:00:00Z
    private let options = ParsingOptions(forwardDate: true)

    func testCasualRegressionPhrasesAreParseable() {
        let parser = Chrono.ja.casual
        let phrases = [
            "今日",
            "2週間後",
            "6月",
            "6月9日",
            "2日後",
            "来月",
            "来年"
        ]

        for phrase in phrases {
            let results = parser.parse(text: phrase, referenceDate: referenceDate, options: options)
            XCTAssertFalse(results.isEmpty, "Expected phrase to parse in Japanese casual mode: \(phrase)")
        }
    }

    func testCasualRegressionSemantics() {
        let parser = Chrono.ja.casual

        let weeks = parser.parse(text: "2週間後", referenceDate: referenceDate, options: options)
        XCTAssertFalse(weeks.isEmpty)
        XCTAssertTrue(weeks[0].start.isCertain(.isoWeek) || weeks[0].start.isCertain(.isoWeekYear))

        let monthDay = parser.parse(text: "6月9日", referenceDate: referenceDate, options: options)
        XCTAssertFalse(monthDay.isEmpty)
        XCTAssertEqual(monthDay[0].start.get(.month), 6)
        XCTAssertEqual(monthDay[0].start.get(.day), 9)
    }

    func testStrictRegressionPhrasesAreParseable() {
        let parser = Chrono.ja.strict
        let phrases = [
            "2週間後",
            "6月",
            "6月9日",
            "2日後",
            "来月",
            "来年"
        ]

        for phrase in phrases {
            let results = parser.parse(text: phrase, referenceDate: referenceDate, options: options)
            XCTAssertFalse(results.isEmpty, "Expected phrase to parse in Japanese strict mode: \(phrase)")
        }
    }
}
