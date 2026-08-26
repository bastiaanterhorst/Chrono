// JARelativeUnitKeywordParser.swift - Parser for expressions like "来月" and "来年"
import Foundation

/// Parser for Japanese relative keyword unit expressions like "来月", "先月", "今年", and "来年".
public struct JARelativeUnitKeywordParser: Parser {
    public init() {}

    public func pattern(context: ParsingContext) -> String {
        // 度 turns any of the year words into a *fiscal* year — 今年度 is a period label, not a
        // date — and 末 turns them into a period edge, which Chrono deliberately does not read.
        // Without the guard 今年 was cut out of 今年度 and left the 度 stranded in the task name.
        return "(今月|来月|先月|今年|来年|去年|昨年)(?![度末])"
    }

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let text = match.string(at: 1) else {
            return nil
        }

        let calendarUnit: Calendar.Component
        let offset: Int

        switch text {
        case "今月":
            calendarUnit = .month
            offset = 0
        case "来月":
            calendarUnit = .month
            offset = 1
        case "先月":
            calendarUnit = .month
            offset = -1
        case "今年":
            calendarUnit = .year
            offset = 0
        case "来年":
            calendarUnit = .year
            offset = 1
        case "去年", "昨年":
            calendarUnit = .year
            offset = -1
        default:
            return nil
        }

        guard let targetDate = Calendar.current.date(
            byAdding: calendarUnit,
            value: offset,
            to: context.reference.instant
        ) else {
            return nil
        }

        let values = Calendar.current.dateComponents([.year, .month, .day], from: targetDate)
        let component = context.createParsingComponents()

        if let year = values.year {
            component.assign(.year, value: year)
        }
        if let month = values.month {
            component.assign(.month, value: month)
        }
        // A relative MONTH means the 1st of that month (start of the unit), not the reference
        // day-of-month — matching how a relative week anchors to its Monday.
        if calendarUnit == .month {
            component.assign(.day, value: 1)
        } else if let day = values.day {
            component.assign(.day, value: day)
        }

        component.addTag("JARelativeUnitKeywordParser")
        return component
    }
}
