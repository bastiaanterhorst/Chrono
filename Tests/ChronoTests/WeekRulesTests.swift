import Testing
import Foundation
@testable import Chrono

/// Week numbering is not universal. ISO 8601 runs Monday–Sunday and gives week 1 to the first week
/// with four days in the new year; the United States starts weeks on Sunday and gives week 1 to
/// whichever week holds 1 January. The same day can sit in week 35 under one and week 36 under the
/// other, and near the turn of the year *every* week differs by one.
///
/// So a host whose users choose their own first day of the week has to say which convention it
/// counts in, and Chrono has to honour it everywhere a week number becomes a date or the other way
/// round. Otherwise the number typed and the number stored are different weeks.
@Suite("Week rules — host convention is honoured")
struct WeekRulesTests {
    private let wed = createDate(2026, 8, 26, 10)   // Wed 26 Aug 2026

    private let iso = WeekRules.iso                                              // Mon-first, 4-day
    private let us  = WeekRules(firstWeekday: 1, minimumDaysInFirstWeek: 1)      // Sun-first
    private let sat = WeekRules(firstWeekday: 7, minimumDaysInFirstWeek: 1)      // Sat-first

    private func parse(_ text: String, _ rules: WeekRules, ref: Date) -> Date? {
        Chrono.casual.parse(text: text, referenceDate: ParsingReference(instant: ref),
                            options: ParsingOptions(forwardDate: true, weekRules: rules))
            .first?.start.date
    }

    /// The heart of it: whatever week the user names, reading the number back with the same rules
    /// must give that number again. Round-tripping through ISO instead shifted nearly every week by
    /// one for a Sunday-first host.
    @Test func aWeekNumberRoundTripsUnderItsOwnRules() {
        for rules in [iso, us, sat] {
            let calendar = rules.calendar
            for week in 1...52 {
                guard let date = parse("review w\(week)", rules, ref: wed) else {
                    Issue.record("w\(week) did not parse under \(rules)"); continue
                }
                let readBack = calendar.component(.weekOfYear, from: date)
                #expect(readBack == week,
                        "w\(week) under firstWeekday \(rules.firstWeekday) read back as w\(readBack)")
            }
        }
    }

    /// The conventions really do disagree — otherwise the test above would prove nothing.
    @Test func theConventionsDisagreeOnRealDates() {
        let isoDate = parse("review w1", iso, ref: wed)
        let usDate = parse("review w1", us, ref: wed)
        #expect(isoDate != nil && usDate != nil)
        #expect(isoDate != usDate, "ISO and US week 1 must land on different days")
        // Read each other's number off the other's date to show the off-by-one that used to ship.
        if let isoDate {
            #expect(us.calendar.component(.weekOfYear, from: isoDate) == 2,
                    "ISO week 1's first day sits in US week 2 — the shift this fixes")
        }
    }

    /// The week starts on the host's first day, not always Monday.
    @Test func theWeekStartsOnTheHostsFirstDay() {
        for rules in [iso, us, sat] {
            guard let date = parse("review w20", rules, ref: wed) else {
                Issue.record("w20 did not parse"); continue
            }
            let startedOn = Calendar.current.component(.weekday, from: date)
            #expect(startedOn == rules.firstWeekday,
                    "w20 under firstWeekday \(rules.firstWeekday) started on weekday \(startedOn)")
        }
    }

    /// Forward-dating asks whether *the host's* week has gone by. On Sunday 30 August the ISO week
    /// 35 (Mon 24 – Sun 30) is still running, while the Sunday-first week that held 23–29 August
    /// has just ended — so the same words, on the same day, resolve to different years.
    @Test func pastnessIsJudgedByTheHostsWeek() {
        let sunday = createDate(2026, 8, 30, 10)

        let isoDate = parse("review w35", iso, ref: sunday)
        #expect(isoDate != nil)
        if let isoDate {
            #expect(iso.calendar.component(.yearForWeekOfYear, from: isoDate) == 2026,
                    "ISO week 35 still holds 30 August, so it is not past")
        }

        let usDate = parse("review w35", us, ref: sunday)
        #expect(usDate != nil)
        if let usDate {
            #expect(us.calendar.component(.weekOfYear, from: usDate) == 35)
            #expect(us.calendar.component(.yearForWeekOfYear, from: usDate) == 2027,
                    "the Sunday-first week 35 ended on 29 August, so it rolls to next year")
        }
    }

    /// Mid-week, both conventions agree the current week is current — the fix must not overshoot.
    @Test func theCurrentWeekHoldsUnderEveryConvention() {
        for rules in [iso, us, sat] {
            guard let date = parse("review w35", rules, ref: wed) else {
                Issue.record("w35 did not parse"); continue
            }
            #expect(rules.calendar.component(.yearForWeekOfYear, from: date) == 2026,
                    "week 35 contains 26 August under firstWeekday \(rules.firstWeekday)")
        }
    }

    /// A relative week phrase lands in the host's week too, not ISO's.
    @Test func relativeWeeksFollowTheHostConvention() {
        for rules in [iso, us, sat] {
            guard let thisWeek = parse("review this week", rules, ref: wed),
                  let nextWeek = parse("review next week", rules, ref: wed) else {
                Issue.record("relative weeks did not parse under \(rules)"); continue
            }
            let calendar = rules.calendar
            #expect(calendar.component(.weekOfYear, from: thisWeek)
                    == calendar.component(.weekOfYear, from: wed),
                    "\"this week\" must be the week holding the reference date")
            let expectedNext = calendar.date(byAdding: .weekOfYear, value: 1, to: wed)!
            #expect(calendar.component(.weekOfYear, from: nextWeek)
                    == calendar.component(.weekOfYear, from: expectedNext),
                    "\"next week\" must be one of the host's weeks on")
        }
    }

    /// Defaulting to ISO keeps every existing caller unchanged.
    @Test func theDefaultIsIso() {
        #expect(ParsingOptions().weekRules == .iso)
        #expect(WeekRules(Calendar(identifier: .iso8601)) == .iso)
        let a = parse("review w10", iso, ref: wed)
        let b = Chrono.casual.parse(text: "review w10", referenceDate: ParsingReference(instant: wed),
                                    options: ParsingOptions(forwardDate: true)).first?.start.date
        #expect(a == b)
    }
}
