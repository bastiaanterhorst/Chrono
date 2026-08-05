// ZHWeekParsingTests.swift - Relative weeks, ISO week numbers, weekends and relative units.
import Testing
import Foundation
@testable import Chrono

/// Reference: **Tuesday 2026-02-17 12:00**.
/// ISO weeks: last = wk 7 (Mon 02-09) · this = wk 8 (Mon 02-16) · next = wk 9 (Mon 02-23).
@Suite("ZH — relative weeks")
struct ZHRelativeWeekTests {

    @Test func thisNextLast() {
        zhExpectWeek("本周", week: 8)
        zhExpectWeek("这周", week: 8)
        zhExpectWeek("这个星期", week: 8)
        zhExpectWeek("下周", week: 9)
        zhExpectWeek("下个星期", week: 9)
        zhExpectWeek("上周", week: 7)
        zhExpectWeek("上个星期", week: 7)
    }

    @Test func doubledPrefixes() {
        zhExpectWeek("下下周", week: 10)
        zhExpectWeek("上上周", week: 6)
    }

    /// The number may be ASCII, full-width or a Chinese numeral — 两周后 is the idiomatic form.
    @Test func numericWeekCounts() {
        zhExpectWeek("3周后", week: 11)
        zhExpectWeek("两周后", week: 10)
        zhExpectWeek("三个星期后", week: 11)
        zhExpectWeek("2周前", week: 6)
    }

    @Test func traditionalWeekForms() {
        zhExpectWeek("下週", week: 9)
        zhExpectWeek("上週", week: 7)
        zhExpectWeek("兩週後", week: 10)
    }

    /// A relative week anchors on its Monday.
    @Test func weekAnchorsOnMonday() {
        zhExpectDay("下周", 2026, 2, 23)
        zhExpectDay("本周", 2026, 2, 16)
    }
}

@Suite("ZH — weekends")
struct ZHWeekendTests {

    /// A weekend resolves to the FIRST weekend day (Saturday) as a concrete DAY, never an ISO week.
    @Test func weekendsResolveToSaturday() {
        zhExpectDay("周末", 2026, 2, 21)
        zhExpectDay("本周末", 2026, 2, 21)
        zhExpectDay("这个周末", 2026, 2, 21)
        zhExpectDay("下周末", 2026, 2, 28)
        zhExpectDay("上周末", 2026, 2, 14)
    }

    @Test func weekendIsADayNotAWeek() {
        #expect(zhParse("下周末").first?.start.isCertain(.isoWeek) == false,
                "a weekend is a specific day, not an ISO week")
    }

    /// 下周末 must match as a unit — otherwise it becomes 下周 plus a stray 末.
    @Test func weekendModifierBindsToTheWeekendWord() {
        let result = zhParse("下周末").first
        #expect(result?.text == "下周末", "matched span → \(String(describing: result?.text))")
    }

    @Test func traditionalWeekends() {
        zhExpectDay("週末", 2026, 2, 21)
        zhExpectDay("下週末", 2026, 2, 28)
    }
}

@Suite("ZH — ISO week numbers")
struct ZHISOWeekNumberTests {

    @Test func explicitWeekNumbers() {
        zhExpectWeek("第10周", week: 10)
        zhExpectWeek("第10週", week: 10)
        zhExpectWeek("第10个星期", week: 10)
        zhExpectWeek("2026年第10周", week: 10)
    }

    @Test func asciiWeekForms() {
        zhExpectWeek("w10", week: 10)
        zhExpectWeek("2026-W10", week: 10)
    }

    @Test func outOfRangeWeeksAreRejected() {
        zhExpectNothing("第99周", "week 99 does not exist")
    }
}

@Suite("ZH — relative units")
struct ZHRelativeUnitTests {

    /// A relative month means the 1st of that month — the start of the unit, matching how a
    /// relative week anchors to its Monday.
    @Test func relativeMonths() {
        zhExpectDay("这个月", 2026, 2, 1)
        zhExpectDay("本月", 2026, 2, 1)
        zhExpectDay("下个月", 2026, 3, 1)
        zhExpectDay("下月", 2026, 3, 1)
        zhExpectDay("上个月", 2026, 1, 1)
    }

    /// A relative year keeps the reference month and day.
    @Test func relativeYears() {
        zhExpectDay("今年", 2026, 2, 17)
        zhExpectDay("明年", 2027, 2, 17)
        zhExpectDay("去年", 2025, 2, 17)
        zhExpectDay("后年", 2028, 2, 17)
        zhExpectDay("前年", 2024, 2, 17)
    }

    @Test func numericDayOffsets() {
        zhExpectDay("3天后", 2026, 2, 20)
        zhExpectDay("三天后", 2026, 2, 20)
        zhExpectDay("两天后", 2026, 2, 19)
        zhExpectDay("3天前", 2026, 2, 14)
        zhExpectDay("过3天", 2026, 2, 20)
        zhExpectDay("再过两天", 2026, 2, 19)
    }

    @Test func numericMonthAndYearOffsets() {
        zhExpectDay("一个月后", 2026, 3, 17)
        zhExpectDay("3个月后", 2026, 5, 17)
        zhExpectDay("两年后", 2028, 2, 17)
        zhExpectDay("一年前", 2025, 2, 17)
    }

    /// Minute and hour offsets move a point in time, so the clock components move too.
    @Test func timeOffsets() {
        zhExpectTime("30分钟后", hour: 12, minute: 30)
        zhExpectTime("2小时后", hour: 14, minute: 0)
        zhExpectTime("半小时后", hour: 12, minute: 30)
    }

    /// "within N units" is a deadline, mirroring Dutch `binnen 3 dagen`.
    @Test func withinForms() {
        zhExpectDay("3天内", 2026, 2, 20)
        zhExpectDay("三天之内", 2026, 2, 20)
        zhExpectDay("一周内", 2026, 2, 24)
    }

    @Test func traditionalRelativeUnits() {
        zhExpectDay("下個月", 2026, 3, 1)
        zhExpectDay("三天後", 2026, 2, 20)
        zhExpectDay("兩個月後", 2026, 4, 17)
    }
}
