// ZHDailyIdiomTests.swift - The date forms Chinese daily life is actually organised around.
import Testing
import Foundation
@testable import Chrono

/// The forms in this suite were found by asking a plainer question than "does ZH match EN": *what
/// does a Chinese speaker type into a to-do list every week?* The answer turned out to include four
/// things the locale could not read, and one it read wrongly.
///
/// The unifying theme is that Chinese organises recurring life by **day of the month** and by the
/// **edges of a period** — 15号交房租, 10号发工资, 月底前完成, 年底总结 — where English reaches for a
/// full date or a preposition phrase. Chrono reads none of these in any locale, but that was never
/// a reason to leave Chinese without them: 号 and 月底 are single lexical words used far more freely
/// than "the 15th" and "end of month" are.
///
/// Reference: Tuesday 2026-02-17 12:00. February 2026 has 28 days.
@Suite("ZH — daily-life date idioms")
struct ZHDailyIdiomTests {

    // MARK: - A bare day of the month

    /// The form every monthly obligation is stated in. `forward: true` throughout, because that is
    /// how a to-do host parses: a day already past means the next month's.
    @Test func bareDayOfMonthResolves() {
        zhExpectDay("15号交房租", 2026, 3, 15, forward: true, "the 15th has passed, so next month's")
        zhExpectDay("20号截止", 2026, 2, 20, forward: true, "the 20th is still ahead, so this month's")
        zhExpectDay("十五号交房租", 2026, 3, 15, forward: true, "Chinese numerals too")
        zhExpectDay("１５号", 2026, 3, 15, forward: true, "full-width digits too")
        zhExpectDay("15號", 2026, 3, 15, forward: true, "Traditional 號")
        zhExpectDay("18号发工资", 2026, 2, 18, forward: true)
    }

    /// A day the reference month does not have rolls to a month that does, rather than overflowing
    /// into the 1st of the next one.
    @Test func aDayTheMonthLacksRollsForward() {
        zhExpectDay("31号", 2026, 3, 31, forward: true, "February has no 31st")
        zhExpectDay("30号", 2026, 3, 30, forward: true, "…nor a 30th")
        zhExpectDay("29号", 2026, 3, 29, forward: true, "…nor a 29th in 2026, which is not a leap year")
    }

    /// 号 labels almost everything numbered in Chinese, so the identifier readings must all survive
    /// untouched. A wrong date out of "buy AA batteries" would be worse than no date at all.
    @Test func identifierReadingsAreNotDates() {
        zhExpectNothing("坐3号线", "3号线 = metro line 3")
        zhExpectNothing("十一号线换乘", "line 11")
        zhExpectNothing("5号楼", "building 5")
        zhExpectNothing("会议室2号", "meeting room 2")
        zhExpectNothing("房间12号", "room 12")
        zhExpectNothing("买5号电池", "5号电池 = an AA battery")
        zhExpectNothing("7号电池", "AAA battery")
        zhExpectNothing("2号选手", "contestant 2")
        zhExpectNothing("工位3号", "workstation 3")
        zhExpectNothing("大号衣服", "大号 = large size")
        zhExpectNothing("第5号文件", "第N号 is an ordinal label")
        zhExpectNothing("手机号", "no number at all — nothing to match")
    }

    /// The bare form is 号 only. 日 is also the day *unit*, and the two readings are indistinguishable
    /// in exactly the shapes that matter — 15日前 "before the 15th" versus 3日前 "three days ago".
    @Test func bareDayMarkerIsHaoOnly() {
        zhExpectNothing("15日截止", "a bare 日 day-of-month is deliberately not read")
        zhExpectDay("3日后", 2026, 2, 20, forward: true, "…because 日 is the day unit, which still works")
        zhExpectDay("3月15日", 2026, 3, 15, forward: true, "…and 日 with its month is a full date")
    }

    /// A month standing next to the number means a fuller parser owns the phrase.
    @Test func aMonthBesideTheNumberWins() {
        zhExpectDay("3月15号", 2026, 3, 15, forward: true)
        zhExpectDay("2027年7月2号", 2027, 7, 2, forward: true)
    }

    // MARK: - Relative month plus a day

