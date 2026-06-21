import Testing
import Foundation
@testable import Chrono

/// The shared little-endian day–month(-year) parser must resolve idiomatic "day month" forms to the
/// correct specific day in every locale — and identically with a leading word (prefix invariance),
/// which is where the old per-locale parsers failed (dropping the day, or turning the lone number
/// into a time → reference day-of-month). Reference: 2026-06-21 (July is future → no forward shift).
@Suite("Shared day-month parser — all locales")
struct MonthNameDayParserTests {
    private let ref = ParsingReference(instant: createDate(2026, 6, 21))
    private let opts = ParsingOptions(forwardDate: true)

    private func ymd(_ text: String, _ chrono: Chrono) -> (Int, Int, Int)? {
        guard let r = chrono.parse(text: text, referenceDate: ref, options: opts).first else { return nil }
        let c = Calendar.current.dateComponents([.year, .month, .day], from: r.start.date)
        guard let y = c.year, let m = c.month, let d = c.day else { return nil }
        return (y, m, d)
    }

    private func expect(_ text: String, _ chrono: Chrono, _ y: Int, _ m: Int, _ d: Int) {
        // Bare form and the same form with a leading word must agree (prefix invariance).
        for t in [text, "test \(text)"] {
            let got = ymd(t, chrono)
            #expect(got != nil, "\(t): no result")
            if let g = got { #expect(g == (y, m, d), "\(t) → \(g), expected (\(y), \(m), \(d))") }
        }
    }

    @Test func dayMonthAllLocales() {
        expect("2 jul", EN.casual, 2026, 7, 2)
        expect("2 july", EN.casual, 2026, 7, 2)
        expect("2nd july", EN.casual, 2026, 7, 2)
        expect("15 july", EN.casual, 2026, 7, 15)
        expect("july 2", EN.casual, 2026, 7, 2)        // middle-endian still works
        expect("2 juli", NL.casual, 2026, 7, 2)
        expect("2. juli", DE.casual, 2026, 7, 2)
        expect("2 juli", DE.casual, 2026, 7, 2)
        expect("2 juillet", FR.casual, 2026, 7, 2)
        expect("2 de julio", ES.casual, 2026, 7, 2)
        expect("2 julio", ES.casual, 2026, 7, 2)
        expect("2 de julho", PT.casual, 2026, 7, 2)
        expect("2 julho", PT.casual, 2026, 7, 2)
    }

    @Test func dayMonthYearAllLocales() {
        expect("2 july 2027", EN.casual, 2027, 7, 2)
        expect("2 juli 2027", NL.casual, 2027, 7, 2)
        expect("2. juli 2027", DE.casual, 2027, 7, 2)
        expect("2 juillet 2027", FR.casual, 2027, 7, 2)
        expect("2 de julio 2027", ES.casual, 2027, 7, 2)
        expect("2 de julho 2027", PT.casual, 2027, 7, 2)
    }
}
