import Testing
import Foundation
@testable import Chrono

/// "next week <weekday>" (and "<weekday> next week") must resolve to that weekday WITHIN the
/// relative week, in EVERY language Space uses (en, nl, de, fr, es, pt, ja, zh; ko falls back to en).
/// Handled by the cross-locale `CombineRelativeWeekAndWeekdayRefiner`.
///
/// Reference: Tuesday 2026-02-17 (a deliberately mid-week ref so a standalone weekday and the
/// weekday-within-the-week differ). ISO weeks around it:
///   last = wk 7  (Mon 02-09 … Sun 02-15)
///   this = wk 8  (Mon 02-16 … Sun 02-22)
///   next = wk 9  (Mon 02-23 … Sun 03-01)
@Suite("next week <weekday> — all locales")
struct NextWeekWeekdayAllLocalesTests {
    private let ref = ParsingReference(instant: createDate(2026, 2, 17))
    private let opts = ParsingOptions(forwardDate: true)

    /// Resolve the first result and return its (year, month, day) in the current calendar.
    private func ymd(_ text: String, _ chrono: Chrono) -> (Int, Int, Int)? {
        guard let r = chrono.parse(text: text, referenceDate: ref, options: opts).first else { return nil }
        let c = Calendar.current.dateComponents([.year, .month, .day], from: r.start.date)
        guard let y = c.year, let m = c.month, let d = c.day else { return nil }
        return (y, m, d)
    }

    private func expect(_ text: String, _ chrono: Chrono, _ y: Int, _ m: Int, _ d: Int,
                        _ comment: Comment? = nil) {
        let got = ymd(text, chrono)
        #expect(got != nil, "\(text): no result")
        if let (gy, gm, gd) = got {
            #expect((gy, gm, gd) == (y, m, d),
                    "\(text) → \(gy)-\(gm)-\(gd), expected \(y)-\(m)-\(d)")
        }
    }

    /// (locale, week-first phrase, weekday-first phrase) — Thursday in each language.
    private var thursdayCases: [(Chrono, String, String)] {
        [
            (EN.casual, "next week thursday",            "thursday next week"),
            (NL.casual, "volgende week donderdag",       "donderdag volgende week"),
            (DE.casual, "nächste woche donnerstag",      "donnerstag nächste woche"),
            (FR.casual, "la semaine prochaine jeudi",    "jeudi la semaine prochaine"),
            (ES.casual, "la próxima semana el jueves",   "el jueves la próxima semana"),
            (PT.casual, "na próxima semana quinta-feira","quinta-feira na próxima semana"),
            (JA.casual, "来週木曜日",                      "木曜日来週"),
            // Chinese fuses the week word and the weekday into a single token — 下周四 IS
            // "next-week Thursday" — so the two word orders every other locale has collapse to
            // one phrase here. Both columns are deliberately the same string.
            (ZH.casual, "下周四",                          "下周四"),
        ]
    }

    /// Both word orders, every locale → Thursday of next week = 2026-02-26.
    @Test func nextWeekThursdayResolvesInEveryLocale() {
        for (chrono, weekFirst, weekdayFirst) in thursdayCases {
            expect(weekFirst, chrono, 2026, 2, 26)
            expect(weekdayFirst, chrono, 2026, 2, 26)
        }
    }

    /// Weekday variety incl. the ISO-week boundary day (Sunday is the last day of an ISO week).
    @Test func weekdayVarietyWithinNextWeek() {
        expect("next week monday", EN.casual, 2026, 2, 23)
        expect("next week tuesday", EN.casual, 2026, 2, 24)
        expect("next week saturday", EN.casual, 2026, 2, 28)
        expect("next week sunday", EN.casual, 2026, 3, 1)   // Sunday = end of ISO week 9
        expect("sunday next week", EN.casual, 2026, 3, 1)
        // Cross-locale Sunday/Monday spot checks.
        expect("volgende week zondag", NL.casual, 2026, 3, 1)
        expect("nächste woche sonntag", DE.casual, 2026, 3, 1)
        expect("来週日曜日", JA.casual, 2026, 3, 1)
        expect("来週月曜日", JA.casual, 2026, 2, 23)
        expect("下周日", ZH.casual, 2026, 3, 1)   // 日 = Sunday, the day that ENDS ISO week 9
        expect("下周一", ZH.casual, 2026, 2, 23)
    }

    /// "this/last week <weekday>" must use the WEEK anchor, not the standalone (forward-adjusted)
    /// weekday — e.g. "this week monday" is 02-16, not next Monday 02-23.
    @Test func thisAndLastWeekUseTheWeekAnchor() {
        expect("this week monday", EN.casual, 2026, 2, 16)
        expect("this week thursday", EN.casual, 2026, 2, 19)
        expect("last week thursday", EN.casual, 2026, 2, 12)
        expect("last week friday", EN.casual, 2026, 2, 13)
    }

    /// Number / explicit week-number forms also combine with a trailing weekday.
    @Test func numberAndWeekNumberFormsCombine() {
        expect("in 2 weeks thursday", EN.casual, 2026, 3, 5) // Thursday of ISO week 10
        expect("week 9 thursday", EN.casual, 2026, 2, 26)
    }

    /// The refiner must NOT over-merge: a relative week with no adjacent weekday, a bare weekday,
    /// and unrelated relative dates stay exactly as before.
    @Test func noSpuriousMerges() {
        // Standalone relative week stays a week (certain ISO week).
        #expect(EN.casual.parse(text: "next week", referenceDate: ref, options: opts).first?.start.isCertain(.isoWeek) == true)
        // Standalone weekday is the forward-adjusted weekday of the current week.
        expect("thursday", EN.casual, 2026, 2, 19)
        // "next month" is not a week and must not gain a weekday.
        #expect(EN.casual.parse(text: "next month", referenceDate: ref, options: opts).first?.start.isCertain(.isoWeek) == false)
    }

    /// Defensive: the "<week> <weekday>" combination must never crash in any locale (a malformed
    /// span in a relative-week result previously crashed the Dutch merge refiner).
    @Test func combiningNeverCrashes() {
        for (chrono, weekFirst, weekdayFirst) in thursdayCases {
            _ = chrono.parse(text: weekFirst, referenceDate: ref, options: opts)
            _ = chrono.parse(text: weekdayFirst, referenceDate: ref, options: opts)
            _ = chrono.parse(text: "\(weekFirst) \(weekdayFirst)", referenceDate: ref, options: opts)
        }
    }
}
