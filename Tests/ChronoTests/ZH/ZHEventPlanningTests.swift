// ZHEventPlanningTests.swift - Booking an event, not just dating a task.
import Testing
import Foundation
@testable import Chrono

/// Scheduling a *task* needs a day; booking an **event** needs a span. Chinese states that span the
/// same way a calendar does — `明天9点到11点` — and that is the phrasing this suite is about.
///
/// The English locale already merges `9am to 11am` into one result carrying an end. ZH produced two
/// disconnected results instead, so the second time was left to be picked up as a stray date and its
/// text stranded in the task's name. Everything else here is a smaller leftover of the same kind.
///
/// Reference: Tuesday 2026-02-17 12:00.
@Suite("ZH — event planning")
struct ZHEventPlanningTests {

    /// The components of a result's end, or nil when it has none.
    private func endOf(_ text: String) -> (month: Int, day: Int, hour: Int, minute: Int)? {
        guard let result = zhParse(text, forward: true).first, let end = result.end else { return nil }
        let c = Calendar.current.dateComponents([.month, .day, .hour, .minute], from: end.date)
        guard let mo = c.month, let d = c.day, let h = c.hour, let mi = c.minute else { return nil }
        return (mo, d, h, mi)
    }

    private func startOf(_ text: String) -> (month: Int, day: Int, hour: Int, minute: Int)? {
        guard let result = zhParse(text, forward: true).first else { return nil }
        let c = Calendar.current.dateComponents([.month, .day, .hour, .minute], from: result.start.date)
        guard let mo = c.month, let d = c.day, let h = c.hour, let mi = c.minute else { return nil }
        return (mo, d, h, mi)
    }

