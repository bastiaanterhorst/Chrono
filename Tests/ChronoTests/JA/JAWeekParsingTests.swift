import XCTest
@testable import Chrono

final class JAWeekParsingTests: XCTestCase {
    private let referenceDate = Date(timeIntervalSince1970: 1736899200) // 2025-01-15
    private let calendar = Calendar(identifier: .iso8601)

    func testJAISOWeekParsing() {
        let results = Chrono.ja.casual.parse(text: "2023年第15週", referenceDate: referenceDate)
        guard let weekResult = results.first(where: { $0.start.get(.isoWeek) == 15 }) else {
            XCTFail("No ISO week parsing result found")
            return
        }

        XCTAssertEqual(weekResult.start.get(.isoWeekYear), 2023)
        XCTAssertTrue(weekResult.start.isCertain(.isoWeek))
        XCTAssertTrue(weekResult.start.isCertain(.isoWeekYear))
    }

    func testJARelativeWeekParsing() {
        let results = Chrono.ja.casual.parse(text: "来週", referenceDate: referenceDate)
        guard let weekResult = results.first(where: { $0.start.get(.isoWeek) != nil }) else {
            XCTFail("No relative week parsing result found")
            return
        }

        let expectedDate = calendar.date(byAdding: .weekOfYear, value: 1, to: referenceDate)!
        XCTAssertEqual(weekResult.start.get(.isoWeek), calendar.component(.weekOfYear, from: expectedDate))
        XCTAssertEqual(weekResult.start.get(.isoWeekYear), calendar.component(.yearForWeekOfYear, from: expectedDate))
    }

    func testJAWeeksAgoParsing() {
        let results = Chrono.ja.casual.parse(text: "2週間前", referenceDate: referenceDate)
        guard let weekResult = results.first(where: { $0.start.get(.isoWeek) != nil }) else {
            XCTFail("No relative week parsing result found")
            return
        }

        let expectedDate = calendar.date(byAdding: .weekOfYear, value: -2, to: referenceDate)!
        XCTAssertEqual(weekResult.start.get(.isoWeek), calendar.component(.weekOfYear, from: expectedDate))
        XCTAssertEqual(weekResult.start.get(.isoWeekYear), calendar.component(.yearForWeekOfYear, from: expectedDate))
    }
}
