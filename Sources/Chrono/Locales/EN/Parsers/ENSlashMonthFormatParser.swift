// ENSlashMonthFormatParser.swift
import Foundation

/// Parser for dates with a slash between MM/DD/YYYY format (American style)
public struct ENSlashMonthFormatParser: Parser {
    public init() {}
    
    public func pattern(context: ParsingContext) -> String {
        return "(\\W|^)" +
               "(?:" +
               "(?:on\\s*?)?" +
               "(?:(\\d{1,2})[\\/\\.\\-](\\d{1,2}))" +
               "(?:[\\/\\.\\-](\\d{4}|\\d{2}))?" +
               "(?=\\W|$)" +
               ")"
    }
    
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        // Numeric date. Which number is the month follows the reader's region — English is written
        // month-first in the United States and day-first almost everywhere else — so the order is
        // taken from the options, defaulting to the American convention for this language.
        guard let firstStr = match.string(at: 2), let first = Int(firstStr),
              let secondStr = match.string(at: 3), let second = Int(secondStr) else {
            return nil
        }
        let order = context.options.numericDateOrder ?? .monthFirst
        guard let (day, month) = NumericDateInterpreter.dayAndMonth(first: first, second: second,
                                                                    order: order) else {
            return nil
        }

        let result = ParsingComponents(reference: context.reference)
        result.assign(.month, value: month)
        result.assign(.day, value: day)
        
        // Third group is the year (optional)
        if let yearStr = match.string(at: 4), 
           let year = Int(yearStr) {
            if year < 100 {
                // Handle 2-digit years (50-99 are 1900s, 00-49 are 2000s)
                result.assign(.year, value: year + (year >= 50 ? 1900 : 2000))
            } else {
                result.assign(.year, value: year)
            }
        } else {
            // If no year is provided, use the reference year
            let referenceDate = context.reference.instant
            let referenceYear = Calendar.current.component(.year, from: referenceDate)
            result.imply(.year, value: referenceYear)
        }
        
        return result
    }
}