// ENSlashDateFormatParser.swift - Parser for date in slash format (MM/DD/YYYY)
import Foundation

/// Parser for slash date formats (e.g., 12/31/2021, 12/31, 12-31-2021)
public final class ENSlashDateFormatParser: Parser {
    private static let PATTERN = "(?:on\\s*)?(0?[1-9]|1[0-2])[\\/-](0?[1-9]|[12][0-9]|3[01])(?:[\\/-]([0-9]{2,4}))?(?=\\W|$)"
    
    /// Returns the regex pattern for this parser
    public func pattern(context: ParsingContext) -> String {
        return ENSlashDateFormatParser.PATTERN
    }
    
    /// Extracts date from slash format expressions
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let component = context.createParsingComponents()
        let calendar = Calendar.current
        
        // In the US, the date format is usually MM/DD/YYYY
        let monthStr = match.string(at: 1)
        let dayStr = match.string(at: 2)
        
        guard let monthStr = monthStr, let month = Int(monthStr),
              let dayStr = dayStr, let day = Int(dayStr) else {
            return nil
        }
        
        // Validate month and day values
        if month < 1 || month > 12 {
            // Maybe it's actually day/month format
            if day >= 1 && day <= 12 && month >= 1 && month <= 31 {
                // If the "month" value is out of range, but the "day" value is in month range,
                // we can assume the format is DD/MM/YYYY
                component.assign(.day, value: month)
                component.assign(.month, value: day)
            } else {
                return nil
            }
        } else if day < 1 || day > 31 {
            return nil
        } else {
            // Standard MM/DD/YYYY format
            component.assign(.day, value: day)
            component.assign(.month, value: month)
        }
        
        // Year handling
        if let yearStr = match.string(at: 3), let year = Int(yearStr) {
            if year < 100 {
                component.assign(.year, value: year + 2000)
            } else {
                component.assign(.year, value: year)
            }
        } else {
            // If year is not specified, use the current year
            let currentYear = calendar.component(.year, from: context.refDate)
            component.imply(.year, value: currentYear)
            
            // Apply forward date adjustment if needed
            if context.options.forwardDate {
                let refDate = context.refDate
                let currentMonth = calendar.component(.month, from: refDate)
                let currentDay = calendar.component(.day, from: refDate)
                
                let componentMonth = component.get(.month) ?? 0
                let componentDay = component.get(.day) ?? 0
                
                // If the specified date is earlier than the current date,
                // move to the next year
                if componentMonth < currentMonth ||
                   (componentMonth == currentMonth && componentDay < currentDay) {
                    component.assign(.year, value: currentYear + 1)
                }
            }
        }
        
        component.addTag("ENSlashDateFormatParser")
        return component
    }
}