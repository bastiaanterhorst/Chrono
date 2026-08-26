import Testing
import Foundation
@testable import Chrono

/// Forward-dating has to behave the same way whatever construction the user reached for — a month
/// name, an ISO week, a numeric date, a weekday. Each of those took a different code path, and each
/// path had drifted: week numbers called the *current* week past from Tuesday onward, the Dutch
/// numeric parser compared months alone, and the Dutch weekday parser read today's own weekday as
/// next week's.
///
/// The unifying rule these tests pin: a construction is only rolled forward once it has *entirely*
/// gone by — a week when its Sunday has passed, a date when its day has, a weekday when it is
/// behind today. Today itself is never rolled.
@Suite("Forward-dating across date constructions")
struct ForwardDatingConstructionsTests {
    // Wed 26 Aug 2026, 10:00 — ISO week 35 of 2026 (Mon 24 – Sun 30 August).
    private let wed = createDate(2026, 8, 26, 10)
    private let opts = ParsingOptions(forwardDate: true)

    private let all: [(String, Chrono)] = [
        ("EN", EN.casual), ("NL", NL.casual), ("DE", DE.casual), ("FR", FR.casual),
        ("ES", ES.casual), ("PT", PT.casual), ("JA", JA.casual), ("ZH", ZH.casual),
    ]

    private func ymd(_ text: String, _ chrono: Chrono, ref: Date) -> (Int, Int, Int)? {
        guard let r = chrono.parse(text: text, referenceDate: ParsingReference(instant: ref),
                                   options: opts).first else { return nil }
        let c = Calendar.current.dateComponents([.year, .month, .day], from: r.start.date)
        guard let y = c.year, let m = c.month, let d = c.day else { return nil }
        return (y, m, d)
    }

