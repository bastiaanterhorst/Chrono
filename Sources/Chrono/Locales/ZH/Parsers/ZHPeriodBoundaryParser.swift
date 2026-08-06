// ZHPeriodBoundaryParser.swift - Parser for the edges of a month or year: 月底, 月初, 年底, 年初
import Foundation

/// Parser for the start and end of a month or a year: `月底`, `月初`, `本月底`, `下个月初`, `3月底`,
/// `年底`, `年初`, `明年底`, `今年年初`.
///
/// `月底前完成报告` ("finish the report by the end of the month") is one of the most ordinary things
/// a Chinese speaker puts in a to-do list, and `年底` is how the whole calendar is organised — 年底
/// 总结, 年底考核, 年底前. English has "end of month" too and Chrono reads it in no locale, but that
/// is not a reason to leave Chinese without it: `月底` is a single lexical word, not a preposition
/// phrase, and it is used far more freely than its English gloss.
///
/// Resolution is the obvious one: 底 is the **last day** of the period, 初 is the **first**. So 月底
/// on 2026-02-17 is 2026-02-28, and 年底 is 2026-12-31.
///
/// Deliberately absent: `月中` / `年中` ("mid-month", "mid-year") and the 上旬/中旬/下旬 ten-day
/// divisions. 中 is far too common a character to match after 月 without a noun list this file has
/// no principled way to bound — 一个月中的 is "during a month" — and the 旬 forms are rare in
/// personal task input. Both would be additions rather than corrections.
public struct ZHPeriodBoundaryParser: Parser {
    public init() {}

    /// Capture groups: 1 = month offset prefix, 2 = month boundary · 3 = month number,
    /// 4 = its boundary · 5 = year offset word, 6 = year boundary.
    public func pattern(context: ParsingContext) -> String {
        // 月底 · 本月底 · 这个月初 · 下个月底 · 上月底 · 下下个月底
        let relativeMonth = "(\(ZHConstants.OFFSET_PREFIX))?(?:个|個)?月(底|初)"

        // 3月底 · 十二月初 — a named month rather than a relative one.
        let numberedMonth = "(\(ZHConstants.NUMBER))月(底|初)"

        // 年底 · 明年底 · 明年年底 · 今年初. The optional 年 after the offset word lets the doubled
        // form (明年年底) and the clipped one (明年底) share a single alternative.
        let year = "(?:(明|今|去|後|后|前|来|來)年?)?年(底|初)"

        return relativeMonth + "|" + numberedMonth + "|" + year
    }

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let calendar = Calendar.current

        // A month, relative to the reference.
        if let boundary = match.string(at: 2) {
            let prefix = match.string(at: 1) ?? ""
            let stated = !prefix.isEmpty
            var offset = stated ? (ZHConstants.offset(forPrefix: prefix) ?? 0) : 0
            guard var monthStart = startOfMonth(offsetBy: offset, from: context.refDate, calendar: calendar) else {
                return nil
            }

            // A *bare* 月初 names the start of a month that is usually already behind us — asked on
            // the 11th, it means the next one. A stated prefix is never second-guessed: 这个月初 is
            // this month's, past or not.
            if !stated, hasPassed(monthStart: monthStart, boundary: boundary, context: context, calendar: calendar) {
                offset += 1
                guard let rolled = startOfMonth(offsetBy: offset, from: context.refDate, calendar: calendar) else {
                    return nil
                }
                monthStart = rolled
            }
            return components(context: context, monthStart: monthStart, boundary: boundary, calendar: calendar)
        }

        // A month named by number.
        if let monthText = match.string(at: 3), let boundary = match.string(at: 4) {
            guard let month = ZHConstants.parseNumber(monthText), (1...12).contains(month) else {
                return nil
            }
            let referenceYear = calendar.component(.year, from: context.refDate)
            guard var monthStart = calendar.date(from: DateComponents(year: referenceYear, month: month, day: 1))
            else {
                return nil
            }
            // Same forward rule as everywhere else: a boundary already gone by rolls into next year.
            if hasPassed(monthStart: monthStart, boundary: boundary, context: context, calendar: calendar) {
                guard let rolled = calendar.date(byAdding: .year, value: 1, to: monthStart) else { return nil }
                monthStart = rolled
            }
            return components(context: context, monthStart: monthStart, boundary: boundary, calendar: calendar)
        }

        // A year.
        if let boundary = match.string(at: 6) {
            let word = match.string(at: 5) ?? ""
            let offset: Int
            switch word {
            case "", "今": offset = 0
            case "明", "来", "來": offset = 1
            case "后", "後": offset = 2
            case "去": offset = -1
            case "前": offset = -2
            default: return nil
            }

            var year = calendar.component(.year, from: context.refDate) + offset
            let month = boundary == "底" ? 12 : 1
            let day = boundary == "底" ? 31 : 1

            // As above: a bare 年初 asked in March means next January, but 今年初 is stated and stands.
            if word.isEmpty, context.options.forwardDate,
               let candidate = calendar.date(from: DateComponents(year: year, month: month, day: day)),
               calendar.startOfDay(for: candidate) < calendar.startOfDay(for: context.refDate) {
                year += 1
            }

            let component = context.createParsingComponents()
            component.assign(.year, value: year)
            component.assign(.month, value: month)
            component.assign(.day, value: day)
            component.addTag("ZHPeriodBoundaryParser")
            return component
        }

        return nil
    }

    /// Whether the boundary of `monthStart`'s month is already behind the reference day, and the
    /// caller asked for forward dates.
    private func hasPassed(monthStart: Date, boundary: String, context: ParsingContext, calendar: Calendar) -> Bool {
        guard context.options.forwardDate,
              let day = boundaryDay(of: monthStart, boundary: boundary, calendar: calendar) else {
            return false
        }
        let values = calendar.dateComponents([.year, .month], from: monthStart)
        guard let year = values.year, let month = values.month,
              let candidate = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            return false
        }
        return calendar.startOfDay(for: candidate) < calendar.startOfDay(for: context.refDate)
    }

    /// The day of the month a boundary names: 1 for 初, the month's length for 底.
    private func boundaryDay(of monthStart: Date, boundary: String, calendar: Calendar) -> Int? {
        guard boundary == "底" else { return 1 }
        guard let range = calendar.range(of: .day, in: .month, for: monthStart) else { return nil }
        return range.upperBound - 1
    }

    /// The first instant of the month `offset` months from `refDate`.
    private func startOfMonth(offsetBy offset: Int, from refDate: Date, calendar: Calendar) -> Date? {
        let values = calendar.dateComponents([.year, .month], from: refDate)
        guard let year = values.year, let month = values.month,
              let start = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else {
            return nil
        }
        return calendar.date(byAdding: .month, value: offset, to: start)
    }

    /// Assigns the first or last day of `monthStart`'s month.
    private func components(context: ParsingContext, monthStart: Date, boundary: String,
                            calendar: Calendar) -> ParsingComponents? {
        let values = calendar.dateComponents([.year, .month], from: monthStart)
        guard let year = values.year, let month = values.month else { return nil }

        // 底 is the length of *this* month — 28, 29, 30 or 31, whichever it actually is; 初 is the 1st.
        guard let day = boundaryDay(of: monthStart, boundary: boundary, calendar: calendar) else { return nil }

        let component = context.createParsingComponents()
        component.assign(.year, value: year)
        component.assign(.month, value: month)
        component.assign(.day, value: day)
        component.addTag("ZHPeriodBoundaryParser")
        return component
    }
}
