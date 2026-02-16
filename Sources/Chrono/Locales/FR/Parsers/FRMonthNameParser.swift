// FRMonthNameParser.swift - Parser for French month-first and month-only expressions
import Foundation

/// Parser for French month expressions like "juin", "juin 9", and "juin 9 2025".
public struct FRMonthNameParser: Parser {
    private static let monthDictionary: [String: Int] = [
        "janvier": 1, "janv": 1, "janv.": 1,
        "février": 2, "fevrier": 2, "févr": 2, "fevr": 2, "févr.": 2, "fevr.": 2,
        "mars": 3,
        "avril": 4, "avr": 4, "avr.": 4,
        "mai": 5,
        "juin": 6,
        "juillet": 7, "juil": 7, "juil.": 7,
        "août": 8, "aout": 8,
        "septembre": 9, "sept": 9, "sept.": 9,
        "octobre": 10, "oct": 10, "oct.": 10,
        "novembre": 11, "nov": 11, "nov.": 11,
        "décembre": 12, "decembre": 12, "déc": 12, "dec": 12, "déc.": 12, "dec.": 12
    ]

    public init() {}

    public func pattern(context: ParsingContext) -> String {
        let months = PatternUtils.matchAnyPattern(FRMonthNameParser.monthDictionary)
        let prefix = "(?:(?:en|le|au)\\s+)?"
        let month = "(" + months + ")"
        let day = "(?:\\s+([0-9]{1,2})(?:er)?)?"
        let year = "(?:\\s*(?:de)?\\s*[,-]?\\s*([0-9]{2,4}))?"
        return "(?i)" + prefix + month + day + year + "(?=\\W|$)"
    }

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let monthText = match.string(at: 1)?.lowercased(),
              let month = FRMonthNameParser.monthDictionary[monthText] else {
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
        component.addTag("FRMonthNameParser")
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
