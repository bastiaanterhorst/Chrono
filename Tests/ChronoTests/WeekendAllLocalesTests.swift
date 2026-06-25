import Testing
import Foundation
@testable import Chrono

/// "this/next/last weekend" must resolve to the FIRST weekend day (Saturday in every locale Space
/// supports) as a concrete DAY — not an ISO week — in en, nl, de, fr, es, pt, ja.
///
/// Reference: Wednesday 2026-02-18 (mid-week, so the weekend is unambiguously in the future).
/// ISO week 8: Mon 02-16 … Sun 02-22 → this weekend = Sat 02-21, next = Sat 02-28, last = Sat 02-14.
@Suite("weekend — all locales")
struct WeekendAllLocalesTests {
    private let ref = ParsingReference(instant: createDate(2026, 2, 18))
    private let opts = ParsingOptions(forwardDate: true)

    /// Assert the first result resolves to the given day AND is a day (not an ISO week).
    private func expectWeekend(_ text: String, _ chrono: Chrono, _ y: Int, _ m: Int, _ d: Int) {
        let r = chrono.parse(text: text, referenceDate: ref, options: opts).first
        #expect(r != nil, "\(text): no result")
        guard let r else { return }
        let c = Calendar.current.dateComponents([.year, .month, .day], from: r.start.date)
        guard let gy = c.year, let gm = c.month, let gd = c.day else {
            #expect(Bool(false), "\(text): no date"); return
        }
        #expect((gy, gm, gd) == (y, m, d), "\(text) → \(gy)-\(gm)-\(gd), expected \(y)-\(m)-\(d)")
        // A weekend resolves to a specific day — it must NOT be classified as an ISO week.
        #expect(r.start.isCertain(.isoWeek) == false, "\(text): should be a day, not an ISO week")
    }

    /// (locale, this / next / last weekend phrase) per language.
    private var cases: [(Chrono, String, String, String)] {
        [
            (EN.casual, "this weekend",        "next weekend",            "last weekend"),
            (NL.casual, "dit weekend",         "volgend weekend",         "afgelopen weekend"),
            (DE.casual, "dieses wochenende",   "nächstes wochenende",     "letztes wochenende"),
            (FR.casual, "ce week-end",         "le week-end prochain",    "le week-end dernier"),
            (ES.casual, "este fin de semana",  "el próximo fin de semana","el fin de semana pasado"),
            (PT.casual, "este fim de semana",  "o próximo fim de semana", "o fim de semana passado"),
            (JA.casual, "今週末",               "来週末",                   "先週末"),
        ]
    }

    @Test func weekendResolvesToFirstWeekendDayInEveryLocale() {
        for (chrono, thisW, nextW, lastW) in cases {
            expectWeekend(thisW, chrono, 2026, 2, 21)
            expectWeekend(nextW, chrono, 2026, 2, 28)
            expectWeekend(lastW, chrono, 2026, 2, 14)
        }
    }

    /// Bare Japanese "週末" (no modifier) means this weekend, and a trailing-context English phrase
    /// still resolves the weekend rather than the week.
    @Test func weekendVariants() {
        expectWeekend("週末", JA.casual, 2026, 2, 21)
        expectWeekend("offsite this weekend", EN.casual, 2026, 2, 21)
        expectWeekend("planning next weekend", EN.casual, 2026, 2, 28)
    }
}
