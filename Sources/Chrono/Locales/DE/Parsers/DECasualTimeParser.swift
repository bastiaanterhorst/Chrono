// DECasualTimeParser.swift - Parser for casual time references in German
import Foundation

/// Parser for casual time references in German like "mittag", "mitternacht", etc.
public struct DECasualTimeParser: Parser {
    public init() {}
    
    public func pattern(context: ParsingContext) -> String {
        return "(mittags?|mitternacht|morgens?|vormittags?|nachmittags?|abends?|nachts?)(?=\\W|$)"
    }
    
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let lowerText = match.text.lowercased()
        let components = ParsingComponents(reference: context.reference)
        
        if lowerText.starts(with: "mittag") {
            // Noon
            components.assign(.hour, value: 12)
            components.assign(.minute, value: 0)
            components.assign(.second, value: 0)
            
        } else if lowerText.starts(with: "mitternacht") {
            // Midnight
            components.assign(.hour, value: 0)
            components.assign(.minute, value: 0)
            components.assign(.second, value: 0)
            
        } else if lowerText.starts(with: "morgen") {
            // Morning - 8:00 AM
            components.assign(.hour, value: 8)
            components.assign(.minute, value: 0)
            components.assign(.second, value: 0)
            
        } else if lowerText.starts(with: "vormittag") {
            // Before noon - 10:00 AM
            components.assign(.hour, value: 10)
            components.assign(.minute, value: 0)
            components.assign(.second, value: 0)
            
        } else if lowerText.starts(with: "nachmittag") {
            // Afternoon - 3:00 PM
            components.assign(.hour, value: 15)
            components.assign(.minute, value: 0)
            components.assign(.second, value: 0)
            
        } else if lowerText.starts(with: "abend") {
            // Evening - 8:00 PM
            components.assign(.hour, value: 20)
            components.assign(.minute, value: 0)
            components.assign(.second, value: 0)
            
        } else if lowerText.starts(with: "nacht") {
            // Night - 11:00 PM
            components.assign(.hour, value: 23)
            components.assign(.minute, value: 0)
            components.assign(.second, value: 0)
        }
        
        return components
    }
}