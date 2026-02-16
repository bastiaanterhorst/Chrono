import XCTest
@testable import Chrono

final class FRIntegrationRegressionTests: XCTestCase {
    private let referenceDate = Date(timeIntervalSince1970: 1_735_689_600) // 2025-01-01T00:00:00Z
    private let options = ParsingOptions(forwardDate: true)

    func testCasualRegressionPhrasesAreParseable() {
        let parser = Chrono.fr.casual
        let phrases = [
            "aujourd'hui",
            "dans 2 semaines",
            "juin",
            "juin 9",
            "lundi",
            "dans 2 jours",
            "mois prochain",
            "an prochain"
        ]

        for phrase in phrases {
            let results = parser.parse(text: phrase, referenceDate: referenceDate, options: options)
            XCTAssertFalse(results.isEmpty, "Expected phrase to parse in French casual mode: \(phrase)")
        }
    }

    func testCasualRegressionSemantics() {
        let parser = Chrono.fr.casual

        let weeks = parser.parse(text: "dans 2 semaines", referenceDate: referenceDate, options: options)
        XCTAssertFalse(weeks.isEmpty)
        XCTAssertTrue(weeks[0].start.isCertain(.isoWeek) || weeks[0].start.isCertain(.isoWeekYear))

        let monthDay = parser.parse(text: "juin 9", referenceDate: referenceDate, options: options)
        XCTAssertFalse(monthDay.isEmpty)
        XCTAssertEqual(monthDay[0].start.get(.month), 6)
        XCTAssertEqual(monthDay[0].start.get(.day), 9)
    }

    func testStrictRegressionPhrasesAreParseable() {
        let parser = Chrono.fr.strict
        let phrases = [
            "dans 2 semaines",
            "juin 9",
            "mois prochain",
            "an prochain",
            "dans 2 jours"
        ]

        for phrase in phrases {
            let results = parser.parse(text: phrase, referenceDate: referenceDate, options: options)
            XCTAssertFalse(results.isEmpty, "Expected phrase to parse in French strict mode: \(phrase)")
        }
    }
}
