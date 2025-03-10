// NLCasualTimeParser.swift - Parser for casual time references in Dutch
import Foundation

/// Parser for casual time expressions in Dutch like "vannacht", "vanavond", etc.
final class NLCasualTimeParser: Parser {
    func pattern(context: ParsingContext) -> String {
        return "(?:(?:\\s|^)(middernacht|vannacht|'s nachts|vanavond|'s avonds|'s morgens|'s ochtends|'s middags)(?=\\W|$))"
    }
    
    func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let text = match.string(at: 1)?.lowercased()
        
        var hour = 0
        var minute = 0
        var meridiem: Meridiem?
        
        switch text {
        case "middernacht":
            // 12 AM
            hour = 0
            minute = 0
            meridiem = .am
        case "vannacht", "'s nachts":
            // Night, assume 0:00
            hour = 0
            minute = 0
            meridiem = .am
        case "vanavond", "'s avonds":
            // Evening, assume 8 PM
            hour = 20
            minute = 0
            meridiem = .pm
        case "'s morgens", "'s ochtends":
            // Morning, assume 8 AM
            hour = 8
            minute = 0
            meridiem = .am
        case "'s middags":
            // Afternoon, assume 2 PM
            hour = 14
            minute = 0
            meridiem = .pm
        default:
            return nil
        }
        
        var result: [Component: Int] = [:]
        result[.hour] = hour
        result[.minute] = minute
        
        if let meridiemValue = meridiem {
            result[.meridiem] = meridiemValue.rawValue
        }
        
        return result
    }
}