// NLSlashDateFormatParser.swift - Parser for slash/dot-separated dates in Dutch (DD/MM/YYYY)
import Foundation

/// Parser for slash-separated dates in Dutch (day/month/year)
final class NLSlashDateFormatParser: Parser {
    func pattern(context: ParsingContext) -> String {
        // The leading lookbehind stops the match starting midway through a longer number:
        // without it "123.4" matched from the second digit and became 23 April.
        return "(?<![0-9./-])(?:(?:op)\\s*)?\\s*" +
            "([0-9]{1,2})" +
            "[\\/\\.\\-]" +
            "([0-9]{1,2})" +
            "(?:" +
            "[\\/\\.\\-]" +
            "([0-9]{4}|[0-9]{2})" +
            ")?" +
            "(?=\\W|$)"
    }
    
    func extract(context: ParsingContext, match: TextMatch) -> Any? {
        // Check if this is a valid date format
        guard let dayStr = match.string(at: 1),
              let monthStr = match.string(at: 2) else {
            return nil
        }
        
        // The two leading numbers are read in the reader's regional order — day-first for the
        // Dutch-speaking territories, month-first for someone whose system says so — falling back
        // to the other order when the stated one is impossible ("22/4" is not month 22).
        guard let first = Int(dayStr), let second = Int(monthStr) else { return nil }
        let order = context.options.numericDateOrder ?? .dayFirst
        guard let (day, month) = NumericDateInterpreter.dayAndMonth(first: first, second: second,
                                                                    order: order) else {
            return nil
        }

        let component = context.createParsingComponents()
        component.assign(.day, value: day)
        component.assign(.month, value: month)

        // Check if a specific year was provided
        if let yearStr = match.string(at: 3), let parsedYear = Int(yearStr) {
            if parsedYear < 100 {
                // For two-digit years, interpret as 20XX for values < 50, 19XX for values >= 50
                component.assign(.year, value: parsedYear < 50 ? 2000 + parsedYear : 1900 + parsedYear)
            } else {
                component.assign(.year, value: parsedYear)
            }
        } else {
            // No year stated, so only *infer* the reference year — which lets `ForwardDateRefiner`
            // roll a date that has already gone by into the next one. Doing it here instead used
            // to compare months alone, so "20/8" typed on 26 August stayed six days in the past
            // (and, being assigned, the inferred year looked stated and no refiner could fix it).
            component.imply(.year, value: Calendar.current.component(.year, from: context.refDate))
        }

        return component
    }
}