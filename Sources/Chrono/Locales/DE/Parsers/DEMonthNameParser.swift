// DEMonthNameParser.swift - Parser for German month-first and month-only expressions
import Foundation

/// Parser for German month expressions like "Juni", "Juni 9", and "Juni 9 2025".
public struct DEMonthNameParser: Parser {
    public init() {}

    public func pattern(context: ParsingContext) -> String {
        let months = PatternUtils.matchAnyPattern(DEConstants.MONTH_DICTIONARY)
        let prefix = "(?:(?:im|in|am|ab)\\s+)?"
        let month = "(" + months + ")"
        let day = "(?:\\s+([0-9]{1,2})(?:\\.|te|ten)?)?"
        let year = "(?:\\s*[,-]?\\s*([0-9]{2,4}))?"
        return "(?i)" + prefix + month + day + year + "(?=\\W|$)"
    }

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let monthText = match.string(at: 1)?.lowercased(),
              let month = DEConstants.MONTH_DICTIONARY[monthText] else {
            return nil
        }

        let component = context.createParsingComponents()
        component.assign(.month, value: month)

        let day: Int?
        if let dayText = match.string(at: 2), let parsedDay = Int(dayText), (1...31).contains(parsedDay) {
            day = parsedDay
            component.assign(.day, value: parsedDay)
        } else {
            day = nil
        }

        let year = resolveYear(context: context, month: month, day: day, rawYear: match.string(at: 3))
        component.imply(.year, value: year)
        component.addTag("DEMonthNameParser")
        return component
    }

    private func resolveYear(context: ParsingContext, month: Int, day: Int?, rawYear: String?) -> Int {
        let calendar = Calendar.current
        let reference = context.refDate
        let currentYear = calendar.component(.year, from: reference)

        if let rawYear, let parsedYear = Int(rawYear.trimmingCharacters(in: .whitespaces)) {
            if parsedYear < 100 {
                return parsedYear < 50 ? 2000 + parsedYear : 1900 + parsedYear
            }
            return parsedYear
        }

        guard context.options.forwardDate else {
            return currentYear
        }

        var candidateYear = currentYear
        let refMonth = calendar.component(.month, from: reference)
        let refDay = calendar.component(.day, from: reference)

        if let day {
            if month < refMonth || (month == refMonth && day < refDay) {
                candidateYear += 1
            }
        } else if month < refMonth {
            candidateYear += 1
        }

        return candidateYear
    }
}
