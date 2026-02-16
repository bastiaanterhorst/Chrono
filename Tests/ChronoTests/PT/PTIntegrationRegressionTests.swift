import XCTest
@testable import Chrono

final class PTIntegrationRegressionTests: XCTestCase {
    private let referenceDate = Date(timeIntervalSince1970: 1_735_689_600) // 2025-01-01T00:00:00Z
    private let options = ParsingOptions(forwardDate: true)

    func testCasualRegressionPhrasesAreParseable() {
        let parser = Chrono.pt.casual
        let phrases = [
            "hoje",
            "em 2 semanas",
            "junho",
            "junho 9",
            "segunda-feira",
            "em 2 dias",
            "próximo mês",
            "próximo ano"
        ]

        for phrase in phrases {
            let results = parser.parse(text: phrase, referenceDate: referenceDate, options: options)
            XCTAssertFalse(results.isEmpty, "Expected phrase to parse in Portuguese casual mode: \(phrase)")
        }
    }

    func testCasualRegressionSemantics() {
        let parser = Chrono.pt.casual

        let weeks = parser.parse(text: "em 2 semanas", referenceDate: referenceDate, options: options)
        XCTAssertFalse(weeks.isEmpty)
        XCTAssertTrue(weeks[0].start.isCertain(.isoWeek) || weeks[0].start.isCertain(.isoWeekYear))

        let monthDay = parser.parse(text: "junho 9", referenceDate: referenceDate, options: options)
        XCTAssertFalse(monthDay.isEmpty)
        XCTAssertEqual(monthDay[0].start.get(.month), 6)
        XCTAssertEqual(monthDay[0].start.get(.day), 9)
    }

    func testStrictRegressionPhrasesAreParseable() {
        let parser = Chrono.pt.strict
        let phrases = [
            "em 2 semanas",
            "junho 9",
            "próximo mês",
            "próximo ano",
            "em 2 dias"
        ]

        for phrase in phrases {
            let results = parser.parse(text: phrase, referenceDate: referenceDate, options: options)
            XCTAssertFalse(results.isEmpty, "Expected phrase to parse in Portuguese strict mode: \(phrase)")
        }
    }
}
