// JAWeekdayParser.swift - Parser for weekday mentions in Japanese (e.g. 木曜日, 月曜)
import Foundation

/// Parser for Japanese weekday expressions like 月曜日 / 火曜 / 木曜日.
/// (Japanese has no word boundaries, so the disambiguating 曜 is required — a bare 月/火/… is not
/// treated as a weekday.) Resolves to the next occurrence of that weekday; combined with a relative
/// week (来週木曜日) by `CombineRelativeWeekAndWeekdayRefiner`.
public struct JAWeekdayParser: Parser {
    public init() {}

    // Sun=0 … Sat=6, matching the other locales' weekday numbering.
    private static let weekdays: [String: Int] = [
        "日": 0, "月": 1, "火": 2, "水": 3, "木": 4, "金": 5, "土": 6
    ]

    public func pattern(context: ParsingContext) -> String {
        return "(日|月|火|水|木|金|土)曜日?"
    }

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let key = match.string(at: 1), let weekday = JAWeekdayParser.weekdays[key] else {
            return nil
        }

        let component = context.createParsingComponents()
        let calendar = Calendar.current
        let refDate = context.refDate

        let currentWeekday = calendar.component(.weekday, from: refDate) - 1 // Sun=0 … Sat=6
        var daysToAdd = weekday - currentWeekday
        if daysToAdd < 0 { daysToAdd += 7 } // next occurrence (today stays today)

        let targetDate = calendar.date(byAdding: .day, value: daysToAdd, to: refDate) ?? refDate
        let dc = calendar.dateComponents([.year, .month, .day], from: targetDate)
        if let y = dc.year { component.assign(.year, value: y) }
        if let m = dc.month { component.assign(.month, value: m) }
        if let d = dc.day { component.assign(.day, value: d) }
        component.assign(.weekday, value: weekday)
        component.imply(.hour, value: 12)
        component.addTag("JAWeekdayParser")
        return component
    }
}
