import Testing
import Foundation
@testable import Chrono

/// A relative month ("next month", "volgende maand", "来月", …) means the START of that month —
/// the 1st — not the reference date's day-of-month (which was rarely intended when scheduling).
/// Mirrors how a relative week anchors to its Monday. Across every locale Space uses.
///
/// Reference: 2026-06-21 (mid-month, so day-of-month 21 ≠ 1 makes the test meaningful).
@Suite("relative month → 1st — all locales")
struct RelativeMonthFirstTests {
    private let ref = ParsingReference(instant: createDate(2026, 6, 21))
    private let opts = ParsingOptions(forwardDate: true)

    private func ymd(_ text: String, _ chrono: Chrono) -> (Int, Int, Int)? {
        guard let r = chrono.parse(text: text, referenceDate: ref, options: opts).first else { return nil }
        let c = Calendar.current.dateComponents([.year, .month, .day], from: r.start.date)
        guard let y = c.year, let m = c.month, let d = c.day else { return nil }
        return (y, m, d)
    }

    private func expect(_ text: String, _ chrono: Chrono, _ y: Int, _ m: Int, _ d: Int) {
        let got = ymd(text, chrono)
        #expect(got != nil, "\(text): no result")
        if let g = got { #expect(g == (y, m, d), "\(text) → \(g), expected (\(y), \(m), \(d))") }
    }

    /// "next month" → 1st of next month (2026-07-01) in every language.
    @Test func nextMonthIsFirstOfNextMonth() {
        expect("next month", EN.casual, 2026, 7, 1)
        expect("volgende maand", NL.casual, 2026, 7, 1)
        expect("nächsten monat", DE.casual, 2026, 7, 1)
        expect("le mois prochain", FR.casual, 2026, 7, 1)
        expect("el próximo mes", ES.casual, 2026, 7, 1)
        expect("próximo mês", PT.casual, 2026, 7, 1)
        expect("来月", JA.casual, 2026, 7, 1)
        expect("下个月", ZH.casual, 2026, 7, 1)
    }

    /// this/last month also resolve to the 1st (start of the unit), e.g. in English.
    @Test func thisAndLastMonthAreFirstOfMonth() {
        expect("this month", EN.casual, 2026, 6, 1)
        expect("last month", EN.casual, 2026, 5, 1)
        expect("deze maand", NL.casual, 2026, 6, 1)
        expect("vorige maand", NL.casual, 2026, 5, 1)
        expect("这个月", ZH.casual, 2026, 6, 1)
        expect("上个月", ZH.casual, 2026, 5, 1)
    }

    /// Regression guard: "next week" stays a week (Monday anchor), and a relative DAY keeps its
    /// actual day — only the month/year units changed.
    @Test func dayAndWeekUnitsUnchanged() {
        // "next week" → certain ISO week (not converted to a day-of-month-1).
        #expect(EN.casual.parse(text: "next week", referenceDate: ref, options: opts).first?.start.isCertain(.isoWeek) == true)
        // "tomorrow" → the actual next day, not the 1st.
        expect("tomorrow", EN.casual, 2026, 6, 22)
    }
}