    /// Asserts a phrase is one result spanning the given clock times on the given day.
    private func expectSpan(_ text: String, month: Int, day: Int,
                            from: (Int, Int), to: (Int, Int), _ note: String = "") {
        let results = zhParse(text, forward: true)
        #expect(results.count == 1, "\(note)「\(text)」→ \(results.count) results \(results.map { $0.text }), expected 1")
        guard let start = startOf(text) else {
            #expect(Bool(false), "\(note)「\(text)」produced no result")
            return
        }
        #expect((start.month, start.day, start.hour, start.minute) == (month, day, from.0, from.1),
                "\(note)「\(text)」start → \(start), expected \(month)-\(day) \(from)")
        guard let end = endOf(text) else {
            #expect(Bool(false), "\(note)「\(text)」has no end — the range did not merge")
            return
        }
        #expect((end.month, end.day, end.hour, end.minute) == (month, day, to.0, to.1),
                "\(note)「\(text)」end → \(end), expected \(month)-\(day) \(to)")
    }

    // MARK: - Time ranges

    /// 到 and 至 are the words; the dashes and the full-width tilde are what an IME emits.
    @Test func timeRangesMergeIntoOneResult() {
        expectSpan("明天9点到11点", month: 2, day: 18, from: (9, 0), to: (11, 0))
        expectSpan("明天9点至11点", month: 2, day: 18, from: (9, 0), to: (11, 0))
        expectSpan("明天9点-11点", month: 2, day: 18, from: (9, 0), to: (11, 0))
        expectSpan("明天9点～11点", month: 2, day: 18, from: (9, 0), to: (11, 0), "full-width tilde")
        expectSpan("明天9:00到11:00", month: 2, day: 18, from: (9, 0), to: (11, 0), "colon times")
        expectSpan("明天9:00-11:00", month: 2, day: 18, from: (9, 0), to: (11, 0))
    }

    /// The end has to inherit the day the start named. `11点` on its own resolves to the reference
    /// day; inside `明天9点到11点` it must be tomorrow, or the event ends before it begins.
    @Test func theEndInheritsTheStartsDay() {
        expectSpan("明天上午9点到10点半", month: 2, day: 18, from: (9, 0), to: (10, 30))
        expectSpan("后天下午2点到4点", month: 2, day: 19, from: (14, 0), to: (16, 0))
        expectSpan("3月15日9点到11点", month: 3, day: 15, from: (9, 0), to: (11, 0))
        expectSpan("下周三下午2点到4点", month: 2, day: 25, from: (14, 0), to: (16, 0), "next week's Wednesday")
    }

    /// A range with no date at all sits on the reference day.
    @Test func aBareTimeRangeUsesTheReferenceDay() {
        expectSpan("9点到11点", month: 2, day: 17, from: (9, 0), to: (11, 0))
        expectSpan("14:00-15:30", month: 2, day: 17, from: (14, 0), to: (15, 30))
        expectSpan("上午9点到下午5点", month: 2, day: 17, from: (9, 0), to: (17, 0), "a prefix on each side")
    }

    /// A range that runs past midnight ends the next day rather than ending before it started.
    @Test func aRangeCrossingMidnightEndsTheNextDay() {
        expectSpan_crossing("晚上10点到11点", startDay: 17, endDay: 17, from: (22, 0), to: (23, 0))
        expectSpan_crossing("晚上11点到1点", startDay: 17, endDay: 18, from: (23, 0), to: (1, 0))
    }

    private func expectSpan_crossing(_ text: String, startDay: Int, endDay: Int,
                                     from: (Int, Int), to: (Int, Int)) {
        guard let start = startOf(text), let end = endOf(text) else {
            #expect(Bool(false), "「\(text)」did not produce a span")
            return
        }
        #expect((start.day, start.hour, start.minute) == (startDay, from.0, from.1),
                "「\(text)」start → \(start), expected day \(startDay) \(from)")
        #expect((end.day, end.hour, end.minute) == (endDay, to.0, to.1),
                "「\(text)」end → \(end), expected day \(endDay) \(to)")
    }

    /// The existing date-to-date ranges must keep working — this refiner is shared.
    @Test func dateRangesAreUnchanged() {
        let results = zhParse("3月15日到3月20日", forward: true)
        #expect(results.count == 1, "3月15日到3月20日 → \(results.map { $0.text })")
        #expect(endOf("3月15日到3月20日")?.day == 20)
        #expect(zhParse("周一到周五", forward: true).count == 1, "周一到周五 is still one range")
    }

    /// A connector that is not joining two times must not invent a range.
    @Test func nonRangesAreLeftAlone() {
        zhExpectTime("明天9点开会", hour: 9, "no connector, no range")
        #expect(zhParse("明天9点", forward: true).first?.end == nil, "a lone time has no end")
    }

    // MARK: - 整 ("on the hour")

    /// 8点整 is "eight o'clock sharp". The 整 was left behind, so the task kept it in its name.
    @Test func theSharpMarkerJoinsTheTime() {
        #expect(zhParse("8点整", forward: true).first?.text == "8点整")
        #expect(zhParse("9点整开会", forward: true).first?.text == "9点整")
        zhExpectTime("8点整", hour: 8)
        zhExpectTime("上午9点整", hour: 9)
        zhExpectTime("十点整", hour: 10, "Chinese numeral")
    }

    /// 整 opens a great many ordinary words, so it only closes an hour when it is not starting one.
    /// `3点整理文件` is "tidy the files at three" — the time is still read, the 整 is not taken.
    @Test func theSharpMarkerYieldsToOrdinaryWords() {
        #expect(zhParse("3点整理文件", forward: true).first?.text == "3点", "整理 = to tidy")
        #expect(zhParse("9点整个团队开会", forward: true).first?.text == "9点", "整个 = the whole")
        #expect(zhParse("8点整天忙", forward: true).first?.text == "8点", "整天 = all day")
        zhExpectTime("3点整理文件", hour: 3, "…and the hour still resolves")
    }

    // MARK: - The attributive 的

    /// Chinese attaches a date to a noun with 的 — 明天的会议 is "tomorrow's meeting". The 的 belongs
    /// to the date phrase, and leaving it behind names the task 「的会议」.
    @Test func theAttributiveParticleJoinsTheDate() {
        #expect(zhParse("明天的会议", forward: true).first?.text == "明天的")
        #expect(zhParse("下周的评审", forward: true).first?.text == "下周的")
        #expect(zhParse("3月15号的体检", forward: true).first?.text == "3月15号的")
    }

    /// …but 的士 is "taxi", so a 的 that opens a word stays put.
    @Test func theParticleGuardHolds() {
        #expect(zhParse("明天打的士", forward: true).first?.text == "明天", "的士 = taxi")
    }

    // MARK: - ISO dates flush against Chinese

    /// The shared ISO parser guarded its tail with `(?=\W|$)`, and ICU counts Han as `\w`, so an ISO
    /// date written flush against Chinese did not parse at all — `2026-03-15 开会` worked and
    /// `2026-03-15开会` did not. The same mistake the duration scanner made, one layer down.
    @Test func isoDatesParseFlushAgainstChineseText() {
        zhExpectDay("2026-03-15开会", 2026, 3, 15, forward: true)
        zhExpectDay("2026-03-15 开会", 2026, 3, 15, forward: true, "…and with a space, as before")
        zhExpectDay("开会2026-03-15", 2026, 3, 15, forward: true, "…and trailing")
        zhExpectDay("2026-03-15", 2026, 3, 15, forward: true, "…and alone")
    }

    /// The guard still has to do its original job: an ISO date is not hiding inside a longer token.
    @Test func isoDatesStillNeedALatinBoundary() {
        zhExpectNothing("2026-03-15abc", "a Latin letter still ends the match")
        zhExpectNothing("2026-03-152", "…as does another digit")
    }

    // MARK: - Half units

    /// 半小时后 worked; the other half-units did not, though they are just as ordinary.
    @Test func halfUnitsResolve() {
        zhExpectDay("半个月后", 2026, 3, 4, forward: true, "half a month is fifteen days")
        zhExpectDay("半年后", 2026, 8, 17, forward: true, "half a year is six months")
        zhExpectTime("半小时后", hour: 12, minute: 30, "unchanged")
        zhExpectDay("半個月後", 2026, 3, 4, forward: true, "Traditional")
        zhExpectDay("半年後", 2026, 8, 17, forward: true, "Traditional")
    }

    /// 半 in ordinary vocabulary must not become an offset.
    @Test func halfUnitsDoNotFireInsideWords() {
        zhExpectNothing("一半的人", "一半 = half of")
        zhExpectNothing("半路上", "半路 = midway")
        zhExpectNothing("半价优惠", "半价 = half price")
    }
}
