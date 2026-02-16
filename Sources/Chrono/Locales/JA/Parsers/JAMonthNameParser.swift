// JAMonthNameParser.swift - Parser for Japanese month-only expressions
import Foundation

/// Parser for Japanese month-only expressions like "6月" and "2025年6月".
public struct JAMonthNameParser: Parser {
    public init() {}

    public func pattern(context: ParsingContext) -> String {
        let explicitYear = "(?:([0-9０-９]{2,4})年\\s*)?"
        let month = "([0-9０-９]{1,2})月"
        let noDaySuffix = "(?!\\s*[0-9０-９]{1,2}日)"
        return explicitYear + month + noDaySuffix
    }

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let monthText = match.string(at: 2),
              let month = normalizeNumber(monthText),
              (1...12).contains(month) else {
            return nil
        }

        let component = context.createParsingComponents()
        component.assign(.month, value: month)

        if let yearText = match.string(at: 1), let explicitYear = normalizeNumber(yearText) {
            component.assign(.year, value: normalizeYear(explicitYear))
        } else {
            let inferredYear = inferYear(context: context, month: month)
            component.imply(.year, value: inferredYear)
        }

        component.addTag("JAMonthNameParser")
        return component
    }

    private func inferYear(context: ParsingContext, month: Int) -> Int {
        let calendar = Calendar.current
        let reference = context.refDate
        let currentYear = calendar.component(.year, from: reference)
        let currentMonth = calendar.component(.month, from: reference)

        guard context.options.forwardDate else {
            return currentYear
        }

        return month < currentMonth ? currentYear + 1 : currentYear
    }

    private func normalizeYear(_ year: Int) -> Int {
        if year < 100 {
            return year < 50 ? 2000 + year : 1900 + year
        }
        return year
    }

    private func normalizeNumber(_ text: String) -> Int? {
        let normalized = text.map { character -> Character in
            if let index = "０１２３４５６７８９".firstIndex(of: character) {
                let offset = "０１２３４５６７８９".distance(from: "０１２３４５６７８９".startIndex, to: index)
                return "0123456789"[String.Index(utf16Offset: offset, in: "0123456789")]
            }
            return character
        }
        return Int(String(normalized))
    }
}
