// FRRelativeUnitKeywordParser.swift - Parser for expressions like "mois prochain"
import Foundation

/// Parser for French relative keyword expressions like "mois prochain", "an dernier", and "cette semaine".
public struct FRRelativeUnitKeywordParser: Parser {
    public init() {}

    public func pattern(context: ParsingContext) -> String {
        let modifier = "(ce|cet|cette|prochain|prochaine|suivant|suivante|dernier|derni[eè]re|pr[eé]c[eé]dent|pr[eé]c[eé]dente|pass[eé]e?)"
        let unit = "(jour|jours|semaine|semaines|mois|an|ans|ann[eé]e|ann[eé]es)"
        let modifierFirst = modifier + "\\s+" + unit
        let unitFirst = unit + "\\s+" + modifier
        return "(?i)(?:" + modifierFirst + "|" + unitFirst + ")(?=\\W|$)"
    }

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let modifierText = (match.string(at: 1) ?? match.string(at: 4) ?? "").lowercased()
        let unitText = (match.string(at: 2) ?? match.string(at: 3) ?? "").lowercased()

        guard !modifierText.isEmpty, !unitText.isEmpty else {
            return nil
        }

        let offset: Int
        if modifierText == "ce" || modifierText == "cet" || modifierText == "cette" {
            offset = 0
        } else if modifierText.hasPrefix("prochain") || modifierText.hasPrefix("suivant") {
            offset = 1
        } else if modifierText.hasPrefix("dernier") || modifierText.hasPrefix("derni") || modifierText.hasPrefix("précéd") || modifierText.hasPrefix("preced") || modifierText.hasPrefix("pass") {
            offset = -1
        } else {
            return nil
        }

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

        component.addTag("FRRelativeUnitKeywordParser")
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

        component.addTag("FRRelativeUnitKeywordParser")
        return component
    }
}
