import Testing
import Foundation
@testable import Chrono

/// Cross-locale date+time hardening. Reference 2026-06-21.
/// - A clock time's hour must not be grabbed as the month's day ("2 juli 14:00" is July 2, not 14).
/// - A bare duration token ("30m"/"30min") must not parse as a time-of-day.
/// - "<date> 30m <time>" must keep date and time as SEPARATE results (so the host can pill each and
///   the duration in between), never merge across the duration.
@Suite("Date+time hardening — all locales")
struct DateTimeHardeningTests {
    private let ref = ParsingReference(instant: createDate(2026, 6, 21))
    private let opts = ParsingOptions(forwardDate: true)

    private func firstDay(_ text: String, _ c: Chrono) -> Int? {
        guard let r = c.parse(text: text, referenceDate: ref, options: opts).first else { return nil }
        return Calendar.current.dateComponents([.day], from: r.start.date).day
    }

    /// "2 <month> 14:00" → July 2 (the "14" of the clock time is not taken as the day).
    @Test func clockTimeHourIsNotTakenAsDay() {
        #expect(firstDay("2 juli 14:00", NL.casual) == 2)
        #expect(firstDay("2. juli 14:00", DE.casual) == 2)
        #expect(firstDay("2 juillet 14:00", FR.casual) == 2)
        #expect(firstDay("2 de julio 14:00", ES.casual) == 2)
        #expect(firstDay("2 de julho 14:00", PT.casual) == 2)
        #expect(firstDay("2 jul 2pm", EN.casual) == 2)
    }

    /// A bare duration is not a time-of-day (German previously read "30m" as 3:00).
    @Test func bareDurationIsNotATime() {
        for t in ["30m", "30min", "90m", "45m"] {
            let rs = DE.casual.parse(text: t, referenceDate: ref, options: opts)
            #expect(rs.allSatisfy { !$0.start.isCertain(.hour) }, "DE '\(t)' must not parse as a time: \(rs.map { $0.text })")
        }
    }

    /// "<date> 30m <time>" keeps date and time separate (no merge across the duration), in every
    /// locale whose clock time Chrono recognizes.
    @Test func dateAndTimeStaySeparateAcrossADuration() {
        let cases: [(Chrono, String)] = [
            (EN.casual, "2 jul 30m 2pm"), (NL.casual, "2 juli 30m 14:00"),
            (DE.casual, "2. juli 30m 14:00"), (FR.casual, "2 juillet 30m 14:00"),
            (ES.casual, "2 de julio 30m 14:00"), (PT.casual, "2 de julho 30m 14:00"),
        ]
        for (c, text) in cases {
            let rs = c.parse(text: text, referenceDate: ref, options: opts)
            let hasDayOnly = rs.contains { $0.start.isCertain(.day) && !$0.start.isCertain(.hour) }
            let hasTime = rs.contains { $0.start.isCertain(.hour) && !$0.start.isCertain(.day) }
            #expect(hasDayOnly && hasTime, "'\(text)' should yield separate date + time, got \(rs.map { "\($0.text)" })")
        }
    }
}
