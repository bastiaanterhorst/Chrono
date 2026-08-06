// ZHIdiomaticTimeTests.swift - The two places Chinese time input needs a rule Latin locales don't.
import Testing
import Foundation
@testable import Chrono

/// Chinese states a time in two shapes that have no Latin equivalent, and both were found by
/// running idiomatic phrases against the English and Dutch anchors:
///
/// 1. **A contracted day+time compound.** English writes "tonight 8pm" as separate words, so the
///    clock time simply merges with the day word. Chinese fuses them into 今晚, which carries an
///    implied hour of its own — so an explicit clock time has to *override* that implied hour
///    rather than sit beside it.
/// 2. **A measure word inside the unit.** 一个小时 is the ordinary way to say "an hour"; dropping
///    the 个 (一小时) is the terser variant, not the default. The unit lexicon has to accept both,
///    the way English accepts "in an hour" as readily as "in one hour".
///
/// Reference: Tuesday 2026-02-17 12:00.
@Suite("ZH — idiomatic time input")
struct ZHIdiomaticTimeTests {

    /// Asserts a phrase yields exactly one result. This is the real content of the compound fix:
    /// the failure it guards against produced *two* results (今晚 at 22:00 plus a stray 8点), which
    /// a host applying last-wins would silently resolve to the wrong hour.
    private func expectSingle(_ text: String, _ comment: String = "") {
        let results = zhParse(text)
        #expect(results.count == 1,
                "\(comment)「\(text)」→ \(results.count) results \(results.map { "'\($0.text)'" }), expected exactly 1")
    }

    // MARK: - Contracted day + time compounds

    /// 今晚8点 is 20:00 tonight — one expression, not 今晚's implied 22:00 plus an orphaned 8点.
    @Test func compoundYieldsToAnExplicitClockTime() {
        expectSingle("今晚8点")
        zhExpectDay("今晚8点", 2026, 2, 17)
        zhExpectTime("今晚8点", hour: 20)

        expectSingle("明早9点半")
        zhExpectDay("明早9点半", 2026, 2, 18, comment: "明早 names tomorrow")
        zhExpectTime("明早9点半", hour: 9, minute: 30)

        expectSingle("明晚7点")
        zhExpectDay("明晚7点", 2026, 2, 18)
        zhExpectTime("明晚7点", hour: 19)

        expectSingle("今早8点")
        zhExpectTime("今早8点", hour: 8, "a morning compound keeps the hour on the morning half")

        expectSingle("昨晚10点")
        zhExpectDay("昨晚10点", 2026, 2, 16, comment: "昨晚 names yesterday")
        zhExpectTime("昨晚10点", hour: 22)
    }

    /// The colon parser has to agree with the 点 parser — the two differ only in how the time is
    /// spelled, never in what a prefix means.
    @Test func compoundYieldsToAColonTimeToo() {
        expectSingle("今晚8:30")
        zhExpectTime("今晚8:30", hour: 20, minute: 30)

        expectSingle("明早9:15")
        zhExpectDay("明早9:15", 2026, 2, 18)
        zhExpectTime("明早9:15", hour: 9, minute: 15)
    }

    /// The hour may be written in any of the three scripts, and the compounds have Traditional forms.
    @Test func compoundAcceptsEveryScript() {
        zhExpectTime("今晚八点", hour: 20, "Chinese numeral hour")
        zhExpectTime("明早七点半", hour: 7, minute: 30, "Chinese numeral with a fraction tail")
        zhExpectTime("今晚8點", hour: 20, "Traditional 點")
        zhExpectTime("明早9點半", hour: 9, minute: 30, "Traditional")
        zhExpectTime("昨夜11点", hour: 23, "夜 compound")
    }

    /// A bare compound keeps the implied hour it always had — the guard must only fire when a clock
    /// time actually follows.
    @Test func bareCompoundsAreUnchanged() {
        zhExpectTime("今晚", hour: 22, "evening compounds imply 22:00")
        zhExpectTime("明晚", hour: 22)
        zhExpectTime("今早", hour: 6, "morning compounds imply 06:00")
        zhExpectTime("明早", hour: 6)
        zhExpectDay("明早", 2026, 2, 18)
        zhExpectTime("昨晚", hour: 22)
        zhExpectDay("昨晚", 2026, 2, 16)
    }

    /// The same discipline for the uncontracted forms, which already worked and must keep working.
    @Test func uncontractedFormsStillResolve() {
        expectSingle("明天晚上8点")
        zhExpectTime("明天晚上8点", hour: 20)
        zhExpectDay("明天晚上8点", 2026, 2, 18)

        expectSingle("下午3点")
        zhExpectTime("下午3点", hour: 15)

        expectSingle("下午3:30")
        zhExpectTime("下午3:30", hour: 15, minute: 30, "a bare time-of-day word yields to a colon time")

        expectSingle("周五晚上8点")
        zhExpectTime("周五晚上8点", hour: 20)
    }

    // MARK: - The 个 measure word

    /// 一个小时后 is the ordinary phrasing — as ordinary as English "in an hour", which the English
    /// locale resolves. Without the measure word in the unit lexicon it produced nothing at all.
    @Test func hourUnitsAcceptTheMeasureWord() {
        zhExpectTime("一个小时后", hour: 13)
        zhExpectTime("两个小时后", hour: 14)
        zhExpectTime("三个小时后", hour: 15)
        zhExpectTime("一个小时前", hour: 11, "the measure word works in the past direction too")
        zhExpectTime("两个钟头后", hour: 14, "钟头 is the colloquial hour unit")
        zhExpectTime("一個小時後", hour: 13, "Traditional")
    }

    /// The forms that already worked must be untouched — in particular 半个小时后, whose 个 is
    /// handled by a separate branch, and 个月, whose measure word is mandatory rather than optional.
    @Test func neighbouringUnitFormsAreUnchanged() {
        zhExpectTime("一小时后", hour: 13, "the measure word stays optional")
        zhExpectTime("2小时后", hour: 14)
        zhExpectTime("半个小时后", hour: 12, minute: 30)
        zhExpectTime("30分钟后", hour: 12, minute: 30)
        zhExpectDay("一个月后", 2026, 3, 17, comment: "个月 is still a month, not an hour")
        zhExpectDay("3天后", 2026, 2, 20)
    }

    // MARK: - Deliberate limitations

    /// These are pinned, not aspirational. Each was checked against the English and Dutch anchors
    /// and left alone on purpose; the test exists so a future change to any of them is a deliberate
    /// decision rather than an accident.
    @Test func documentedLimitationsHold() {
        // A bare Chinese-numeral hour stays unread: 一点 is "a little", 两点建议 is "two suggestions".
        // The disambiguated forms all work, so nothing idiomatic is actually lost.
        zhExpectNothing("两点", "a bare Chinese-numeral hour needs a tail or a prefix")
        zhExpectNothing("十点", "same rule, no collision of its own but the gate is uniform")
        zhExpectSomething("下午两点", "…and the prefixed form resolves")
        zhExpectSomething("两点半", "…as does the form with a tail")
        zhExpectSomething("两点钟", "…and the 钟 marker")

        // "One and a half hours" is not read. English drops the half silently ("in an hour and a
        // half" → 13:00) and Dutch reads nothing at all, so refusing the phrase is at or above both
        // anchors — and a wrong hour would be worse than no hour.
        zhExpectNothing("一个半小时后", "N and a half hours is deliberately not read")

        // 晚上12点 resolves to 12:00, exactly as English "tonight at 12" and "12pm" do. Chinese is
        // in principle unambiguous here where English is not, but the fix needs a day rollover that
        // the merge refiners would have to agree on; 半夜12点 gives Chinese a working midnight.
        zhExpectTime("晚上12点", hour: 12, "parity with EN 12pm")
        zhExpectTime("半夜12点", hour: 0, "…and 半夜 is the unambiguous way to say midnight")
    }
}

/// `zhExpectDay` takes its trailing note positionally; this keeps the call sites above readable.
private func zhExpectDay(_ text: String, _ y: Int, _ m: Int, _ d: Int, comment: String) {
    zhExpectDay(text, y, m, d, forward: false, comment)
}
