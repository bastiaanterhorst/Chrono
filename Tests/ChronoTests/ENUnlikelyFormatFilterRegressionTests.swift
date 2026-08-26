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

    /// English reads slash dates now, so a bare "1/1" is 1 January rather than nothing. The filter
    /// used to reject any two `/`-separated numbers under 50 as a score, which cost English the
    /// format its own users reach for first ("12/25"). Scores and fractions reading as dates is the
    /// price, and it is one every day-first locale has always paid — "3/4 cup" has been a date in
    /// Dutch, German, French and Spanish all along.
    func testNumericSlashIsNowReadAsADate() {
        let results = Chrono.casual.parse(
            text: "score was 1/1",
            referenceDate: referenceDate,
            options: ParsingOptions(forwardDate: true)
        )

        XCTAssertFalse(results.isEmpty)
        XCTAssertEqual(results[0].text.trimmingCharacters(in: .whitespaces), "1/1")
    }

    /// What must still be filtered: text where the slash is structural rather than a date.
    func testPathsUrlsAndEmailsAreStillFiltered() {
        for text in ["docs/readme", "see https://example.com/a/b", "mail a@b.com/c"] {
            let results = Chrono.casual.parse(
                text: text,
                referenceDate: referenceDate,
                options: ParsingOptions(forwardDate: true)
            ).filter { $0.start.isCertain(.day) && $0.start.isCertain(.month) }
            XCTAssertTrue(results.isEmpty, "'\(text)' should not yield a date")
        }
    }
}
