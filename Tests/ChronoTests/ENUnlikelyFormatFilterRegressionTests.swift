import XCTest
@testable import Chrono

final class ENUnlikelyFormatFilterRegressionTests: XCTestCase {
    private let referenceDate = Date(timeIntervalSince1970: 1_735_689_600) // 2025-01-01T00:00:00Z

    func testTodayIsNotFilteredOnJanuaryFirst() {
        let results = Chrono.casual.parse(
            text: "today",
            referenceDate: referenceDate,
            options: ParsingOptions(forwardDate: true)
        )

        XCTAssertFalse(results.isEmpty)
        XCTAssertEqual(results[0].text.lowercased(), "today")
    }

    func testNumericSlashAmbiguityStillFiltered() {
        let results = Chrono.casual.parse(
            text: "score was 1/1",
            referenceDate: referenceDate,
            options: ParsingOptions(forwardDate: true)
        )

        XCTAssertTrue(results.isEmpty)
    }
}
