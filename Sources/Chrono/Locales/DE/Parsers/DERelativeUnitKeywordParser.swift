// DERelativeUnitKeywordParser.swift - Parser for expressions like "nächsten Monat"
import Foundation

/// Parser for German relative keyword expressions like "nächsten Monat", "letztes Jahr", and "diese Woche".
public struct DERelativeUnitKeywordParser: Parser {
    public init() {}

    public func pattern(context: ParsingContext) -> String {
        let modifier = "(diese(?:n|m|r|s)?|n[aä]chste(?:n|m|r|s)?|naechste(?:n|m|r|s)?|kommende(?:n|m|r|s)?|letzte(?:n|m|r|s)?|vorige(?:n|m|r|s)?|vorherige(?:n|m|r|s)?)"
        let unit = "(tag|tage|woche|wochen|monat|monate|jahr|jahre)"
        return "(?i)" + modifier + "\\s+" + unit + "(?=\\W|$)"
    }

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let modifierText = match.string(at: 1)?.lowercased(),
              let unitText = match.string(at: 2)?.lowercased() else {
            return nil
        }

        let offset: Int
        if modifierText.hasPrefix("dies") {
            offset = 0
        } else if modifierText.hasPrefix("nächst") || modifierText.hasPrefix("naechst") || modifierText.hasPrefix("kommend") {
            offset = 1
        } else if modifierText.hasPrefix("letzt") || modifierText.hasPrefix("vorig") || modifierText.hasPrefix("vorherig") {
            offset = -1
        } else {
            return nil
        }

        if unitText == "woche" || unitText == "wochen" {
            return extractWeek(context: context, offset: offset)
        }

        let calendarUnit: Calendar.Component
        switch unitText {
        case "tag", "tage":
            calendarUnit = .day
        case "monat", "monate":
            calendarUnit = .month
        case "jahr", "jahre":
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

        component.addTag("DERelativeUnitKeywordParser")
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

        component.addTag("DERelativeUnitKeywordParser")
        return component
    }
}
