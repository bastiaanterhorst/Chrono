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
        // MM/DD/YYYY format (US style)
        
        let text = match.text
        
        // First group should be the first number (month)
        guard let monthStr = match.string(at: 2), 
              let month = Int(monthStr),
              month >= 1 && month <= 12 else {
            return nil
        }
        
        // Second group should be the second number (day)
        guard let dayStr = match.string(at: 3), 
              let day = Int(dayStr),
              day >= 1 && day <= 31 else {
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