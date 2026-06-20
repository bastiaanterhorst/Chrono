import Testing
import Foundation
@testable import Chrono

/// Regression tests for fixes made while building Space's natural-language task input.
/// (`createDate` is the shared helper defined in DECasualDateParserTests.swift.)
@Suite("Relative-time certainty & locale fixes")
struct RelativeTimeAndLocaleFixesTests {
    private let ref = ParsingReference(instant: createDate(2025, 6, 15)) // a Sunday, noon
    private let opts = ParsingOptions(forwardDate: true)

    private func firstResult(_ text: String, _ chrono: Chrono = Chrono.casual) -> ParsedResult? {
        chrono.parse(text: text, referenceDate: ref, options: opts).first
    }

    /// Relative date phrases ("in 3 days", "next week") must NOT report a certain hour —
    /// they carry no clock time. Previously they leaked the reference time as "known".
    @Test func relativeDatesHaveNoSpuriousTime() {
        // Languages Space uses: en, nl, fr, es, pt, ja (ko falls back to en in Chrono).
        #expect(firstResult("in 3 days")?.start.isCertain(.hour) == false)
        #expect(firstResult("5 days later")?.start.isCertain(.hour) == false)
        #expect(firstResult("next week")?.start.isCertain(.hour) == false)
        #expect(firstResult("in 2 weeks")?.start.isCertain(.hour) == false)
        #expect(firstResult("week 23")?.start.isCertain(.hour) == false)
        #expect(firstResult("en 3 días", Chrono.es.casual)?.start.isCertain(.hour) == false)
        #expect(firstResult("over 3 dagen", Chrono.nl.casual)?.start.isCertain(.hour) == false)
        #expect(firstResult("dans 3 jours", Chrono.fr.casual)?.start.isCertain(.hour) == false)
        #expect(firstResult("em 3 dias", Chrono.pt.casual)?.start.isCertain(.hour) == false)
        #expect(firstResult("3日後", Chrono.ja.casual)?.start.isCertain(.hour) == false)
    }

    /// `assignNull(.hour)` (used by week parsers) must not leak the internal -1 sentinel into
    /// the public result: hour should be absent from knownValues and `get` must never return -1.
    @Test func weekResultsDoNotLeakNullSentinel() {
        let r = firstResult("next week")
        #expect(r != nil)
        #expect(r?.start.isCertain(.hour) == false)
        #expect(r?.start.knownValues[.hour] == nil)
        #expect(r?.start.get(.hour) != -1) // never the internal null sentinel
    }

    /// Explicit times must remain certain. "in 5 hours" is a time unit, so its hour is meaningful.
    @Test func explicitTimesStayCertain() {
        #expect(firstResult("at 15:00")?.start.isCertain(.hour) == true)
        #expect(firstResult("monday 9am")?.start.isCertain(.hour) == true)
        #expect(firstResult("in 5 hours")?.start.isCertain(.hour) == true)
    }

    /// Portuguese weekday resolution was off by one (0-based dict vs 1-based Calendar.weekday).
    @Test func portugueseWeekdayIsNotOffByOne() {
        let cal = Calendar.current
        func weekday(_ text: String) -> Int? {
            guard let d = firstResult(text, Chrono.pt.casual)?.start.date else { return nil }
            return cal.component(.weekday, from: d) // 1=Sun … 7=Sat
        }
        #expect(weekday("segunda") == 2) // Monday
        #expect(weekday("sexta") == 6)   // Friday
        #expect(weekday("sábado") == 7)  // Saturday
    }

    /// Japanese hour-only 24h times ("15時", no 分) must parse.
    @Test func japaneseHourOnlyTimeParses() {
        let r = firstResult("15時", Chrono.ja.casual)
        #expect(r?.start.isCertain(.hour) == true)
        #expect(r?.start.get(.hour) == 15)
    }

    /// A bare month → the 1st of that month, forward-dated (not the reference day-of-month).
    @Test func bareMonthIsFirstOfMonthForwardDated() {
        let cal = Calendar.current
        func parsed(_ s: String) -> Date? {
            firstResult(s)?.start.date
        }
        // ref is 2025-06-15. October is future this year → Oct 1, 2025.
        if let d = parsed("october") {
            #expect(cal.component(.day, from: d) == 1)
            #expect(cal.component(.month, from: d) == 10)
            #expect(cal.component(.year, from: d) == 2025)
        } else { #expect(Bool(false)) }
        // June 1 is already past → June 1 of next year.
        if let d = parsed("june") {
            #expect(cal.component(.day, from: d) == 1)
            #expect(cal.component(.month, from: d) == 6)
            #expect(cal.component(.year, from: d) == 2026)
        } else { #expect(Bool(false)) }
    }

    /// Dutch "over N <unit>" (a common future-relative form) must parse.
    @Test func dutchOverPrefixParses() {
        let r = firstResult("over 3 dagen", Chrono.nl.casual)
        #expect(r != nil)
        #expect(r?.start.isCertain(.hour) == false)
        if let d = r?.start.date {
            #expect(Calendar.current.component(.day, from: d) == 18) // Jun 15 + 3
        }
    }
}
