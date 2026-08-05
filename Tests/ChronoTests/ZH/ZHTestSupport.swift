// ZHTestSupport.swift - Shared helpers for the Chinese locale test suites.
import Testing
import Foundation
@testable import Chrono

/// The canonical reference instant for the ZH suites: **Tuesday 2026-02-17 12:00**.
///
/// Deliberately the same instant the cross-locale suites use, and deliberately mid-week and
/// mid-day so that "this week" / "next week" and "3 o'clock" (already past) are unambiguous.
/// ISO weeks around it:
///   last = wk 7 (Mon 02-09 … Sun 02-15) · this = wk 8 (Mon 02-16 … Sun 02-22) · next = wk 9 (Mon 02-23 … Sun 03-01)
/// Computed rather than stored: `ParsingReference` is not `Sendable`, so a global `let` would be
/// rejected under strict concurrency.
var zhRef: ParsingReference { ParsingReference(instant: createDate(2026, 2, 17, 12, 0)) }

/// Parse with the Chinese casual configuration.
func zhParse(_ text: String, forward: Bool = false) -> [ParsedResult] {
    Chrono.zh.casual.parse(text: text, referenceDate: zhRef,
                           options: ParsingOptions(forwardDate: forward))
}

/// The (year, month, day) of the first result, or nil when nothing parsed.
func zhYMD(_ text: String, forward: Bool = false) -> (Int, Int, Int)? {
    guard let result = zhParse(text, forward: forward).first else { return nil }
    let c = Calendar.current.dateComponents([.year, .month, .day], from: result.start.date)
    guard let y = c.year, let m = c.month, let d = c.day else { return nil }
    return (y, m, d)
}

/// Asserts the first result falls on the given calendar day.
func zhExpectDay(_ text: String, _ y: Int, _ m: Int, _ d: Int,
                 forward: Bool = false, _ comment: String = "") {
    let got = zhYMD(text, forward: forward)
    #expect(got != nil, "\(comment)「\(text)」produced no result")
    if let (gy, gm, gd) = got {
        #expect((gy, gm, gd) == (y, m, d),
                "\(comment)「\(text)」→ \(gy)-\(gm)-\(gd), expected \(y)-\(m)-\(d)")
    }
}

/// Asserts the first result carries the given clock components.
func zhExpectTime(_ text: String, hour: Int, minute: Int = 0, _ comment: String = "") {
    let results = zhParse(text)
    #expect(!results.isEmpty, "\(comment)「\(text)」produced no result")
    guard let r = results.first else { return }
    #expect(r.start.get(.hour) == hour,
            "\(comment)「\(text)」hour → \(String(describing: r.start.get(.hour))), expected \(hour)")
    #expect(r.start.get(.minute) == minute,
            "\(comment)「\(text)」minute → \(String(describing: r.start.get(.minute))), expected \(minute)")
}

/// Asserts the first result is the given ISO week of the given ISO week-year.
func zhExpectWeek(_ text: String, week: Int, year: Int = 2026, _ comment: String = "") {
    let results = zhParse(text)
    #expect(!results.isEmpty, "\(comment)「\(text)」produced no result")
    guard let r = results.first else { return }
    #expect(r.start.get(.isoWeek) == week,
            "\(comment)「\(text)」week → \(String(describing: r.start.get(.isoWeek))), expected \(week)")
    #expect(r.start.get(.isoWeekYear) == year,
            "\(comment)「\(text)」week-year → \(String(describing: r.start.get(.isoWeekYear))), expected \(year)")
}

/// Asserts the text produces no result at all — the "must not parse" discipline.
func zhExpectNothing(_ text: String, _ comment: String) {
    let results = zhParse(text)
    #expect(results.isEmpty,
            "\(comment): 「\(text)」should not parse, got \(results.map { "'\($0.text)'" })")
}

/// Asserts the text produces at least one result — the counterpart to `zhExpectNothing`.
func zhExpectSomething(_ text: String, _ comment: String) {
    #expect(!zhParse(text).isEmpty, "\(comment): 「\(text)」should parse")
}
