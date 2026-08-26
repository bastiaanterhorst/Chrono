// KOWeekdayParser.swift - 월요일 … 일요일, with 이번 주 / 다음 주 / 지난주.
import Foundation

/// Korean weekdays, optionally qualified by 이번 주 (this week), 다음 주 (next) or 지난주 (last).
///
/// A bare weekday means the next one still to come, and — as in every other locale — naming today's
/// own weekday means today. 다음 주 월요일 is next week's Monday even when today is Monday, which is
/// the distinction the bare form must not blur.
public struct KOWeekdayParser: Parser {
    public init() {}

    public func pattern(context: ParsingContext) -> String {
        let modifiers = KOConstants.relativeModifiers.keys.sorted { $0.count > $1.count }
            .joined(separator: "|")
        // (modifier 주)? (weekday)요일
        return "(?:(" + modifiers + ")" + KOConstants.optionalSpace + "주" + KOConstants.optionalSpace + ")?"
             + "([일월화수목금토])요일"
    }

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let syllable = match.string(at: 2), let weekday = KOConstants.weekdays[syllable] else {
            return nil
        }
        let calendar = Calendar.current
        let refWeekday = calendar.component(.weekday, from: context.refDate)
        var diff = weekday - refWeekday

        if let modifier = match.string(at: 1), let offset = KOConstants.relativeModifiers[modifier] {
            // Inside a named week, the weekday is taken relative to that week rather than nudged
            // forward: 지난주 금요일 is behind us on purpose.
            if diff < 0 && offset == 0 { diff += 7 }
            diff += offset * 7
        } else if diff < 0 {
            // Bare weekday: strictly *passed* days move to next week; today stays today.
            diff += 7
        }

        let components = context.createParsingComponents()
        guard components.assignKODay(offsetBy: diff, from: context.refDate) else { return nil }
        components.assign(.weekday, value: weekday - 1)
        components.addTag("KOWeekdayParser")
        return components
    }
}