    private func expect(_ text: String, _ chrono: Chrono, ref: Date, _ y: Int, _ m: Int, _ d: Int,
                        _ label: String = "", _ loc: SourceLocation = #_sourceLocation) {
        let got = ymd(text, chrono, ref: ref)
        #expect(got != nil, "[\(label)] \(text): no result", sourceLocation: loc)
        if let g = got {
            #expect(g == (y, m, d), "[\(label)] \(text) → \(g), expected (\(y), \(m), \(d))",
                    sourceLocation: loc)
        }
    }

    // MARK: - ISO week numbers

    /// The week you are standing in is not past. Components resolve to the week's *Monday*, so
    /// comparing that against the reference instant used to send "w35", typed on the Wednesday of
    /// week 35, to week 35 of the following year.
    @Test func theCurrentWeekIsNotRolledForward() {
        let forms = ["EN": "w35", "NL": "w35", "DE": "KW 35", "FR": "semaine 35",
                     "ES": "semana 35", "PT": "semana 35", "JA": "第35週", "ZH": "第35周"]
        for (label, chrono) in all {
            expect(forms[label]!, chrono, ref: wed, 2026, 8, 24, label)   // Monday of week 35
        }
    }

    /// Still true on the last day of that week.
    @Test func theCurrentWeekHoldsOnItsFinalDay() {
        let sunday = createDate(2026, 8, 30, 10)   // Sun 30 Aug — the last day of week 35
        expect("w35", EN.casual, ref: sunday, 2026, 8, 24)
        expect("w35", NL.casual, ref: sunday, 2026, 8, 24)
    }

    /// A week that has fully gone by rolls to the next year, in every locale.
    @Test func aFinishedWeekRollsToNextYear() {
        let forms = ["EN": "w34", "NL": "w34", "DE": "KW 34", "FR": "semaine 34",
                     "ES": "semana 34", "PT": "semana 34", "JA": "第34週", "ZH": "第34周"]
        for (label, chrono) in all {
            expect(forms[label]!, chrono, ref: wed, 2027, 8, 23, label)
        }
    }

    /// A week still ahead stays in this year.
    @Test func aComingWeekStaysInThisYear() {
        let forms = ["EN": "w36", "NL": "w36", "DE": "KW 36", "FR": "semaine 36",
                     "ES": "semana 36", "PT": "semana 36", "JA": "第36週", "ZH": "第36周"]
        for (label, chrono) in all {
            expect(forms[label]!, chrono, ref: wed, 2026, 8, 31, label)
        }
    }

    /// Around the turn of the year: week 1 belongs to the coming year, and the year's own final
    /// week (2026 has 53) is still current on 30 December.
    @Test func weeksAcrossTheYearBoundary() {
        let dec = createDate(2026, 12, 30, 10)
        expect("w1", EN.casual, ref: dec, 2027, 1, 4)
        expect("w53", EN.casual, ref: dec, 2026, 12, 28)   // the week 30 December sits in
        expect("w52", EN.casual, ref: dec, 2027, 12, 27)   // already finished
        expect("w1", EN.casual, ref: wed, 2027, 1, 4)
    }

    // MARK: - Numeric (slash / dotted) dates

    /// Every locale's numeric form rolls a day that has gone by — including one earlier in the
    /// current month, which the Dutch parser missed by comparing months alone.
    @Test func numericDatesRollAPastDay() {
        expect("20/8", NL.casual, ref: wed, 2027, 8, 20, "NL")
        expect("25/8", NL.casual, ref: wed, 2027, 8, 25, "NL")
        expect("20.8.", DE.casual, ref: wed, 2027, 8, 20, "DE")
        expect("20/8", FR.casual, ref: wed, 2027, 8, 20, "FR")
        expect("20/8", ES.casual, ref: wed, 2027, 8, 20, "ES")
        expect("20/8", PT.casual, ref: wed, 2027, 8, 20, "PT")
        expect("8.20", EN.casual, ref: wed, 2027, 8, 20, "EN")   // EN is month-first
        expect("22/4", NL.casual, ref: wed, 2027, 4, 22, "NL")
        expect("4.22", EN.casual, ref: wed, 2027, 4, 22, "EN")
    }

    @Test func numericDatesKeepTodayAndTheFuture() {
        expect("26/8", NL.casual, ref: wed, 2026, 8, 26, "NL")
        expect("27/8", NL.casual, ref: wed, 2026, 8, 27, "NL")
        expect("22/10", NL.casual, ref: wed, 2026, 10, 22, "NL")
        expect("26.8.", DE.casual, ref: wed, 2026, 8, 26, "DE")
        expect("26/8", FR.casual, ref: wed, 2026, 8, 26, "FR")
        expect("26/8", ES.casual, ref: wed, 2026, 8, 26, "ES")
        expect("26/8", PT.casual, ref: wed, 2026, 8, 26, "PT")
        expect("8.26", EN.casual, ref: wed, 2026, 8, 26, "EN")
    }

    /// A year the user wrote out is honoured, past or not.
    @Test func numericDatesWithAStatedYearAreLeftAlone() {
        expect("22/4/2026", NL.casual, ref: wed, 2026, 4, 22, "NL")
        expect("22.4.2026", DE.casual, ref: wed, 2026, 4, 22, "DE")
    }

    // MARK: - Weekdays

    /// A bare weekday naming today means today — in every locale. Dutch alone applied the
    /// "volgende" (next) rule to the bare form and jumped a week.
    @Test func todaysOwnWeekdayMeansToday() {
        let forms = ["EN": "wednesday", "NL": "woensdag", "DE": "Mittwoch", "FR": "mercredi",
                     "ES": "miércoles", "PT": "quarta-feira", "JA": "水曜日", "ZH": "星期三"]
        for (label, chrono) in all {
            expect(forms[label]!, chrono, ref: wed, 2026, 8, 26, label)
        }
    }

    /// Also on a Sunday, where a week-boundary off-by-one would show up.
    @Test func todaysOwnWeekdayMeansTodayOnASunday() {
        let sunday = createDate(2026, 8, 30, 10)
        let forms = ["EN": "sunday", "NL": "zondag", "DE": "Sonntag", "FR": "dimanche",
                     "ES": "domingo", "PT": "domingo", "JA": "日曜日", "ZH": "星期日"]
        for (label, chrono) in all {
            expect(forms[label]!, chrono, ref: sunday, 2026, 8, 30, label)
        }
    }

    /// A weekday behind today still means next week's.
    @Test func aPassedWeekdayMeansNextWeek() {
        let forms = ["EN": "monday", "NL": "maandag", "DE": "Montag", "FR": "lundi",
                     "ES": "lunes", "PT": "segunda-feira", "JA": "月曜日", "ZH": "星期一"]
        for (label, chrono) in all {
            expect(forms[label]!, chrono, ref: wed, 2026, 8, 31, label)
        }
    }

    /// The explicit modifiers keep their own meanings — "next Wednesday" on a Wednesday is still
    /// a week out, which is exactly what the bare form must not do.
    @Test func weekdayModifiersAreUnchanged() {
        expect("next wednesday", EN.casual, ref: wed, 2026, 9, 2, "EN")
        expect("this wednesday", EN.casual, ref: wed, 2026, 8, 26, "EN")
        expect("last wednesday", EN.casual, ref: wed, 2026, 8, 19, "EN")
        expect("volgende woensdag", NL.casual, ref: wed, 2026, 9, 2, "NL")
        expect("komende woensdag", NL.casual, ref: wed, 2026, 9, 2, "NL")
        expect("deze woensdag", NL.casual, ref: wed, 2026, 8, 26, "NL")
        expect("volgende week woensdag", NL.casual, ref: wed, 2026, 9, 2, "NL")
    }

    // MARK: - Constructions that must never be forward-dated

    /// Explicitly backward-looking words stay in the past, and relative units are computed, not
    /// rolled.
    @Test func backwardAndRelativeFormsAreUntouched() {
        expect("yesterday", EN.casual, ref: wed, 2026, 8, 25, "EN")
        expect("3 days ago", EN.casual, ref: wed, 2026, 8, 23, "EN")
        expect("last monday", EN.casual, ref: wed, 2026, 8, 24, "EN")
        expect("today", EN.casual, ref: wed, 2026, 8, 26, "EN")
        expect("in 2 weeks", EN.casual, ref: wed, 2026, 9, 7, "EN")
        expect("next month", EN.casual, ref: wed, 2026, 9, 1, "EN")
        expect("this weekend", EN.casual, ref: wed, 2026, 8, 29, "EN")
        expect("next weekend", EN.casual, ref: wed, 2026, 9, 5, "EN")
    }
}
