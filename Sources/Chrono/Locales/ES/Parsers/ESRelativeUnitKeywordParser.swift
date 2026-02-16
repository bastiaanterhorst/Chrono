// ESRelativeUnitKeywordParser.swift - Parser for expressions like "próximo mes"
import Foundation

/// Parser for Spanish relative keyword expressions like "próximo mes", "año pasado", and "esta semana".
public struct ESRelativeUnitKeywordParser: Parser {
    public init() {}

    public func pattern(context: ParsingContext) -> String {
        let modifier = "(este|esta|pr[oó]ximo|pr[oó]xima|pasado|pasada|anterior)"
        let unit = "(d[ií]a|d[ií]as|semana|semanas|mes|meses|a[nñ]o|a[nñ]os)"
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
        if modifierText == "este" || modifierText == "esta" {
            offset = 0
        } else if modifierText.contains("próximo") || modifierText.contains("proximo") {
            offset = 1
        } else if modifierText == "pasado" || modifierText == "pasada" || modifierText == "anterior" {
            offset = -1
        } else {
            return nil
        }

        if unitText.contains("semana") {
            return extractWeek(context: context, offset: offset)
        }

        let calendarUnit: Calendar.Component
        if unitText.contains("día") || unitText.contains("dia") {
            calendarUnit = .day
        } else if unitText.contains("mes") {
            calendarUnit = .month
        } else if unitText.contains("año") || unitText.contains("ano") {
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

        component.addTag("ESRelativeUnitKeywordParser")
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

        component.addTag("ESRelativeUnitKeywordParser")
        return component
    }
}
