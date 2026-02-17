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

    func testFutureIntentPhrasesStayInFuture() {
        let parser = Chrono.pt.casual
        let ref = Date(timeIntervalSince1970: 1_739_534_400) // 2025-02-14T12:00:00Z

        let futurePhrases = [
            "em 2 dias",
            "em 2 semanas",
            "em 2 meses",
            "em 2 anos"
        ]

        for phrase in futurePhrases {
            let results = parser.parse(text: phrase, referenceDate: ref, options: options)
            XCTAssertFalse(results.isEmpty, "Expected phrase to parse: \(phrase)")
            XCTAssertGreaterThan(results[0].start.date, ref, "Expected future date for phrase: \(phrase)")
        }

        let explicitPast = parser.parse(text: "há 2 dias", referenceDate: ref, options: options)
        XCTAssertFalse(explicitPast.isEmpty)
        XCTAssertLessThan(explicitPast[0].start.date, ref)
    }

    func testImplicitISOWeekYearUsesLogicalFutureYear() {
        let parser = Chrono.pt.casual
        let isoCalendar = Calendar(identifier: .iso8601)

        let beforeWeek10Ref = Date(timeIntervalSince1970: 1_736_899_200) // 2025-01-15T00:00:00Z
        let afterWeek10Ref = Date(timeIntervalSince1970: 1_742_428_800) // 2025-03-20T00:00:00Z

        let beforeResults = parser.parse(text: "w10", referenceDate: beforeWeek10Ref, options: options)
        XCTAssertFalse(beforeResults.isEmpty)
        XCTAssertEqual(isoCalendar.component(.yearForWeekOfYear, from: beforeResults[0].start.date), 2025)

        let afterResults = parser.parse(text: "w10", referenceDate: afterWeek10Ref, options: options)
        XCTAssertFalse(afterResults.isEmpty)
        XCTAssertEqual(isoCalendar.component(.yearForWeekOfYear, from: afterResults[0].start.date), 2026)

        let explicitYearResults = parser.parse(text: "w10-2010", referenceDate: afterWeek10Ref, options: options)
        XCTAssertFalse(explicitYearResults.isEmpty)
        XCTAssertEqual(isoCalendar.component(.yearForWeekOfYear, from: explicitYearResults[0].start.date), 2010)
    }
}
