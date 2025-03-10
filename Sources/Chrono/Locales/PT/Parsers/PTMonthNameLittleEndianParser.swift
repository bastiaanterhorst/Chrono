// PTMonthNameLittleEndianParser.swift - Parser for date formats with month names in Portuguese
import Foundation

/// Parser for Portuguese date expressions in little-endian format (day, month, year)
/// like "13 de janeiro de 2012", "14 de fevereiro", etc.
public final class PTMonthNameLittleEndianParser: Parser {
    /// Returns the pattern for matching Portuguese dates with month names
    public func pattern(context: ParsingContext) -> String {
        let monthNames = PTConstants.MONTH_DICTIONARY.keys.joined(separator: "|")
        
        return "(?:em\\s*)?([0-9]{1,2})(?:º|°|\\.)?" +
              "(?:\\s*(?:de|\\/)\\s*)" +
              "(" + monthNames + ")" +
              "(?:\\s*(?:de|\\/)\\s*([0-9]{1,4}(?![^\\s]\\d)))?(?=\\W|$)"
    }
    
    /// Extracts date components from matched text
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let dayText = match.string(at: 1), 
              let monthText = match.string(at: 2)?.lowercased() else { 
            return nil 
        }
        
        // Day component
        guard let day = Int(dayText), day >= 1 && day <= 31 else { 
            return nil
        }
        
        // Month component
        guard let month = PTConstants.MONTH_DICTIONARY[monthText] else {
            return nil
        }
        
        // Create parsing components
        let component = context.createParsingComponents()
        component.assign(.day, value: day)
        component.assign(.month, value: month)
        
        // Year component (optional)
        if let yearText = match.string(at: 3) {
            let year = PTConstants.parseYear(yearText)
            component.assign(.year, value: year)
        } else {
            // Infer year from reference date
            let refDate = context.refDate
            let calendar = Calendar.current
            let year = calendar.component(.year, from: refDate)
            
            // Basic handling of past/future dates based on current date
            let currentMonth = calendar.component(.month, from: refDate)
            let currentDay = calendar.component(.day, from: refDate)
            
            // Check if the specified date is earlier than the reference date
            if month < currentMonth || (month == currentMonth && day < currentDay) {
                // If the date is earlier in the year, it might refer to next year
                if context.options.forwardDate {
                    component.imply(.year, value: year + 1)
                } else {
                    component.imply(.year, value: year)
                }
            } else {
                // If the date is later in the year, it likely refers to the current year
                component.imply(.year, value: year)
            }
        }
        
        component.addTag("PTMonthNameLittleEndianParser")
        return component
    }
}