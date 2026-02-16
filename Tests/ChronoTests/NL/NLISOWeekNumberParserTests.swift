import XCTest
@testable import Chrono

final class NLISOWeekNumberParserTests: XCTestCase {
    private let parser = NLISOWeekNumberParser()
    private let referenceDate = Date(timeIntervalSince1970: 1735603200) // 2025-01-01

    func testDutchWeekFormats() throws {
        let currentISOWeekYear = Calendar(identifier: .iso8601).component(.yearForWeekOfYear, from: referenceDate)

        let testCases: [(text: String, expectedWeek: Int, expectedYear: Int, isYearCertain: Bool)] = [
            ("week 45", 45, currentISOWeekYear, false),
            ("weeknummer 12", 12, currentISOWeekYear, false),
            ("W45", 45, currentISOWeekYear, false),
            ("week 45 2023", 45, 2023, true),
            ("week 45 '23", 45, 2023, true),
            ("de 45e week", 45, currentISOWeekYear, false),
            ("de 45ste week van 2023", 45, 2023, true),
            ("2023-W45", 45, 2023, true),
            ("2023W45", 45, 2023, true),
            ("W45-2023", 45, 2023, true),
            ("W45/2023", 45, 2023, true)
        ]

        for testCase in testCases {
            let result = try extract(text: testCase.text)
            XCTAssertEqual(result.start.get(.isoWeek), testCase.expectedWeek, "Week mismatch for: \(testCase.text)")
            XCTAssertEqual(result.start.get(.isoWeekYear), testCase.expectedYear, "Week year mismatch for: \(testCase.text)")
            XCTAssertEqual(result.start.isCertain(.isoWeek), true, "Week should always be certain for: \(testCase.text)")
            XCTAssertEqual(result.start.isCertain(.isoWeekYear), testCase.isYearCertain, "Week year certainty mismatch for: \(testCase.text)")
        }
    }

    func testWeekDateResolutionUsesISOCalendar() throws {
        let result = try extract(text: "week 1 2023")
        let calendar = Calendar(identifier: .iso8601)
        let components = calendar.dateComponents([.year, .month, .day, .weekday], from: result.start.date)

        XCTAssertEqual(components.year, 2023)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 2)
        XCTAssertEqual(components.weekday, 2) // Monday
    }

    func testDutchLocaleIntegrationForWeekNumber() {
        let results = Chrono.nl.casual.parse(
            text: "Vergadering in week 15 van 2023",
            referenceDate: referenceDate
        )

        XCTAssertFalse(results.isEmpty)
        guard let weekResult = results.first(where: { $0.start.get(.isoWeek) == 15 }) else {
            XCTFail("No week-number parsing result found")
            return
        }

        XCTAssertEqual(weekResult.start.get(.isoWeekYear), 2023)
        XCTAssertTrue(weekResult.start.isCertain(.isoWeek))
        XCTAssertTrue(weekResult.start.isCertain(.isoWeekYear))
    }

    private func extract(text: String) throws -> ParsedResult {
        let context = ParsingContext(
            text: text,
            reference: ReferenceWithTimezone(instant: referenceDate),
            options: ParsingOptions()
        )

        let pattern = parser.pattern(context: context)
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let nsText = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))

        XCTAssertEqual(matches.count, 1, "Expected exactly one match for: \(text)")

        guard let firstMatch = matches.first else {
            throw NSError(domain: "NLISOWeekNumberParserTests", code: 1)
        }

        let textMatch = TextMatch(match: firstMatch, text: text)
        guard let internalResult = parser.extract(context: context, match: textMatch) as? ParsingResult,
              let result = internalResult.toPublicResult() else {
            throw NSError(domain: "NLISOWeekNumberParserTests", code: 2)
        }

        return result
    }
}
