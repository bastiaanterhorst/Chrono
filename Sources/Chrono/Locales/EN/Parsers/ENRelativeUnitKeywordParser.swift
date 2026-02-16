// ENRelativeUnitKeywordParser.swift - Parser for expressions like "next month"
import Foundation

/// Parser for relative unit keyword expressions like "next month", "last year", and "this week".
public final class ENRelativeUnitKeywordParser: Parser {
    private static let PATTERN =
        "(?i)(this|next|last|previous|past|coming)\\s+" +
        "(day|week|month|year)s?(?=\\W|$)"

    public func pattern(context: ParsingContext) -> String {
        return ENRelativeUnitKeywordParser.PATTERN
    }

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let modifierText = match.string(at: 1)?.lowercased(),
              let unitText = match.string(at: 2)?.lowercased() else {
            return nil
        }

        let offset: Int
        switch modifierText {
        case "this":
            offset = 0
        case "next", "coming":
            offset = 1
        case "last", "previous", "past":
            offset = -1
        default:
            return nil
        }

        if unitText == "week" {
            return extractWeek(context: context, offset: offset)
        }

        let calendarUnit: Calendar.Component
        switch unitText {
        case "day":
            calendarUnit = .day
        case "month":
            calendarUnit = .month
        case "year":
            calendarUnit = .year
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

        component.addTag("ENRelativeUnitKeywordParser")
        return component
    }

    private func extractWeek(context: ParsingContext, offset: Int) -> ParsingComponents? {
        var isoCalendar = Calendar(identifier: .iso8601)
        isoCalendar.firstWeekday = 2

        guard let targetDate = isoCalendar.date(
            byAdding: .weekOfYear,
            value: offset,
            to: context.reference.instant
        ) else {
            return nil
        }

        let isoWeek = isoCalendar.component(.weekOfYear, from: targetDate)
        let isoWeekYear = isoCalendar.component(.yearForWeekOfYear, from: targetDate)

        let component = context.createParsingComponents()
        component.assign(.isoWeek, value: isoWeek)
        component.assign(.isoWeekYear, value: isoWeekYear)
        component.assignNull(.hour)

        var weekStartComponents = DateComponents()
        weekStartComponents.weekOfYear = isoWeek
        weekStartComponents.yearForWeekOfYear = isoWeekYear
        weekStartComponents.weekday = 2

        if let weekStart = isoCalendar.date(from: weekStartComponents) {
            let values = isoCalendar.dateComponents([.year, .month, .day], from: weekStart)
            if let year = values.year {
                component.assign(.year, value: year)
            }
            if let month = values.month {
                component.assign(.month, value: month)
            }
            if let day = values.day {
                component.assign(.day, value: day)
            }
        }

        component.addTag("ENRelativeUnitKeywordParser")
        return component
    }
}
