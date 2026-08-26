import Testing
import Foundation
@testable import Chrono

/// A month the user named without a year, that has already gone by, means the **next** one:
/// typed on 26 August 2026, "april 22" is 22 April 2027 — not four months into the past. Chrono
/// only ever *infers* the reference year here, so `ForwardDateRefiner` corrects it centrally,
/// which is what makes this hold for every locale, both word orders, and with or without a time.
///
/// Reference throughout: 2026-08-26 (a Wednesday). April is behind it; October is ahead of it;
/// 20 August is behind it *within the same month* — the case per-locale "month < current month"
/// heuristics all missed.
@Suite("Past month rolls forward — all locales")
struct PastMonthRollsForwardTests {
    private let ref = ParsingReference(instant: createDate(2026, 8, 26, 10))
    private let opts = ParsingOptions(forwardDate: true)

    private func ymd(_ text: String, _ chrono: Chrono) -> (Int, Int, Int)? {
        guard let r = chrono.parse(text: text, referenceDate: ref, options: opts).first else { return nil }
        let c = Calendar.current.dateComponents([.year, .month, .day], from: r.start.date)
        guard let y = c.year, let m = c.month, let d = c.day else { return nil }
        return (y, m, d)
    }

    /// Asserts bare and with a leading word (prefix invariance — real task input is "buy milk …").
    private func expect(_ text: String, _ chrono: Chrono, _ y: Int, _ m: Int, _ d: Int,
                        _ location: SourceLocation = #_sourceLocation) {
        for t in [text, "buy milk \(text)"] {
            let got = ymd(t, chrono)
            #expect(got != nil, "\(t): no result", sourceLocation: location)
            if let g = got {
                #expect(g == (y, m, d), "\(t) → \(g), expected (\(y), \(m), \(d))", sourceLocation: location)
            }
        }
    }

    // MARK: - The reported defect

    @Test func aPastMonthMeansNextYearInBothOrders() {
        expect("april 22", EN.casual, 2027, 4, 22)
        expect("22 april", EN.casual, 2027, 4, 22)
        expect("apr 22", EN.casual, 2027, 4, 22)
        expect("22 apr", EN.casual, 2027, 4, 22)
    }

    /// The half that already worked must keep working: a month still ahead stays in this year.
    @Test func aFutureMonthStaysInTheReferenceYear() {
        expect("october 22", EN.casual, 2026, 10, 22)
        expect("22 october", EN.casual, 2026, 10, 22)
    }

    /// A day earlier in the *current* month is past too — the case a month-number comparison misses.
    @Test func anEarlierDayInTheCurrentMonthRollsForward() {
        expect("august 20", EN.casual, 2027, 8, 20)
        expect("20 august", EN.casual, 2027, 8, 20)
    }

    /// The reference day itself is not past. Compared at day granularity, so the hour of typing
    /// (10:00 here, against an implied noon) can never push today a year out.
    @Test func theReferenceDayItselfStays() {
        expect("august 26", EN.casual, 2026, 8, 26)
        expect("26 august", EN.casual, 2026, 8, 26)
    }

    // MARK: - Every locale, both orders

    @Test func everyLocaleRollsAPastMonthForward() {
        expect("april 22", EN.casual, 2027, 4, 22)
        expect("22 april", EN.casual, 2027, 4, 22)
        expect("22 april", NL.casual, 2027, 4, 22)
        expect("april 22", NL.casual, 2027, 4, 22)
        expect("22. april", DE.casual, 2027, 4, 22)
        expect("april 22", DE.casual, 2027, 4, 22)
        expect("22 avril", FR.casual, 2027, 4, 22)
        expect("avril 22", FR.casual, 2027, 4, 22)
        expect("22 de abril", ES.casual, 2027, 4, 22)
        expect("22 abril", ES.casual, 2027, 4, 22)
        expect("abril 22", ES.casual, 2027, 4, 22)
        expect("22 de abril", PT.casual, 2027, 4, 22)
        expect("22 abril", PT.casual, 2027, 4, 22)
        expect("abril 22", PT.casual, 2027, 4, 22)
        expect("4月22日", JA.casual, 2027, 4, 22)
        expect("4月22日", ZH.casual, 2027, 4, 22)
    }

