// NLCasualDateParser.swift - Parser for casual date references in Dutch
import Foundation

/// Parser for casual date expressions in Dutch like "vandaag", "morgen", etc.
final class NLCasualDateParser: Parser {
    func pattern(context: ParsingContext) -> String {
        // Define a pattern with a capture group for Dutch casual date expressions
        return "(?:(?:\\s|^)(nu|vandaag|gisteren|eergisteren|morgen|overmorgen|vanavond|vannacht|vanochtend|vanmiddag)(?=\\W|$))"
    }
    
    func extract(context: ParsingContext, match: TextMatch) -> Any? {
        // Extract the matched text from the capture group
        guard let term = match.string(at: 1)?.lowercased() else {
            return nil
        }
        
        var targetDate = context.refDate
        var hour: Int? = nil
        var minute: Int? = nil
        
        switch term {
        case "nu":
            // Use current time
            let components = Calendar.current.dateComponents([.hour, .minute, .second], from: targetDate)
            hour = components.hour
            minute = components.minute
        case "vandaag":
            // Just the date, no time
            break
        case "morgen":
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: targetDate) ?? targetDate
        case "overmorgen":
            targetDate = Calendar.current.date(byAdding: .day, value: 2, to: targetDate) ?? targetDate
        case "gisteren":
            targetDate = Calendar.current.date(byAdding: .day, value: -1, to: targetDate) ?? targetDate
        case "eergisteren":
            targetDate = Calendar.current.date(byAdding: .day, value: -2, to: targetDate) ?? targetDate
        case "vanavond":
            // Evening, usually 19:00
            hour = 19
            minute = 0
        case "vannacht":
            // Night, usually 0:00
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: targetDate) ?? targetDate
            hour = 0
            minute = 0
        case "vanochtend":
            // Morning, usually 8:00
            hour = 8
            minute = 0
        case "vanmiddag":
            // Afternoon, usually 14:00
            hour = 14
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
        
        // Add time components if available
        if let hour = hour {
            result[.hour] = hour
        }
        
        if let minute = minute {
            result[.minute] = minute
        }
        
        return result
    }
}