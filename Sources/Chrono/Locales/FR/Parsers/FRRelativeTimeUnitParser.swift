// FRRelativeTimeUnitParser.swift - Parser for expressions like "dans 2 jours"
import Foundation

/// Parser for French numeric relative unit expressions like "dans 2 jours" and "il y a 3 mois".
public struct FRRelativeTimeUnitParser: Parser {
    public init() {}

    public func pattern(context: ParsingContext) -> String {
        let unit = "(jour|jours|semaine|semaines|mois|an|ans|ann[eé]e|ann[eé]es)"
        let future = "(dans)\\s+(\\d+)\\s+" + unit
        let past = "(il\\s+y\\s+a)\\s+(\\d+)\\s+" + unit
        return "(?i)(?:" + future + "|" + past + ")(?=\\W|$)"
    }

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let isFuture = match.string(at: 1) != nil
        let numberText = match.string(at: 2) ?? match.string(at: 5)
        let unitText = (match.string(at: 3) ?? match.string(at: 6) ?? "").lowercased()

        guard let numberText, let value = Int(numberText), !unitText.isEmpty else {
            return nil
        }

        let offset = isFuture ? value : -value

        if unitText.hasPrefix("semaine") {
            return extractWeek(context: context, offset: offset)
        }

        let calendarUnit: Calendar.Component
        if unitText.hasPrefix("jour") {
            calendarUnit = .day
        } else if unitText.hasPrefix("mois") {
            calendarUnit = .month
        } else if unitText.hasPrefix("an") || unitText.hasPrefix("année") || unitText.hasPrefix("annee") {
            calendarUnit = .year
        } else {
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

        component.addTag("FRRelativeTimeUnitParser")
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

        component.addTag("FRRelativeTimeUnitParser")
        return component
    }
}
