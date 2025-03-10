// DESlashDateFormatParser.swift - Parser for date in European slash format (DD/MM/YYYY)
import Foundation

/// Parser for European slash date formats (e.g., 31/12/2021, 31/12, 31-12-2021)
public final class DESlashDateFormatParser: Parser {
    private static let PATTERN = "(?:am\\s*)?(0?[1-9]|[12][0-9]|3[01])[\\/-](0?[1-9]|1[0-2])(?:[\\/-]([0-9]{2,4}))?(?=\\W|$)"
    
    /// Returns the regex pattern for this parser
    public func pattern(context: ParsingContext) -> String {
        return DESlashDateFormatParser.PATTERN
    }
    
    /// Extracts date from slash format expressions (European format: DD/MM/YYYY)
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let component = context.createParsingComponents()
        let calendar = Calendar.current
        
        // In Europe, the date format is DD/MM/YYYY
        let dayStr = match.string(at: 1)
        let monthStr = match.string(at: 2)
        
        guard let dayStr = dayStr, let day = Int(dayStr),
              let monthStr = monthStr, let month = Int(monthStr) else {
            return nil
        }
        
        // Validate day and month values
        if day < 1 || day > 31 {
            return nil
        }
        
        if month < 1 || month > 12 {
            return nil
        }
        
        component.assign(.day, value: day)
        component.assign(.month, value: month)
        
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
        
        component.addTag("DESlashDateFormatParser")
        return component
    }
}