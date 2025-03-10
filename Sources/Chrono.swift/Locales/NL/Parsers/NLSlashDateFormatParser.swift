// NLSlashDateFormatParser.swift - Parser for slash/dot-separated dates in Dutch (DD/MM/YYYY)
import Foundation

/// Parser for slash-separated dates in Dutch (day/month/year)
final class NLSlashDateFormatParser: Parser {
    func pattern(context: ParsingContext) -> String {
        return "(?:(?:op)\\s*)?\\s*" +
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
        
        // In Dutch, the format is typically DD/MM/YYYY
        let day = Int(dayStr) ?? 0
        let month = Int(monthStr) ?? 0
        
        // Validate day and month
        if day < 1 || day > 31 || month < 1 || month > 12 {
            return nil
        }
        
        // Check if a specific year was provided
        var year = Calendar.current.component(.year, from: context.refDate)
        if let yearStr = match.string(at: 3), let parsedYear = Int(yearStr) {
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
        } else if month < Calendar.current.component(.month, from: context.refDate) && context.options.forwardDate {
            // If month is in the past and forwardDate is true, increment year
            year += 1
        }
        
        // Build the result
        var result: [Component: Int] = [:]
        result[.day] = day
        result[.month] = month
        result[.year] = year
        
        return result
    }
}