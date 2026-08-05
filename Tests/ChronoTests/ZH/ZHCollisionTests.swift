// ZHCollisionTests.swift - The "must not parse" discipline for Chinese.
import Testing
import Foundation
@testable import Chrono

/// Chinese has no word boundaries, and ICU classifies Han ideographs as `\w`, so `\b` never fires
/// between two Han characters. Every guard that keeps a date token from firing inside ordinary
/// vocabulary is therefore explicit — a lookaround, a required compound, or a required measure word.
/// This suite is what proves those guards hold; it is the ZH counterpart of
/// `CommonWordCollisionTests` (whose Latin locales can lean on `\b`).
///
/// Reference: Tuesday 2026-02-17 12:00.
@Suite("ZH — common word collisions")
struct ZHCollisionTests {

    /// 分 alone is not a minute unit: 十分 means "very". Only 分钟 counts.
    @Test func numericAdverbsAreNotDurations() {
        zhExpectNothing("十分重要", "十分 = very, not 10 minutes")
        zhExpectNothing("十分感谢", "十分 = very")
        zhExpectNothing("这件事十分紧急", "十分 inside a sentence")
    }

    /// 点 is the single sharpest collision in the language: it is the clock marker *and* the
    /// measure word for "a bit". A Chinese-numeral hour therefore needs disambiguation.
    @Test func dianIsNotAlwaysAnHour() {
        zhExpectNothing("一点点", "一点点 = a little bit")
        zhExpectNothing("有点累", "有点 = somewhat")
        zhExpectNothing("改一点文案", "一点 = a little, not 01:00")
        zhExpectNothing("差一点忘了", "差一点 = nearly")
        zhExpectNothing("吃点心", "点心 = dim sum")
        zhExpectNothing("这个观点很好", "观点 = viewpoint")
        zhExpectNothing("工作重点", "重点 = key point")
        zhExpectNothing("集合地点", "地点 = location")
        zhExpectNothing("好点子", "点子 = idea")
        zhExpectNothing("他点头了", "点头 = to nod")
    }

    /// 日 and 天 only count inside a compound or as the closing marker of a `…月…` date.
    @Test func riAndTianDoNotFireInsideWords() {
        zhExpectNothing("我喜欢日本", "日本 = Japan")
        zhExpectNothing("生日快乐", "生日 = birthday")
        zhExpectNothing("一起聊天", "聊天 = to chat")
        zhExpectNothing("天气很好", "天气 = weather")
        // 今天天气很好 must yield 今天 and nothing else: the 天 of 天气 must not add a second result.
        let weather = zhParse("今天天气很好")
        #expect(weather.count == 1 && weather.first?.text == "今天",
                "今天天气很好 → \(weather.map { $0.text }), expected just 今天")
        zhExpectNothing("白天工作", "白天 = daytime")
        zhExpectNothing("每天跑步", "每天 = daily, a recurrence not a date")
        zhExpectNothing("日本日期", "日本 + 日期, never 本日")
    }

    /// 年 and 月 only count with an explicit relative prefix or a number plus measure word.
    @Test func nianAndYueDoNotFireInsideWords() {
        zhExpectNothing("他很年轻", "年轻 = young")
        zhExpectNothing("看月亮", "月亮 = the moon")
        zhExpectNothing("蜜月旅行", "蜜月 = honeymoon")
    }

    /// 周 alone is never a weekday — it needs one of 一二三四五六日天 after it. It is also a
    /// very common surname.
    @Test func zhouAloneIsNotAWeekday() {
        zhExpectNothing("周围很安静", "周围 = surroundings")
        zhExpectNothing("服务很周到", "周到 = thoughtful")
        zhExpectNothing("周先生来了", "周 = a surname")
    }

    /// 号 only counts as a day-of-month when it closes a `…月…` pair, so metro lines are safe.
    @Test func haoIsNotAlwaysADayOfMonth() {
        zhExpectNothing("坐3号线", "3号线 = metro line 3")
        zhExpectNothing("十一号线换乘", "十一号线 = metro line 11")
    }

    /// 上/下 form many compounds that have nothing to do with weeks.
    @Test func shangAndXiaDoNotFireInsideWords() {
        zhExpectNothing("下班后回家", "下班 = to leave work")
        zhExpectNothing("上班时间", "上班 = to go to work")
        zhExpectNothing("等一下", "一下 = a moment")
    }

    /// 过 and 半 form fixed compounds that must not be read as relative expressions.
    @Test func guoAndBanCompounds() {
        zhExpectNothing("超过3天没洗澡", "超过 = to exceed")
        zhExpectNothing("不过3天就好了", "不过 = however")
    }

    /// A duration is not a point in time — the same rule the other locales carry
    /// (EN "for 2 hours", JA "2時間", NL "gedurende 2 uur").
    @Test func durationsAreNotClockTimes() {
        zhExpectNothing("会议2小时", "2小时 is a duration, not 02:00")
        zhExpectNothing("24小时营业", "24小时 is a duration")
        zhExpectNothing("开会30分钟", "30分钟 is a duration")
    }

    /// 每 marks a recurrence, not a date: 每周末 is "every weekend", a repeat rule the host
    /// schedules, never one specific Saturday. Same rule as 每天 above, one unit up. The measure
    /// word may sit between 每 and the noun (每个周末), which is why the guard is three lookbehinds.
    @Test func meiMarksARecurrenceNotADate() {
        zhExpectNothing("每周末", "每周末 = every weekend")
        zhExpectNothing("每个周末", "每个周末 = every weekend, with the measure word")
        zhExpectNothing("每周", "每周 = every week")
        zhExpectNothing("每周三", "每周三 = every Wednesday")
        zhExpectNothing("每个星期三", "每个星期三 = every Wednesday, with the measure word")
        zhExpectNothing("每个月", "每个月 = every month")
    }

    /// The counterpart: every guarded token must still work in its real usage.
    @Test func realExpressionsStillParse() {
        zhExpectSomething("今天", "今天 still parses")
        zhExpectSomething("明天开会", "明天 still parses with trailing text")
        zhExpectSomething("下周三", "下周三 still parses")
        zhExpectSomething("3月15日", "3月15日 still parses")
        zhExpectSomething("下午3点", "下午3点 still parses")
        zhExpectSomething("3天后", "3天后 still parses")
        zhExpectSomething("30分钟后", "30分钟后 still parses")
        zhExpectSomething("2小时后", "2小时后 still parses")
        zhExpectSomething("周末", "周末 still parses")
        zhExpectSomething("下周末", "下周末 still parses")
        zhExpectSomething("这个周末", "这个周末 still parses (measure word, no 每)")
        zhExpectSomething("本周", "本周 still parses")
        zhExpectSomething("周三", "周三 still parses")
        zhExpectSomething("下个星期三", "下个星期三 still parses (measure word, no 每)")
        zhExpectSomething("一点半", "一点半 still parses")
    }
}
