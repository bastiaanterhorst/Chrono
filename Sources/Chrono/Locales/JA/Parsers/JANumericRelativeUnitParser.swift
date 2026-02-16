// JANumericRelativeUnitParser.swift - Parser for expressions like "2日後"
import Foundation

/// Parser for Japanese numeric relative unit expressions like "2日後", "2ヶ月前", and "あと3日".
public struct JANumericRelativeUnitParser: Parser {
    public init() {}

    public func pattern(context: ParsingContext) -> String {
        let direct = "(\\d+)\\s*(日|週間|か月|ヶ月|ヵ月|月|年)\\s*(後|前)"
        let after = "あと\\s*(\\d+)\\s*(日|週間|か月|ヶ月|ヵ月|月|年)"
        return "(?:" + direct + "|" + after + ")"
    }

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let directNumberText = match.string(at: 1)
        let directUnitText = match.string(at: 2)
        let directionText = match.string(at: 3)

        let afterNumberText = match.string(at: 4)
        let afterUnitText = match.string(at: 5)

        let numberText = directNumberText ?? afterNumberText
        let unitText = directUnitText ?? afterUnitText

        guard let numberText, let value = Int(numberText), let unitText else {
            return nil
        }

        let offset: Int
        if directionText == "前" {
            offset = -value
        } else {
            offset = value
        }

        if unitText == "週間" {
            return extractWeek(context: context, offset: offset)
        }

        let calendarUnit: Calendar.Component
        switch unitText {
        case "日":
            calendarUnit = .day
        case "か月", "ヶ月", "ヵ月", "月":
            calendarUnit = .month
        case "年":
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

        component.addTag("JANumericRelativeUnitParser")
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

        component.addTag("JANumericRelativeUnitParser")
        return component
    }
}