    @Test func everyLocaleKeepsAFutureMonthInThisYear() {
        expect("october 22", EN.casual, 2026, 10, 22)
        expect("22 oktober", NL.casual, 2026, 10, 22)
        expect("22. oktober", DE.casual, 2026, 10, 22)
        expect("22 octobre", FR.casual, 2026, 10, 22)
        expect("22 de octubre", ES.casual, 2026, 10, 22)
        expect("22 de outubro", PT.casual, 2026, 10, 22)
        expect("10月22日", JA.casual, 2026, 10, 22)
        expect("10月22日", ZH.casual, 2026, 10, 22)
    }

    // MARK: - A stated time must not block the roll

    /// Merging a date with a time used to promote the *inferred* year to a stated one, which hid
    /// the date from forward-dating. The merge now carries certainty across unchanged.
    @Test func aStatedTimeStillRollsForward() {
        expect("april 22 3pm", EN.casual, 2027, 4, 22)
        expect("22 april 3pm", EN.casual, 2027, 4, 22)
        expect("august 20 9am", EN.casual, 2027, 8, 20)
        expect("22. april 15:00", DE.casual, 2027, 4, 22)
        expect("22 avril 15:00", FR.casual, 2027, 4, 22)
        expect("22 de abril 15:00", ES.casual, 2027, 4, 22)
        expect("22 de abril 15:00", PT.casual, 2027, 4, 22)
        expect("4月22日 15時", JA.casual, 2027, 4, 22)
        expect("4月22日 15点", ZH.casual, 2027, 4, 22)
    }

    // MARK: - What must NOT move

    /// A year the user actually typed is never second-guessed, even into the past.
    @Test func anExplicitYearIsRespected() {
        expect("april 22 2026", EN.casual, 2026, 4, 22)
        expect("22 april 2026", EN.casual, 2026, 4, 22)
        expect("22 april 2026", NL.casual, 2026, 4, 22)
        expect("22 avril 2026", FR.casual, 2026, 4, 22)
    }

    /// Only forward-dating parses roll. With the option off, a past month stays past.
    @Test func backwardParsingIsUnaffected() {
        let off = ParsingOptions(forwardDate: false)
        let r = EN.casual.parse(text: "buy milk april 22", referenceDate: ref, options: off).first
        #expect(r != nil)
        let c = Calendar.current.dateComponents([.year, .month, .day], from: r!.start.date)
        #expect((c.year, c.month, c.day) == (2026, 4, 22))
    }

    /// Weekday- and relative-based results carry their own forward-dating; a year is the wrong
    /// unit to move them by, so they must be left alone.
    @Test func weekdayAndRelativeFormsAreUntouched() {
        expect("tomorrow", EN.casual, 2026, 8, 27)
        expect("monday", EN.casual, 2026, 8, 31)
        expect("next friday", EN.casual, 2026, 8, 28)
        expect("in 3 days", EN.casual, 2026, 8, 29)
    }

    // MARK: - Ranges

    /// A range moves whole, so it can never invert: "20 august to 5 september" is next year's pair,
    /// not a start a year after its own end.
    @Test func aRangeMovesWhole() {
        let r = EN.casual.parse(text: "august 20 to september 5", referenceDate: ref, options: opts).first
        #expect(r != nil)
        guard let r, let end = r.end else { return }
        let s = Calendar.current.dateComponents([.year, .month, .day], from: r.start.date)
        let e = Calendar.current.dateComponents([.year, .month, .day], from: end.date)
        #expect((s.year, s.month, s.day) == (2027, 8, 20))
        #expect((e.year, e.month, e.day) == (2027, 9, 5))
        #expect(r.start.date < end.date)
    }

    /// A range whose end alone has gone by closes in the following year rather than inverting.
    @Test func aRangeCrossingTheYearBoundaryClosesForward() {
        let r = EN.casual.parse(text: "december 28 to january 3", referenceDate: ref, options: opts).first
        #expect(r != nil)
        guard let r, let end = r.end else { return }
        let s = Calendar.current.dateComponents([.year, .month, .day], from: r.start.date)
        let e = Calendar.current.dateComponents([.year, .month, .day], from: end.date)
        #expect((s.year, s.month, s.day) == (2026, 12, 28))
        #expect((e.year, e.month, e.day) == (2027, 1, 3))
        #expect(r.start.date < end.date)
    }
}