    /// 下个月15号 used to report the 1st of next month and leave 15号 in the task's name — a wrong
    /// date, silently. It is one expression.
    @Test func relativeMonthTakesAStatedDay() {
        zhExpectDay("下个月15号体检", 2026, 3, 15, forward: true)
        zhExpectDay("下月10号面签", 2026, 3, 10, forward: true, "…without the measure word")
        zhExpectDay("这个月20号截止", 2026, 2, 20, forward: true)
        zhExpectDay("下个月15日", 2026, 3, 15, forward: true, "日 is fine here — the month disambiguates it")
        zhExpectDay("下下个月1号", 2026, 4, 1, forward: true)
        zhExpectDay("下個月15號", 2026, 3, 15, forward: true, "Traditional")
    }

    /// A bare relative month still means the start of that month.
    @Test func bareRelativeMonthIsUnchanged() {
        zhExpectDay("下个月", 2026, 3, 1, forward: true)
        zhExpectDay("这个月", 2026, 2, 1, forward: true)
    }

    // MARK: - The edges of a period

    @Test func periodBoundariesResolve() {
        zhExpectDay("月底", 2026, 2, 28, forward: true, "February 2026 has 28 days")
        zhExpectDay("本月底", 2026, 2, 28, forward: true)
        zhExpectDay("这个月底", 2026, 2, 28, forward: true)
        zhExpectDay("下个月底", 2026, 3, 31, forward: true, "March has 31")
        zhExpectDay("下月初", 2026, 3, 1, forward: true)
        zhExpectDay("上个月底", 2026, 1, 31, forward: true)
        zhExpectDay("3月底", 2026, 3, 31, forward: true, "a named month, not a relative one")
        zhExpectDay("12月初", 2026, 12, 1, forward: true)
        zhExpectDay("年底", 2026, 12, 31, forward: true)
        zhExpectDay("明年年底", 2027, 12, 31, forward: true, "the doubled form")
        zhExpectDay("明年底", 2027, 12, 31, forward: true, "…and the clipped one")
        zhExpectDay("去年底", 2025, 12, 31, forward: true)
        zhExpectDay("月底前完成报告", 2026, 2, 28, forward: true, "the deadline reading is the same day")
    }

    /// A boundary that has already gone by rolls forward, the way every other forward-dated ZH
    /// parser does. Asked on 2026-02-17, 月初 means March's — the user is not scheduling into the
    /// past. A *stated* prefix is never second-guessed, because it says which period is meant.
    @Test func aPassedBoundaryRollsForwardUnlessStated() {
        zhExpectDay("月初", 2026, 3, 1, forward: true, "the 1st has gone by, so next month's")
        zhExpectDay("年初", 2027, 1, 1, forward: true, "January has gone by, so next year's")
        zhExpectDay("3月初", 2026, 3, 1, forward: true, "…but March's 1st is still the nearest one")
        zhExpectDay("2月初", 2027, 2, 1, forward: true, "February's has gone by, so next year's")

        zhExpectDay("这个月初", 2026, 2, 1, forward: true, "stated: this month's, past or not")
        zhExpectDay("本月初", 2026, 2, 1, forward: true, "stated")
        zhExpectDay("今年初", 2026, 1, 1, forward: true, "stated")
        zhExpectDay("上个月底", 2026, 1, 31, forward: true, "stated, and deliberately in the past")

        zhExpectDay("月初", 2026, 2, 1, forward: false, "without forward dates nothing rolls")
    }

    /// The boundary word must be claimed whole — the older parsers may not take the 月 and abandon
    /// the 底, which is what produced 3月底 → March 1st with a stray 底.
    @Test func boundaryWordsAreClaimedWhole() {
        let results = zhParse("3月底交税", forward: true)
        #expect(results.count == 1, "3月底交税 → \(results.map { $0.text }), expected one result")
        #expect(results.first?.text == "3月底", "expected the whole 3月底, got \(results.first?.text ?? "nothing")")

        let boundary = zhParse("下个月底", forward: true)
        #expect(boundary.first?.text == "下个月底", "got \(boundary.first?.text ?? "nothing")")
    }

