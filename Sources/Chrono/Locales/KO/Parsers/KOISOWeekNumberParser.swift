// KOISOWeekNumberParser.swift - 35주차 / 제35주.
import Foundation

/// Korean week numbers: 35주차 and 제35주, optionally with a year (2026년 35주차).
///
/// The week is numbered by this parse's own convention, so the number typed is the number stored.
public struct KOISOWeekNumberParser: Parser {
    public init() {}

    public func pattern(context: ParsingContext) -> String {
        let s = KOConstants.optionalSpace
        // 차 is what makes 35주 a week *number* rather than a count of weeks: without it, "2주 후"
        // (in two weeks) would be read as week 2. The 제35주 form carries its marker in front instead.
        let ordinal = "제" + s + "(\\d{1,2})" + s + "주(?![일말차])"
        let counter = "(\\d{1,2})" + s + "주차"
        return "(?:(\\d{4})년" + s + ")?(?:" + ordinal + "|" + counter + ")"
    }

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let weekStr = match.string(at: 2) ?? match.string(at: 3),
              let week = Int(weekStr), (1...53).contains(week) else {
            return nil
        }
        let calendar = context.weekCalendar
        let statedYear = match.string(at: 1).flatMap { Int($0) }
        let weekYear = statedYear ?? calendar.component(.yearForWeekOfYear, from: context.refDate)

        let components = context.createParsingComponents()
        components.assign(.isoWeek, value: week)
        if let statedYear {
            components.assign(.isoWeekYear, value: statedYear)
        } else {
            components.imply(.isoWeekYear, value: weekYear)
        }
        components.assignNull(.hour)

        var dc = DateComponents()
        dc.weekOfYear = week
        dc.yearForWeekOfYear = weekYear
        dc.weekday = calendar.firstWeekday
        dc.hour = 12
        if let start = calendar.date(from: dc) {
            let v = calendar.dateComponents([.year, .month, .day], from: start)
            if let y = v.year { components.assign(.year, value: y) }
            if let m = v.month { components.assign(.month, value: m) }
            if let d = v.day { components.assign(.day, value: d) }
        }
        components.addTag("KOISOWeekNumberParser")
        return components
    }
}
