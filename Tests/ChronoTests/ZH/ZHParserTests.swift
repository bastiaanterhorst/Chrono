// ZHParserTests.swift - Tests for the Chinese casual-date, weekday, absolute-date and time parsers.
import Testing
import Foundation
@testable import Chrono

/// Reference for every case here: **Tuesday 2026-02-17 12:00**.
@Suite("ZH — casual dates")
struct ZHCasualDateParserTests {

    @Test func todayTomorrowAndFriends() {
        zhExpectDay("今天", 2026, 2, 17)
        zhExpectDay("今日", 2026, 2, 17)
        zhExpectDay("明天", 2026, 2, 18)
        zhExpectDay("明日", 2026, 2, 18)
        zhExpectDay("后天", 2026, 2, 19)
        zhExpectDay("大后天", 2026, 2, 20)
    }

    /// Past-direction keywords remain a library capability (forward-only is a consumer policy).
    @Test func pastKeywords() {
        zhExpectDay("昨天", 2026, 2, 16)
        zhExpectDay("昨日", 2026, 2, 16)
        zhExpectDay("前天", 2026, 2, 15)
        zhExpectDay("大前天", 2026, 2, 14)
    }

    /// 大后天 must win over 后天 — an alternation that listed the short form first would fail at the
    /// 大 and then match 后天 one index later, silently losing a day.
    @Test func longestTokenWins() {
        let result = zhParse("大后天开会").first
        #expect(result?.text == "大后天", "matched span → \(String(describing: result?.text))")
        zhExpectDay("大后天开会", 2026, 2, 20)
        zhExpectDay("大前天的会议", 2026, 2, 14)
    }

    @Test func traditionalVariantsParse() {
        zhExpectDay("後天", 2026, 2, 19)
        zhExpectDay("大後天", 2026, 2, 20)
        zhExpectDay("明兒", 2026, 2, 18)
    }

    @Test func dayPlusTimeOfDayCompounds() {
        zhExpectDay("今晚", 2026, 2, 17)
        zhExpectTime("今晚", hour: 22)
        zhExpectDay("明早", 2026, 2, 18)
        zhExpectTime("明早", hour: 6)
        zhExpectDay("明晚", 2026, 2, 18)
        zhExpectTime("明晚", hour: 22)
        zhExpectDay("昨晚", 2026, 2, 16)
        zhExpectTime("昨晚", hour: 22)
    }

    @Test func bareTimeOfDayWords() {
        zhExpectTime("上午", hour: 9)
        zhExpectTime("中午", hour: 12)
        zhExpectTime("下午", hour: 15)
        zhExpectTime("傍晚", hour: 17)
        zhExpectTime("晚上", hour: 20)
        zhExpectTime("凌晨", hour: 3)
    }

    /// A time-of-day word directly before a clock time belongs to the time parser as ONE match —
    /// `下午3点` is 15:00, not "afternoon" plus a stray "3 o'clock".
    @Test func timeOfDayWordDoesNotStealAClockTime() {
        zhExpectTime("下午3点", hour: 15)
        zhExpectTime("上午10点", hour: 10)
        #expect(zhParse("下午3点").count == 1, "下午3点 must be a single result")
    }

    /// Chrono keeps no "now" keyword in any locale (casual-parsing-scope), and ZH adds none.
    @Test func nowKeywordIsNotRecognized() {
        zhExpectNothing("现在就做", "现在 = now")
        zhExpectNothing("马上开始", "马上 = right away")
    }
}

@Suite("ZH — weekdays")
struct ZHWeekdayParserTests {

    /// A bare weekday resolves to its next occurrence; today counts as today.
    @Test func bareWeekdays() {
        zhExpectDay("星期四", 2026, 2, 19)
        zhExpectDay("周三", 2026, 2, 18)
        zhExpectDay("礼拜五", 2026, 2, 20)
        zhExpectDay("星期二", 2026, 2, 17, "today is Tuesday: ")
        // Monday has already passed this week, so the next one falls in the following week.
        zhExpectDay("周一", 2026, 2, 23)
    }

    /// 日 and 天 both name Sunday.
    @Test func sundayHasTwoNames() {
        zhExpectDay("星期日", 2026, 2, 22)
        zhExpectDay("星期天", 2026, 2, 22)
        zhExpectDay("周日", 2026, 2, 22)
        zhExpectDay("周天", 2026, 2, 22)
    }

    /// `下周三` is one fused token in Chinese — the week word and the weekday are not separable,
    /// so the weekday parser owns the whole thing rather than leaving it to a merge refiner.
    @Test func weekdayWithinARelativeWeek() {
        zhExpectDay("下周三", 2026, 2, 25)
        zhExpectDay("下星期四", 2026, 2, 26)
        zhExpectDay("下个星期一", 2026, 2, 23)
        zhExpectDay("这周五", 2026, 2, 20)
        zhExpectDay("本周五", 2026, 2, 20)
        zhExpectDay("上周五", 2026, 2, 13)
        zhExpectDay("下下周三", 2026, 3, 4)
        zhExpectDay("上上周三", 2026, 2, 4, "week 6 Monday is 02-02: ")
        zhExpectDay("下周日", 2026, 3, 1, "Sunday ends the ISO week: ")
    }

