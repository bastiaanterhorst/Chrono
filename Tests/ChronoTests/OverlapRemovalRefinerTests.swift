import XCTest
@testable import Chrono

final class OverlapRemovalRefinerTests: XCTestCase {
    private func makeContext(text: String) -> ParsingContext {
        return ParsingContext(
            text: text,
            reference: ReferenceWithTimezone(instant: Date(timeIntervalSince1970: 1_735_689_600)),
            options: ParsingOptions(forwardDate: true)
        )
    }

    func testEqualRangeKeepsSinglePreferredWeekResult() {
        let context = makeContext(text: "in 2 weeks")
        let refiner = OverlapRemovalRefiner()

        let weekStart = context.createParsingComponents(components: [
            .isoWeek: 3,
            .isoWeekYear: 2025,
            .year: 2025,
            .month: 1,
            .day: 13
        ])
        weekStart.assignNull(.hour)
        let weekResult = context.createParsingResult(index: 0, text: "in 2 weeks", start: weekStart)

        let dayStart = context.createParsingComponents(components: [
            .year: 2025,
            .month: 1,
            .day: 15
        ])
        let dayResult = context.createParsingResult(index: 0, text: "in 2 weeks", start: dayStart)

        let refined = refiner.refine(context: context, results: [dayResult, weekResult])
        XCTAssertEqual(refined.count, 1)
        XCTAssertTrue(refined[0].start.isCertain(.isoWeek) || refined[0].start.isCertain(.isoWeekYear))
    }

    func testStrictContainmentRemovesInnerResult() {
        let context = makeContext(text: "next week at 3pm")
        let refiner = OverlapRemovalRefiner()

        let outerStart = context.createParsingComponents(components: [
            .year: 2025,
            .month: 1,
            .day: 8,
            .hour: 15
        ])
        let outer = context.createParsingResult(index: 0, text: "next week at 3pm", start: outerStart)

        let innerStart = context.createParsingComponents(components: [.hour: 15])
        let inner = context.createParsingResult(index: 13, text: "3pm", start: innerStart)

        let refined = refiner.refine(context: context, results: [inner, outer])
        XCTAssertEqual(refined.count, 1)
        XCTAssertEqual(refined[0].text, "next week at 3pm")
    }

    func testEqualRangeCandidatesDoNotDisappear() {
        let context = makeContext(text: "june 9")
        let refiner = OverlapRemovalRefiner()

        let firstStart = context.createParsingComponents(components: [
            .year: 2025,
            .month: 6,
            .day: 9
        ])
        let first = context.createParsingResult(index: 0, text: "june 9", start: firstStart)

        let secondStart = context.createParsingComponents(components: [
            .year: 2025,
            .month: 6,
            .day: 9,
            .hour: 12
        ])
        let second = context.createParsingResult(index: 0, text: "june 9", start: secondStart)

        let refined = refiner.refine(context: context, results: [first, second])
        XCTAssertEqual(refined.count, 1)
        XCTAssertFalse(refined.isEmpty)
    }
}
