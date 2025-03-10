// ENYearMonthDayParser.swift
import Foundation

/// Parser for dates with format YYYY/MM/DD or YYYY-MM-DD
public struct ENYearMonthDayParser: Parser {
    public init() {}
    
    public func pattern(context: ParsingContext) -> String {
        return "(\\W|^)" +
               "([0-9]{4})[\\-\\/\\.]([0-9]{1,2})[\\-\\/\\.]([0-9]{1,2})" +
               "(?=\\W|$)"
    }
    
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        // First group is the year (YYYY)
        guard let yearStr = match.string(at: 2), 
              let year = Int(yearStr),
              year > 0 else {
            return nil
        }
        
        // Second group is the month (MM)
        guard let monthStr = match.string(at: 3), 
              let month = Int(monthStr),
              month >= 1 && month <= 12 else {
            return nil
        }
        
        // Third group is the day (DD)
        guard let dayStr = match.string(at: 4), 
              let day = Int(dayStr),
              day >= 1 && day <= 31 else {
            return nil
        }
        
        let text = match.text
        let result = ParsingComponents(reference: context.reference)
        
        result.assign(.year, value: year)
        result.assign(.month, value: month)
        result.assign(.day, value: day)
        
        return result
    }
}