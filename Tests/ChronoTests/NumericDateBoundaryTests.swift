import Testing
import Foundation
@testable import Chrono

/// A numeric date must be recognised as a whole or not at all. It must never be found *inside* a
/// longer number, which produced dates nobody typed: "22.4" was rejected as month 22, retried one
/// digit along, and came back as 4 February; "31.12" became 12 January; "version 123.4" became a
/// date. Silently wrong, and with a pill on it, so nothing looked amiss.
///
/// Two causes, both fixed: patterns guarding their left edge with `(\W|^)` stopped guarding once
/// the parse loop stepped past a rejected match, because `^` re-anchored to the search range rather
/// than the string; and some patterns had no left guard at all.
@Suite("Numeric dates are matched whole")
struct NumericDateBoundaryTests {
    private let ref = ParsingReference(instant: createDate(2026, 8, 26, 10))
    private let opts = ParsingOptions(forwardDate: true)

    private let all: [(String, Chrono)] = [
        ("EN", EN.casual), ("NL", NL.casual), ("DE", DE.casual), ("FR", FR.casual),
        ("ES", ES.casual), ("PT", PT.casual), ("JA", JA.casual), ("ZH", ZH.casual),
    ]

    /// Nothing may match starting partway through a run of digits, in any locale.
    @Test func aDateIsNeverFoundInsideALongerNumber() {
        let inputs = ["22-4", "22.4", "31.12", "13.5", "99.9", "123.4", "1234.5",
                      "version 123.4", "invoice 1234.5", "buy 22-4"]
        for (label, chrono) in all {
            for text in inputs {
                let ns = text as NSString
                for r in chrono.parse(text: text, referenceDate: ref, options: opts) {
                    // Where does the matched text actually begin?
                    let lead = r.text.count - r.text.drop(while: { $0 == " " }).count
                    let start = r.index + lead
                    guard start > 0 else { continue }
                    let prev = ns.substring(with: NSRange(location: start - 1, length: 1))
                    #expect(!(prev.first?.isNumber ?? false),
                            "[\(label)] '\(text)' matched '\(r.text)' starting mid-number at \(start)")
                }
            }
        }
    }

    /// A day-first numeric date the locale genuinely uses still parses, whole.
    @Test func genuineNumericDatesStillParse() {
        func day(_ text: String, _ chrono: Chrono) -> (Int, Int)? {
            guard let r = chrono.parse(text: text, referenceDate: ref, options: opts)
                .first(where: { $0.start.isCertain(.day) && $0.start.isCertain(.month) }) else { return nil }
            let c = Calendar.current.dateComponents([.month, .day], from: r.start.date)
            return (c.month!, c.day!)
        }
        #expect(day("22/4", NL.casual)! == (4, 22))
        #expect(day("31.12", DE.casual)! == (12, 31))
        #expect(day("22/4", FR.casual)! == (4, 22))
        #expect(day("22/4", ES.casual)! == (4, 22))
        #expect(day("22/4", PT.casual)! == (4, 22))
        #expect(day("4.22", EN.casual)! == (4, 22))   // English is month-first by default
        #expect(day("12/25", EN.casual)! == (12, 25))
    }

    /// When the first number cannot be a month, English reads the pair the only way it can rather
    /// than matching some fragment of it. The point of the boundary fix is that the *whole* token is
    /// considered — not that impossible pairs are silently trimmed until something fits.
    @Test func englishReadsAnImpossibleMonthTheOnlyWayItCan() {
        func ymd(_ text: String) -> (Int, Int)? {
            guard let r = EN.casual.parse(text: text, referenceDate: ref, options: opts)
                .first(where: { $0.start.isCertain(.day) && $0.start.isCertain(.month) }) else { return nil }
            let c = Calendar.current.dateComponents([.month, .day], from: r.start.date)
            return (c.month!, c.day!)
        }
        #expect(ymd("22.4")! == (4, 22))    // not 4 February, as the shifted match used to give
        #expect(ymd("31.12")! == (12, 31))  // not 12 January
        #expect(ymd("13.5")! == (5, 13))
    }
}
