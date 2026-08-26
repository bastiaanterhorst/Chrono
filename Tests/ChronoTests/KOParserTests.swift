import Testing
import Foundation
@testable import Chrono

/// Korean date parsing. Sonto ships in Korean, but Chrono had no `ko` locale, so Korean input fell
/// through to English and nothing at all was recognised — not even 내일.
///
/// Reference throughout: Wed 26 August 2026, 10:00.
@Suite("KO — Korean dates")
struct KOParserTests {
    private let ref = ParsingReference(instant: createDate(2026, 8, 26, 10))
    private let opts = ParsingOptions(forwardDate: true)

    private func ymd(_ text: String) -> (Int, Int, Int)? {
        guard let r = KO.casual.parse(text: text, referenceDate: ref, options: opts).first else { return nil }
        let c = Calendar.current.dateComponents([.year, .month, .day], from: r.start.date)
        return (c.year!, c.month!, c.day!)
    }

    private func expect(_ text: String, _ y: Int, _ m: Int, _ d: Int,
                        _ loc: SourceLocation = #_sourceLocation) {
        // Bare and with a trailing task name: real input is "내일 우유 사기", not a lone date.
        for t in [text, "\(text) 확인하기"] {
            let got = ymd(t)
            #expect(got != nil, "\(t): no result", sourceLocation: loc)
            if let got {
                #expect(got == (y, m, d), "\(t) → \(got), expected (\(y), \(m), \(d))", sourceLocation: loc)
            }
        }
    }

    @Test func dayWords() {
        expect("오늘", 2026, 8, 26)
        expect("내일", 2026, 8, 27)
        expect("모레", 2026, 8, 28)
        expect("글피", 2026, 8, 29)
        expect("어제", 2026, 8, 25)
        expect("어저께", 2026, 8, 25)
        expect("그제", 2026, 8, 24)
        expect("그저께", 2026, 8, 24)
    }

    /// A bare weekday means the next one still to come; today's own weekday means today.
    @Test func weekdays() {
        expect("수요일", 2026, 8, 26)   // the reference day itself
        expect("금요일", 2026, 8, 28)
        expect("월요일", 2026, 8, 31)   // Monday has passed, so next week's
        expect("일요일", 2026, 8, 30)
    }

    /// The spacing is optional in Korean, and both forms must agree.
    @Test func weekdaysWithinANamedWeek() {
        expect("다음 주 금요일", 2026, 9, 4)
        expect("다음주 금요일", 2026, 9, 4)
        expect("이번 주 금요일", 2026, 8, 28)
        expect("지난주 금요일", 2026, 8, 21)
    }

    @Test func calendarDates() {
        expect("12월 25일", 2026, 12, 25)
        expect("10월 22일", 2026, 10, 22)
        expect("2026년 4월 22일", 2026, 4, 22)   // a stated year is honoured, past or not
        expect("4월 22일", 2027, 4, 22)          // April has gone by, so next April
        expect("2026.4.22", 2026, 4, 22)
    }

    @Test func countedRelativeExpressions() {
        expect("3일 후", 2026, 8, 29)
        expect("2주 후", 2026, 9, 9)
        expect("2주 전", 2026, 8, 12)
        expect("6개월 후", 2027, 2, 26)
        expect("3일 뒤", 2026, 8, 29)
    }

    @Test func namedRelativeExpressions() {
        expect("다음 달", 2026, 9, 1)
        expect("다음달", 2026, 9, 1)
        expect("내년", 2027, 8, 26)
        expect("작년", 2025, 8, 26)
        expect("다음 주말", 2026, 9, 5)
        expect("이번 주말", 2026, 8, 29)
    }

    /// "In two weeks" must not be read as week 2 — 차 is what makes a number a week *number*.
    @Test func weekNumbersAreDistinctFromWeekCounts() {
        let week = KO.casual.parse(text: "35주차", referenceDate: ref, options: opts).first
        #expect(week?.start.isCertain(.isoWeek) == true)
        #expect(week?.start.get(.isoWeek) == 35)

        let ordinal = KO.casual.parse(text: "제35주", referenceDate: ref, options: opts).first
        #expect(ordinal?.start.get(.isoWeek) == 35)

        let count = KO.casual.parse(text: "2주 후", referenceDate: ref, options: opts).first
        #expect(count?.start.isCertain(.isoWeek) != true, "\"2주 후\" is a count of weeks, not week 2")
    }

    @Test func clockTimes() {
        func hourMinute(_ text: String) -> (Int, Int)? {
            guard let r = KO.casual.parse(text: text, referenceDate: ref, options: opts)
                .first(where: { $0.start.isCertain(.hour) }) else { return nil }
            return (r.start.get(.hour) ?? -1, r.start.get(.minute) ?? -1)
        }
        #expect(hourMinute("9시")! == (9, 0))
        #expect(hourMinute("오전 9시")! == (9, 0))
        #expect(hourMinute("오후 3시")! == (15, 0))
        #expect(hourMinute("9시 30분")! == (9, 30))
        #expect(hourMinute("저녁 7시")! == (19, 0))
        #expect(hourMinute("15:30")! == (15, 30))
    }

    /// A day period states a meridiem, which is what marks the time as one the user really gave.
    @Test func aDayPeriodMakesTheMeridiemCertain() {
        let r = KO.casual.parse(text: "오후 3시", referenceDate: ref, options: opts).first
        #expect(r?.start.isCertain(.meridiem) == true)
    }

    /// Ordinary Korean that merely contains a date syllable must not become a date.
    @Test func nonDatesStayNonDates() {
        for text in ["3장 읽기", "사과 2개 사기", "일본 여행 계획", "생일 선물"] {
            let dates = KO.casual.parse(text: text, referenceDate: ref, options: opts)
                .filter { $0.start.isCertain(.day) || $0.start.isCertain(.month) }
            #expect(dates.isEmpty, "'\(text)' should not yield a date, got \(dates.map(\.text))")
        }
    }
}
