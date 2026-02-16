// NLMonthNameParser.swift - Parser for Dutch month-first and month-only expressions
import Foundation

/// Parser for Dutch month expressions like "juni", "juni 9", and "juni 9 2025".
final class NLMonthNameParser: Parser {
    func pattern(context: ParsingContext) -> String {
        let monthNames = PatternUtils.matchAnyPattern(NLConstants.MONTH_DICTIONARY)
        let prefix = "(?:(?:in|op)\\s+)?"
        let month = "(" + monthNames + ")"
        let day = "(?:\\s+([0-9]{1,2})(?:ste|de|e)?)?"
        let year = "(?:\\s*[,-]?\\s*([0-9]{2,4}))?"
        let end = "(?=\\W|$)"
        return prefix + month + day + year + end
    }

    func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let monthText = match.string(at: 1)?.lowercased(),
              let month = NLConstants.MONTH_DICTIONARY[monthText] else {
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

        component.addTag("NLMonthNameParser")
        return component
    }

    private func resolveYear(context: ParsingContext, month: Int, day: Int?, rawYear: String?) -> Int {
        let reference = context.refDate
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: reference)

        if let rawYear, let parsedYear = Int(rawYear.trimmingCharacters(in: .whitespaces)) {
            if parsedYear < 100 {
                return parsedYear < 50 ? 2000 + parsedYear : 1900 + parsedYear
            }
            return parsedYear
        }

        var candidateYear = currentYear

        if context.options.forwardDate {
            if let day {
                let refMonth = calendar.component(.month, from: reference)
                let refDay = calendar.component(.day, from: reference)
                if month < refMonth || (month == refMonth && day < refDay) {
                    candidateYear += 1
                }
            } else if month < calendar.component(.month, from: reference) {
                candidateYear += 1
            }
        }

        return candidateYear
    }
}
