// ENMonthNameParser.swift - Parser for month names
import Foundation

/// Parser for month name expressions like "January", "Feb", etc.
public final class ENMonthNameParser: Parser {
    private static let PATTERN = "(?:in\\s*)?([A-Za-z]+)(\\s*[,-]?\\s*(\\d{1,2})(?:st|nd|rd|th)?)?(?:\\s*(?:to|through|\\-|\\–)\\s*([A-Za-z]+))?(?:\\s*[,-]?\\s*(\\d{1,2})(?:st|nd|rd|th)?)?\\s*(?:,?\\s*(\\d{2,4})(?!\\s*[\\-\\–]\\s*\\d{1,2}))?(?=\\W|$)"
    
    private static let MONTH_NAME_DICTIONARY: [String: Int] = [
        "january": 1, "jan": 1,
        "february": 2, "feb": 2,
        "march": 3, "mar": 3,
        "april": 4, "apr": 4,
        "may": 5,
        "june": 6, "jun": 6,
        "july": 7, "jul": 7,
        "august": 8, "aug": 8,
        "september": 9, "sep": 9, "sept": 9,
        "october": 10, "oct": 10,
        "november": 11, "nov": 11,
        "december": 12, "dec": 12
    ]
    
    /// Returns the regex pattern for this parser
    public func pattern(context: ParsingContext) -> String {
        return ENMonthNameParser.PATTERN
    }
    
    /// Extracts date from month name expressions
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let component = context.createParsingComponents()
        
        // Get the month name
        guard let monthName = match.string(at: 1)?.lowercased(),
              let month = ENMonthNameParser.MONTH_NAME_DICTIONARY[monthName] else {
            return nil
        }
        
        component.assign(.month, value: month)
        
        // Handle day
        if let dayStr = match.string(at: 3), let day = Int(dayStr) {
            if day >= 1 && day <= 31 {
                component.assign(.day, value: day)
            }
        }
        
        // Handle year
        if let yearStr = match.string(at: 6), let year = Int(yearStr) {
            if year < 100 {
                component.assign(.year, value: year + 2000)
            } else {
                component.assign(.year, value: year)
            }
        } else {
            // If no year is specified, use the year from reference date
            // But apply forward/backward adjustment if needed
            let refDate = context.refDate
            let calendar = Calendar.current
            let currentYear = calendar.component(.year, from: refDate)
            let currentMonth = calendar.component(.month, from: refDate)
            
            // If the specified month is earlier than the current month,
            // we likely refer to the next year
            if context.options.forwardDate && month < currentMonth {
                component.imply(.year, value: currentYear + 1)
            } else {
                component.imply(.year, value: currentYear)
            }
        }
        
        // Check for date range (e.g., "January to February")
        if let endMonthName = match.string(at: 4)?.lowercased(),
           let endMonth = ENMonthNameParser.MONTH_NAME_DICTIONARY[endMonthName] {
            // Create an end date component
            let endComponent = context.createParsingComponents()
            endComponent.assign(.month, value: endMonth)
            
            // Check for end day
            if let endDayStr = match.string(at: 5), let endDay = Int(endDayStr) {
                if endDay >= 1 && endDay <= 31 {
                    endComponent.assign(.day, value: endDay)
                }
            }
            
            // If year was specified, apply to end date as well
            if let yearStr = match.string(at: 6), let year = Int(yearStr) {
                if year < 100 {
                    endComponent.assign(.year, value: year + 2000)
                } else {
                    endComponent.assign(.year, value: year)
                }
            } else if let impliedYear = component.get(.year) {
                endComponent.imply(.year, value: impliedYear)
            }
            
            // Create a date range result
            let result = context.createParsingResult(
                index: match.match.range.location,
                text: match.matchedText,
                start: component,
                end: endComponent
            )
            
            result.addTag("ENMonthNameParser")
            return result
        }
        
        component.addTag("ENMonthNameParser")
        return component
    }
}