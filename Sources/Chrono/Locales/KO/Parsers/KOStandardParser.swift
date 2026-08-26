// KOStandardParser.swift - 2026년 4월 22일 / 4월 22일 / 4월 / 22일.
import Foundation

/// Korean calendar dates, written largest unit first: 2026년 4월 22일.
///
/// The year and the day are each optional, so this one parser covers 4월 22일, 2026년 4월, and a
/// bare 4월. A bare day (22일) is handled too, but only where no month stands beside it.
///
/// Two guards earn their place. 월 also ends 월요일, so a month must not be read out of a weekday;
/// and 일 also ends 일요일 and opens counting phrases (3일 후, 이틀 동안), so a bare day yields to
/// anything that would make it part of a longer expression.
public struct KOStandardParser: Parser {
    public init() {}

    public func pattern(context: ParsingContext) -> String {
        let s = KOConstants.optionalSpace
        // Group 1 year, 2 month, 3 day — full or partial, month-anchored.
        let monthAnchored = "(?:(\\d{4})년" + s + ")?(\\d{1,2})월(?!요일)(?:" + s + "(\\d{1,2})일(?!요일))?"
        // Group 4: a bare day of the month, only when nothing makes it a counted duration.
        let bareDay = "(\\d{1,2})일(?!요일)(?!" + s + "(?:후|뒤|전|간|동안|째))"
        return "(?:" + monthAnchored + "|" + bareDay + ")"
    }

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let components = context.createParsingComponents()
        let calendar = Calendar.current

        if let monthStr = match.string(at: 2), let month = Int(monthStr), (1...12).contains(month) {
            components.assign(.month, value: month)

            if let dayStr = match.string(at: 3), let day = Int(dayStr), (1...31).contains(day) {
                components.assign(.day, value: day)
            }

            if let yearStr = match.string(at: 1), let year = Int(yearStr) {
                components.assign(.year, value: year)
            } else {
                components.imply(.year, value: calendar.component(.year, from: context.refDate))
            }
            components.addTag("KOStandardParser")
            return components
        }

        if let dayStr = match.string(at: 4), let day = Int(dayStr), (1...31).contains(day) {
            components.assign(.day, value: day)
            components.imply(.month, value: calendar.component(.month, from: context.refDate))
            components.imply(.year, value: calendar.component(.year, from: context.refDate))
            components.addTag("KOStandardParser")
            return components
        }

        return nil
    }
}
