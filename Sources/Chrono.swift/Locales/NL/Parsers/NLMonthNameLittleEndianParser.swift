// NLMonthNameLittleEndianParser.swift - Parser for dates with month names in Dutch (DD MMMM YYYY)
import Foundation

/// Parser for dates with month names in Dutch like "15 januari 2025"
final class NLMonthNameLittleEndianParser: Parser {
    func pattern(context: ParsingContext) -> String {
        let monthNames = PatternUtils.matchAnyPattern(NLConstants.MONTH_DICTIONARY)
        
        let prefix = "(?:(?:op|vanaf)\\s*)?\\s*"
        let dayWithSuffix = "([0-9]{1,2})(?:ste|de|e)?\\s*"
        let month = "(" + monthNames + ")"
        let yearOptional = "(?:(?:-|/|,|\\s*(?:van|in)?\\s*)(\\s*[0-9]{1,4})(?![^\\s]\\d))?"
        let end = "(?=\\W|$)"
        
        return prefix + "(?:(?:de|den)\\s+)?" + dayWithSuffix + 
               "(?:tot|\\-|\\–|\\s*(?:van)?\\s*(?:de|het)?\\s+)?\\s*" + 
               month + yearOptional + end
    }
    
    func extract(context: ParsingContext, match: TextMatch) -> Any? {
        // Day number
        guard let dayStr = match.string(at: 1), let day = Int(dayStr) else {
            return nil
        }
        
        // Validate day
        if day < 1 || day > 31 {
            return nil
        }
        
        // Get month
        guard let monthName = match.string(at: 2)?.lowercased(),
              let month = NLConstants.MONTH_DICTIONARY[monthName] else {
            return nil
        }
        
        // Year (optional)
        var year = Calendar.current.component(.year, from: context.refDate)
        if let yearStr = match.string(at: 3)?.trimmingCharacters(in: .whitespaces), let parsedYear = Int(yearStr) {
            if parsedYear < 100 {
                // For two-digit years, interpret as 20XX for values < 50, 19XX for values >= 50
                if parsedYear < 50 {
                    year = 2000 + parsedYear
                } else {
                    year = 1900 + parsedYear
                }
            } else {
                year = parsedYear
            }
        }
        
        // Build result
        var result: [Component: Int] = [:]
        result[.day] = day
        result[.month] = month
        result[.year] = year
        
        // Forward date adjustment if needed
        if context.options.forwardDate && month < Calendar.current.component(.month, from: context.refDate) {
            result[.year] = year + 1
        }
        
        return result
    }
}