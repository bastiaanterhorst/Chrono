// DEMonthNameLittleEndianParser.swift - Parser for month names in German
import Foundation

/// Parser for month names in German in format "day-month-year" like "31 Januar 2020" or "10. Mai"
public struct DEMonthNameLittleEndianParser: Parser {
    public init() {}
    
    public func pattern(context: ParsingContext) -> String {
        return "(\\W|^)" +
               "(?:a[nm]\\s*?)?" +
               "([0-9]{1,2})(?:te|\\.)?" +
               "(?:\\s*(?:bis|\\-|\\–|\\s)\\s*([0-9]{1,2})(?:te|\\.)?)?\\s*" +
               "(" + DEConstants.MONTH_DICTIONARY.keys.joined(separator: "|") + ")" +
               "(?:(?:-|\\/)([0-9]{1,2})(?:te|\\.)?)?" +
               "(?:\\s*,?\\s*([0-9]{1,4})(\\s*(?:v\\.\\s*(?:Chr|c)|n\\.\\s*(?:Chr|c))))?" +
               "(?=\\W|$)"
    }
    
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let text = match.text
        let result = ParsingComponents(reference: context.reference)
        
        guard let monthStr = match.string(at: 4)?.lowercased(),
              let month = DEConstants.MONTH_DICTIONARY[monthStr] else {
            return nil
        }
        
        guard let dayStr = match.string(at: 2),
              let day = Int(dayStr),
              day >= 1 && day <= 31 else {
            return nil
        }
        
        result.assign(.day, value: day)
        result.assign(.month, value: month)
        
        // Year
        if let yearStr = match.string(at: 6), let year = Int(yearStr) {
            // Check for era (BC/AD)
            let eraStr = match.string(at: 7)?.lowercased() ?? ""
            if eraStr.contains("v") {
                // BC (Before Christ)
                result.assign(.year, value: -year)
            } else {
                // AD or default
                result.assign(.year, value: year)
            }
        } else {
            // If no explicit year, imply the current year
            let refDate = context.reference.instant
            let calendar = Calendar.current
            let year = calendar.component(.year, from: refDate)
            result.imply(.year, value: year)
        }
        
        // Check for date range
        if let endDayStr = match.string(at: 3), let endDay = Int(endDayStr), endDay >= 1 && endDay <= 31 {
            let endResult = ParsingComponents(reference: context.reference)
            endResult.assign(.day, value: endDay)
            endResult.assign(.month, value: month)
            
            // If there's a year for the start date, use the same for end date
            if result.isCertain(.year), let year = result.get(.year) {
                endResult.assign(.year, value: year)
            } else if let impliedYear = result.get(.year) {
                endResult.imply(.year, value: impliedYear)
            }
            
            return context.createParsingResult(
                index: match.match.range.location,
                text: text,
                start: result,
                end: endResult
            )
        }
        
        return result
    }
}