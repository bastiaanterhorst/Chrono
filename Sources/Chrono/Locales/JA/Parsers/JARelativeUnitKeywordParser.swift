// JARelativeUnitKeywordParser.swift - Parser for expressions like "来月" and "来年"
import Foundation

/// Parser for Japanese relative keyword unit expressions like "来月", "先月", "今年", and "来年".
public struct JARelativeUnitKeywordParser: Parser {
    public init() {}

    public func pattern(context: ParsingContext) -> String {
        return "(今月|来月|先月|今年|来年|去年|昨年)"
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
        if let day = values.day {
            component.assign(.day, value: day)
        }

        component.addTag("JARelativeUnitKeywordParser")
        return component
    }
}
