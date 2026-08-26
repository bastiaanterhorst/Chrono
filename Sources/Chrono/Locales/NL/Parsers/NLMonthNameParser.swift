// NLMonthNameParser.swift - Parser for Dutch month-first and month-only expressions
import Foundation

/// Parser for Dutch month expressions like "juni", "juni 9", and "juni 9 2025".
final class NLMonthNameParser: Parser {
    func pattern(context: ParsingContext) -> String {
        let monthNames = PatternUtils.matchAnyPattern(NLConstants.MONTH_DICTIONARY)
        let prefix = "(?:(?:in|op)\\s+)?"
        let month = "(" + monthNames + ")"
        // (?!:) so the hour of a clock time isn't taken as the day/year (e.g. "juli 14:00" ≠ July 14).
        let day = "(?:\\s+([0-9]{1,2})(?:ste|de|e)?(?!:))?"
        let year = "(?:\\s*[,-]?\\s*([0-9]{2,4})(?!:))?"
        let end = "(?=\\W|$)"
        // Leading `(?<!\w)` prevents matching a month abbreviation as the suffix of a longer word.
        return "(?<!\\w)" + prefix + month + day + year + end
    }

    func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let monthText = match.string(at: 1)?.lowercased(),
              let month = NLConstants.MONTH_DICTIONARY.matchValue(for: monthText) else {
            return nil
        }

        // A month *abbreviation* standing entirely alone is too collision-prone to schedule: "jan"
        // is one of the commonest Dutch first names, so "bellen met jan" booked 1 January. With a
        // day or a year beside it the intent is unambiguous ("15 jan"), and the full name is
        // unambiguous by itself, so only the bare-abbreviation case is refused. Detected by
        // comparison rather than a hard-coded list, which keeps "mei" — three letters, but the
        // whole word — working.
        let isAbbreviation = NLConstants.MONTH_DICTIONARY
            .contains { $0.value == month && $0.key.count > monthText.count }
        if isAbbreviation, match.string(at: 2) == nil, match.string(at: 3) == nil { return nil }

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