    @Test func weekdayNumbersUseSundayZero() {
        #expect(zhParse("周一").first?.start.get(.weekday) == 1)
        #expect(zhParse("周六").first?.start.get(.weekday) == 6)
        #expect(zhParse("周日").first?.start.get(.weekday) == 0)
    }

    @Test func traditionalWeekWords() {
        zhExpectDay("週三", 2026, 2, 18)
        zhExpectDay("禮拜五", 2026, 2, 20)
        zhExpectDay("下週三", 2026, 2, 25)
    }
}

@Suite("ZH — absolute dates")
struct ZHAbsoluteDateTests {

    @Test func fullDates() {
        zhExpectDay("2026年3月15日", 2026, 3, 15)
        zhExpectDay("2026年3月15号", 2026, 3, 15)
        zhExpectDay("3月15日", 2026, 3, 15)
        zhExpectDay("3月15号", 2026, 3, 15)
    }

    @Test func fullWidthAndChineseNumeralDates() {
        zhExpectDay("２０２６年３月１５日", 2026, 3, 15)
        zhExpectDay("二〇二六年三月十五日", 2026, 3, 15)
        zhExpectDay("三月十五日", 2026, 3, 15)
    }

    /// A bare month resolves to the 1st (the cross-locale MonthOnlyDayRefiner).
    @Test func monthOnly() {
        zhExpectDay("3月", 2026, 3, 1)
        zhExpectDay("2026年3月", 2026, 3, 1)
        zhExpectDay("十月", 2026, 10, 1)
    }

    /// Chinese writes dates big-endian, so a slash date is month/day — the opposite of the Dutch
    /// day-first convention.
    @Test func slashDates() {
        zhExpectDay("2026/3/15", 2026, 3, 15)
        zhExpectDay("3/15", 2026, 3, 15)
    }

    @Test func outOfRangeDatesAreRejected() {
        zhExpectNothing("13月45日", "month 13 / day 45")
        zhExpectNothing("3月99号", "day 99")
    }

    /// With forwardDate a date already past rolls to next year.
    @Test func yearRollsForward() {
        zhExpectDay("1月5日", 2027, 1, 5, forward: true)
        zhExpectDay("3月15日", 2026, 3, 15, forward: true)
    }
}

@Suite("ZH — clock times")
struct ZHTimeExpressionTests {

    @Test func bareDigitHours() {
        zhExpectTime("3点", hour: 3)
        zhExpectTime("15点", hour: 15)
        zhExpectTime("3点30分", hour: 3, minute: 30)
        zhExpectTime("3点半", hour: 3, minute: 30)
        zhExpectTime("3点一刻", hour: 3, minute: 15)
        zhExpectTime("3点三刻", hour: 3, minute: 45)
        zhExpectTime("3点钟", hour: 3)
    }

    @Test func timeOfDayPrefixes() {
        zhExpectTime("下午3点", hour: 15)
        zhExpectTime("上午10点30分", hour: 10, minute: 30)
        zhExpectTime("晚上8点半", hour: 20, minute: 30)
        zhExpectTime("早上7点", hour: 7)
        zhExpectTime("中午12点", hour: 12)
        zhExpectTime("凌晨2点", hour: 2)
        zhExpectTime("傍晚6点", hour: 18)
    }

    /// A Chinese-numeral hour is only accepted when it is disambiguated — by a time-of-day prefix
    /// or by a minute/half/quarter tail. A bare `一点` means "a little bit" far more often than
    /// "one o'clock", so it must not parse at all; see ZHCollisionTests.
    @Test func chineseNumeralHoursRequireDisambiguation() {
        zhExpectTime("一点半", hour: 1, minute: 30)
        zhExpectTime("下午一点", hour: 13)
        zhExpectTime("三点半", hour: 3, minute: 30)
        zhExpectTime("晚上八点", hour: 20)
    }

    /// The Japanese locale cannot parse `15:00`; ZH deliberately closes that gap.
    @Test func colonTimes() {
        zhExpectTime("15:30", hour: 15, minute: 30)
        zhExpectTime("9:05", hour: 9, minute: 5)
        zhExpectTime("下午3:30", hour: 15, minute: 30)
        zhExpectTime("15：30", hour: 15, minute: 30, "full-width colon: ")
    }

    /// Out-of-range values reject the match rather than overflowing the calendar
    /// (numeric-time-validation). Chinese has no late-night 27時 convention — 23 is the cap.
    @Test func outOfRangeTimesAreRejected() {
        zhExpectNothing("25点", "hour 25")
        zhExpectNothing("3点80分", "minute 80")
        zhExpectNothing("99:99", "out of range colon time")
    }
}
