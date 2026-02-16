import XCTest
@testable import Chrono

final class NLRelativeWeekParserTests: XCTestCase {
    private let parser = NLRelativeWeekParser()
    private let calendar = Calendar(identifier: .iso8601)
    private let referenceDate = Date(timeIntervalSince1970: 1736899200) // 2025-01-15

    func testBasicRelativeWeekPatterns() throws {
        try assertWeek(text: "deze week", offset: 0)
        try assertWeek(text: "vorige week", offset: -1)
        try assertWeek(text: "afgelopen week", offset: -1)
        try assertWeek(text: "volgende week", offset: 1)
        try assertWeek(text: "komende week", offset: 1)
    }

    func testNumericRelativeWeekPatterns() throws {
        try assertWeek(text: "2 weken geleden", offset: -2)
        try assertWeek(text: "over 3 weken", offset: 3)
        try assertWeek(text: "binnen 4 weken", offset: 4)
        try assertWeek(text: "3 weken vanaf nu", offset: 3)
    }

    func testComplexRelativeWeekPatterns() throws {
        try assertWeek(text: "de week voor vorige", offset: -2)
        try assertWeek(text: "de week na volgende", offset: 2)
    }

    func testDutchLocaleIntegrationForRelativeWeek() {
        let results = Chrono.nl.casual.parse(
            text: "We spreken volgende week af",
            referenceDate: referenceDate
        )

        XCTAssertFalse(results.isEmpty)
        guard let weekResult = results.first(where: { $0.text.lowercased().contains("volgende week") }) else {
            XCTFail("No relative-week result found")
            return
        }

        XCTAssertTrue(weekResult.start.isCertain(.isoWeek))
        XCTAssertTrue(weekResult.start.isCertain(.isoWeekYear))
    }

    private func assertWeek(text: String, offset: Int) throws {
        let expectedDate = calendar.date(byAdding: .weekOfYear, value: offset, to: referenceDate)!
        let expectedWeek = calendar.component(.weekOfYear, from: expectedDate)
        let expectedWeekYear = calendar.component(.yearForWeekOfYear, from: expectedDate)

        let result = try extract(text: text)
        XCTAssertEqual(result.start.get(.isoWeek), expectedWeek, "Week mismatch for: \(text)")
        XCTAssertEqual(result.start.get(.isoWeekYear), expectedWeekYear, "Week year mismatch for: \(text)")
        XCTAssertTrue(result.start.isCertain(.isoWeek), "Week should be certain for: \(text)")
        XCTAssertTrue(result.start.isCertain(.isoWeekYear), "Week year should be certain for: \(text)")
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
            throw NSError(domain: "NLRelativeWeekParserTests", code: 1)
        }

        let textMatch = TextMatch(match: firstMatch, text: text)
        guard let internalResult = parser.extract(context: context, match: textMatch) as? ParsingResult,
              let result = internalResult.toPublicResult() else {
            throw NSError(domain: "NLRelativeWeekParserTests", code: 2)
        }

        return result
    }
}
