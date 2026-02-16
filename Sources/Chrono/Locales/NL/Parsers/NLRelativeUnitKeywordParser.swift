// NLRelativeUnitKeywordParser.swift - Parser for expressions like "volgende maand"
import Foundation

/// Parser for Dutch relative keyword expressions like "volgende maand" and "volgend jaar".
final class NLRelativeUnitKeywordParser: Parser {
    func pattern(context: ParsingContext) -> String {
        let modifier = "(volgende|volgend|komende|komend|vorige|vorig|deze|dit)"
        let unit = "(dag|dagen|week|weken|maand|maanden|jaar|jaren)"
        return "(?i)" + modifier + "\\s+" + unit + "(?=\\W|$)"
    }

    func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let modifierText = match.string(at: 1)?.lowercased(),
              let unitText = match.string(at: 2)?.lowercased() else {
            return nil
        }

        let offset: Int
        switch modifierText {
        case "deze", "dit":
            offset = 0
        case "volgende", "volgend", "komende", "komend":
            offset = 1
        case "vorige", "vorig":
            offset = -1
        default:
            return nil
        }

        if unitText == "week" || unitText == "weken" {
            return extractWeek(context: context, offset: offset)
        }

        let calendarUnit: Calendar.Component
        switch unitText {
        case "dag", "dagen":
            calendarUnit = .day
        case "maand", "maanden":
            calendarUnit = .month
        case "jaar", "jaren":
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

        component.addTag("NLRelativeUnitKeywordParser")
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

        component.addTag("NLRelativeUnitKeywordParser")
        return component
    }
}
