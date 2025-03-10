// NLSpecialTimeOfDayParser.swift - Parser for Dutch time-of-day expressions
import Foundation

/// Parser specifically for Dutch time-of-day expressions like "vanavond" and "vannacht"
final class NLSpecialTimeOfDayParser: Parser {
    func pattern(context: ParsingContext) -> String {
        // Only match "vanavond" and "vannacht" 
        return "(?:(?:\\s|^)(vanavond|vannacht)(?=\\W|$))"
    }
    
    func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let term = match.string(at: 1)?.lowercased() else {
            return nil
        }
        
        var targetDate = context.refDate
        var hour: Int? = nil
        var minute: Int? = nil
        
        switch term {
        case "vanavond":
            // Evening, usually 19:00
            hour = 19
            minute = 0
        case "vannacht":
            // Night, usually 0:00
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: targetDate) ?? targetDate
            hour = 0
            minute = 0
        default:
            return nil
        }
        
        let components = Calendar.current.dateComponents([.year, .month, .day], from: targetDate)
        
        var result: [Component: Int] = [:]
        
        if let year = components.year {
            result[.year] = year
        }
        
        if let month = components.month {
            result[.month] = month
        }
        
        if let day = components.day {
            result[.day] = day
        }
        
        // Add time components
        if let hour = hour {
            result[.hour] = hour
        }
        
        if let minute = minute {
            result[.minute] = minute
        }
        
        return result
    }
}