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
        // ZH writes the date big-endian and glues the time straight on, with no separator at all.
        #expect(firstDay("7月2日14:00", ZH.casual) == 2)
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
            // ZH spells the duration out (30分钟) and uses no spaces — the date and the time on
            // either side of it must still come back as two results.
            (ZH.casual, "7月2日30分钟14:00"),
        ]
        for (c, text) in cases {
            let rs = c.parse(text: text, referenceDate: ref, options: opts)
            let hasDayOnly = rs.contains { $0.start.isCertain(.day) && !$0.start.isCertain(.hour) }
            let hasTime = rs.contains { $0.start.isCertain(.hour) && !$0.start.isCertain(.day) }
            #expect(hasDayOnly && hasTime, "'\(text)' should yield separate date + time, got \(rs.map { "\($0.text)" })")
        }
    }

    /// A (relative) date and a time separated by a plain word must stay as separate date + time
    /// results — never collapse into a bogus range that drops the time ("tomorrow bla 3pm" used to
    /// become a "tomorrow → 3pm" range because "tomorrow" contains "to").
    @Test func dateAndSeparatedTimeStaySeparate() {
        let cases: [(Chrono, String)] = [
            (EN.casual, "tomorrow bla 3pm"), (EN.casual, "2 jul bla 3pm"),
            (NL.casual, "morgen bla 15:00"), (DE.casual, "morgen bla 15:00"),
            (FR.casual, "demain bla 15:00"), (PT.casual, "amanhã bla 15:00"),
            // The ZH separator is a word, not a space: 开会 ("have a meeting") sits between the
            // date and the time, so the two must not merge into a 明天 → 下午3点 range.
            (ZH.casual, "明天开会下午3点"), (ZH.casual, "3月15日开会下午3点"),
        ]
        for (c, text) in cases {
            let rs = c.parse(text: text, referenceDate: ref, options: opts)
            #expect(rs.contains { $0.start.isCertain(.hour) }, "'\(text)': the time must survive, got \(rs.map { "\($0.text)" })")
            #expect(rs.allSatisfy { $0.end == nil }, "'\(text)': must not form a range, got \(rs.map { "\($0.text)" })")
        }
    }
}
