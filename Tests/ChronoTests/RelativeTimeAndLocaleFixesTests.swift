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

    /// The bare-month → 1st rule applies across locales (not just English).
    @Test func bareMonthFirstAcrossLocales() {
        let cal = Calendar.current
        func day(_ s: String, _ chrono: Chrono) -> Int? {
            chrono.parse(text: s, referenceDate: ref, options: opts).first.map { cal.component(.day, from: $0.start.date) }
        }
        #expect(day("oktober", Chrono.nl.casual) == 1)
        #expect(day("octobre", Chrono.fr.casual) == 1)
        #expect(day("octubre", Chrono.es.casual) == 1)
        #expect(day("outubro", Chrono.pt.casual) == 1)
        #expect(day("oktober", Chrono.de.casual) == 1)
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

    /// Multi-date strings must come back in stable ascending text order on every parse. Some
    /// refiners reorder results via sets keyed on reference identity, so without the final
    /// re-sort in `parse()` the order was process-dependent — which made last-wins selection in
    /// downstream consumers (SpaceNLI/NLDatePlanner) nondeterministic. Holds across locales.
    @Test func multiDateResultsStayOrderedByIndex() {
        let cases: [(String, Chrono)] = [
            ("water plants tomorrow call dentist friday", Chrono.casual),
            ("review pr next friday and ship monday", Chrono.casual),
            ("morgen bellen en vrijdag mailen", Chrono.nl.casual),
        ]
        for (text, chrono) in cases {
            var serialized = Set<String>()
            for _ in 0..<24 {
                let results = chrono.parse(text: text, referenceDate: ref, options: opts)
                // Output is always sorted ascending by text index.
                #expect(results.map(\.index) == results.map(\.index).sorted())
                serialized.insert(results.map { "\($0.index):\($0.text)" }.joined(separator: "|"))
            }
            // Identical result sequence on every one of the 24 parses.
            #expect(serialized.count == 1, "nondeterministic results for «\(text)»: \(serialized)")
        }
    }

    // MARK: - Weekday + relative week, greedy matching, crash regressions

    /// "<weekday> next week" resolves to that weekday WITHIN next week — the precise day wins over
    /// the week's default Monday. (ref Sun 2025-06-15 → next week is Mon 06-16 … Sun 06-22.)
    @Test func weekdayWithinRelativeWeekResolvesToThatDay() {
        let cal = Calendar.current
        func dayOf(_ s: String) -> Int? {
            guard let d = firstResult(s)?.start.date else { return nil }
            return cal.component(.day, from: d)
        }
        #expect(dayOf("monday next week") == 16)
        #expect(dayOf("tuesday next week") == 17)
        #expect(dayOf("wednesday next week") == 18)
        #expect(dayOf("thursday next week") == 19)
        #expect(dayOf("friday next week") == 20)
        #expect(dayOf("saturday next week") == 21)
        #expect(dayOf("sunday next week") == 22)
        // The resolved day really is a Thursday (weekday 5: 1=Sun … 7=Sat).
        if let d = firstResult("thursday next week")?.start.date {
            #expect(cal.component(.weekday, from: d) == 5)
        }
    }

    /// "next week thursday" (week-FIRST) merges to that weekday WITHIN next week — computed from the
    /// week anchor, NOT the standalone weekday (which would be the current week's). ref Sun 2025-06-15
    /// → next week Mon 06-16 … Sun 06-22, so Thursday is 06-19.
    @Test func nextWeekWeekdayResolvesToThatDay() {
        let cal = Calendar.current
        func dayOf(_ s: String) -> Int? {
            guard let d = firstResult(s)?.start.date else { return nil }
            return cal.component(.day, from: d)
        }
        #expect(dayOf("next week thursday") == 19)
        #expect(dayOf("next week monday") == 16)
        #expect(dayOf("next week sunday") == 22)
        #expect(firstResult("next week thursday")?.start.isCertain(.isoWeek) == false) // a day, not a week
    }

    /// A relative week with a preceding word ("plan in 2 weeks") still classifies as a week, and a
    /// trailing word ("do it next week") doesn't get swallowed into the week's span.
    @Test func relativeWeekWithSurroundingWordsStaysAWeek() {
        #expect(firstResult("plan in 2 weeks")?.start.isCertain(.isoWeek) == true)
        #expect(firstResult("in 2 weeks")?.start.isCertain(.isoWeek) == true)
        #expect(firstResult("do it next week")?.start.isCertain(.isoWeek) == true)
        // "this weekend" matches as a unit (not "this week" + stray "end").
        #expect(firstResult("offsite this weekend")?.text.lowercased() == "this weekend")
    }

    /// A relative-week ("in N weeks") or ISO-week ("week N") phrase followed by unrelated words must
    /// match ONLY the phrase — the trailing words must not be swallowed into the result span.
    /// Regression for "in 2 weeks xxx" highlighting/stripping "in 2 weeks xxx" as one date token.
    @Test func weekPhrasesDoNotSwallowTrailingWords() {
        func check(_ text: String, _ chrono: Chrono, phrase: String) {
            let results = chrono.parse(text: text, referenceDate: ref, options: opts)
            // No result may swallow the trailing sentinel "xxx".
            for r in results {
                #expect(!r.text.lowercased().contains("xxx"),
                        "«\(text)» → result «\(r.text)» swallowed trailing text")
            }
            // The week phrase itself is matched (trimmed) by some result, and stays a week.
            let weekTexts = results
                .filter { $0.start.isCertain(.isoWeek) }
                .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            #expect(weekTexts.contains(phrase.lowercased()),
                    "«\(text)» → expected a week «\(phrase)», got \(weekTexts)")
        }
        // Relative "in N weeks" forms across every supported locale.
        check("plan in 2 weeks xxx", Chrono.casual, phrase: "in 2 weeks")
        check("doe iets over 2 weken xxx", Chrono.nl.casual, phrase: "over 2 weken")
        check("etwas in 2 wochen xxx", Chrono.de.casual, phrase: "in 2 wochen")
        check("faire dans 2 semaines xxx", Chrono.fr.casual, phrase: "dans 2 semaines")
        check("hacer en 2 semanas xxx", Chrono.es.casual, phrase: "en 2 semanas")
        check("fazer em 2 semanas xxx", Chrono.pt.casual, phrase: "em 2 semanas")
        // ISO "week N" forms (the explicit week-number parser).
        check("meet week 25 xxx", Chrono.casual, phrase: "week 25")
        check("plan week 25 xxx", Chrono.nl.casual, phrase: "week 25")
        check("termin woche 25 xxx", Chrono.de.casual, phrase: "woche 25")
    }

    /// ISO week + explicit 4-digit year must capture the WHOLE year (not just the first 2 digits)
    /// in the matched span — regression where "week 45 van 2023" matched "…van 20" and resolved 2020.
    @Test func isoWeekKeepsFullFourDigitYear() {
        for (text, chrono) in [("week 45 van 2023", Chrono.nl.casual),
                               ("de 45ste week van 2023", Chrono.nl.casual),
                               ("woche 45 von 2023", Chrono.de.casual)] {
            let r = chrono.parse(text: text, referenceDate: ref, options: opts)
                .first { $0.start.isCertain(.isoWeek) }
            #expect(r != nil, "«\(text)» should parse as an ISO week")
            #expect(r?.text.contains("2023") == true, "«\(text)» → span «\(r?.text ?? "")» dropped the year")
            #expect(r?.start.get(.isoWeekYear) == 2023, "«\(text)» resolved week-year \(String(describing: r?.start.get(.isoWeekYear)))")
        }
    }

    /// A bare number is not a date — it must not greedily match (regression: "1" became "today",
    /// and any number up to ~100 turned into today).
    @Test func bareNumbersAreNotDates() {
        for n in ["0", "1", "2", "7", "12", "21", "31", "50", "99", "100", "365"] {
            #expect(firstResult(n) == nil, "bare number «\(n)» should not parse as a date")
        }
    }

    /// Combining a weekday with a relative week in EITHER order (and assorted nearby phrasings) must
    /// never crash — "thursday next week" previously overran a string index in a merge refiner.
    @Test func weekdayAndRelativeWeekNeverCrash() {
        let phrases = [
            "thursday next week", "next week thursday", "tuesday next week", "next week on tuesday",
            "thu next week", "next week fri", "sunday next week", "saturday last week",
            "wednesday this week", "next week wednesday at 3pm", "mon next week tue next week",
            "next week", "last week monday", "this week friday", "friday the week after next",
        ]
        for p in phrases {
            // Parsing must not crash; specific results aren't asserted here.
            _ = Chrono.casual.parse(text: p, referenceDate: ref, options: opts)
        }
    }
}