    /// 月亮 still has to survive the month patterns, and 年 words must not be cut in half.
    @Test func boundaryParserDoesNotBreakNeighbours() {
        zhExpectNothing("这个月亮很美", "月亮 = the moon")
        zhExpectNothing("他很年轻", "年轻 = young")
        zhExpectDay("下个月", 2026, 3, 1, forward: true)
        zhExpectDay("明年", 2027, 2, 17, forward: true)
    }

    // MARK: - Deadline particles

    /// The particle never changes which day is meant; it only decides whether the word survives into
    /// the task's name. In Chinese that matters more than in a Latin script, because the orphan
    /// fuses with what follows into a different word — 「前提交」 reads as 前提 + 交.
    @Test func deadlineParticlesJoinTheMatch() {
        #expect(zhParse("周五前提交报告").first?.text == "周五前")
        #expect(zhParse("本周内回复").first?.text == "本周内")
        #expect(zhParse("明天之前确认").first?.text == "明天之前")
        #expect(zhParse("今天之内完成").first?.text == "今天之内")
        #expect(zhParse("15号前交房租", forward: true).first?.text == "15号前")
        #expect(zhParse("月底前完成", forward: true).first?.text == "月底前")
    }

    /// …but a particle that is really the first character of the next word stays out of the match.
    @Test func wordOpeningsKeepTheirCharacter() {
        #expect(zhParse("明天前往北京").first?.text == "明天", "前往 = to head for")
        #expect(zhParse("明天前台确认").first?.text == "明天", "前台 = front desk")
        #expect(zhParse("本周内容安排").first?.text == "本周", "内容 = content")
        #expect(zhParse("下周内部会议").first?.text == "下周", "内部 = internal")
    }

    /// The particle must not disturb the date it follows.
    @Test func particlesDoNotMoveTheDate() {
        zhExpectDay("周五前提交报告", 2026, 2, 20, forward: true, "Friday of the reference week")
        zhExpectDay("明天之前确认", 2026, 2, 18, forward: true)
    }

    // MARK: - The 点 enumeration collision

    /// 点 is the measure word for items as well as the clock marker. This was a live defect for
    /// digits: 记录3点建议 ("note three suggestions") reported 03:00 and mangled the name.
    @Test func enumeratedPointsAreNotTimes() {
        zhExpectNothing("记录3点建议", "three suggestions, in digits")
        zhExpectNothing("总结3点意见", "three opinions")
        zhExpectNothing("提出2点要求", "two requirements")
        zhExpectNothing("有3点问题", "three questions")
        zhExpectNothing("讨论4点内容", "four items")
        zhExpectNothing("分为5点说明", "five points")
        zhExpectNothing("列出3点原因", "three reasons")
        zhExpectNothing("记录三点建议", "…and the same in Chinese numerals")
        zhExpectNothing("总结两点经验", "two lessons")
    }

    /// The guards must not swallow a real time. Every one of these is a verb after the hour.
    @Test func realTimesSurviveTheEnumerationGuards() {
        zhExpectTime("3点开会", hour: 3)
        zhExpectTime("3点提交报告", hour: 3, "提 is deliberately not an enumeration guard")
        zhExpectTime("三点看电影", hour: 3, "看 could begin 看法, and must still be a verb here")
        zhExpectTime("三点体检", hour: 3, "体 could begin 体会")
        zhExpectTime("三点理发", hour: 3, "理 could begin 理由")
        zhExpectTime("三点问医生", hour: 3, "问 could begin 问题")
        zhExpectTime("下午3点开会", hour: 15)
        zhExpectTime("明天3点开会", hour: 3)
    }

    /// Bare Chinese-numeral hours, which used to need a tail. 一 and 二 stay gated.
    @Test func bareChineseNumeralHours() {
        zhExpectTime("十点开会", hour: 10)
        zhExpectTime("十一点开会", hour: 11)
        zhExpectTime("十二点吃饭", hour: 12)
        zhExpectTime("两点开会", hour: 2)
        zhExpectTime("八点起床", hour: 8)
        zhExpectTime("九点半开会", hour: 9, minute: 30, "the tailed form is unchanged")
        zhExpectTime("兩點開會", hour: 2, "Traditional")
    }
}
