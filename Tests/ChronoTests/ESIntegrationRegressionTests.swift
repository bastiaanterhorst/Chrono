import XCTest
@testable import Chrono

final class ESIntegrationRegressionTests: XCTestCase {
    private let referenceDate = Date(timeIntervalSince1970: 1_735_689_600) // 2025-01-01T00:00:00Z
    private let options = ParsingOptions(forwardDate: true)

    func testCasualRegressionPhrasesAreParseable() {
        let parser = Chrono.es.casual
        let phrases = [
            "hoy",
            "en 2 semanas",
            "junio",
            "junio 9",
            "lunes",
            "en 2 días",
            "próximo mes",
            "próximo año"
        ]

        for phrase in phrases {
            let results = parser.parse(text: phrase, referenceDate: referenceDate, options: options)
            XCTAssertFalse(results.isEmpty, "Expected phrase to parse in Spanish casual mode: \(phrase)")
        }
    }

    func testCasualRegressionSemantics() {
        let parser = Chrono.es.casual

        let weeks = parser.parse(text: "en 2 semanas", referenceDate: referenceDate, options: options)
        XCTAssertFalse(weeks.isEmpty)
        XCTAssertTrue(weeks[0].start.isCertain(.isoWeek) || weeks[0].start.isCertain(.isoWeekYear))

        let monthDay = parser.parse(text: "junio 9", referenceDate: referenceDate, options: options)
        XCTAssertFalse(monthDay.isEmpty)
        XCTAssertEqual(monthDay[0].start.get(.month), 6)
        XCTAssertEqual(monthDay[0].start.get(.day), 9)
    }

    func testStrictRegressionPhrasesAreParseable() {
        let parser = Chrono.es.strict
        let phrases = [
            "en 2 semanas",
            "junio 9",
            "próximo mes",
            "próximo año",
            "en 2 días"
        ]

        for phrase in phrases {
            let results = parser.parse(text: phrase, referenceDate: referenceDate, options: options)
            XCTAssertFalse(results.isEmpty, "Expected phrase to parse in Spanish strict mode: \(phrase)")
        }
    }
}
