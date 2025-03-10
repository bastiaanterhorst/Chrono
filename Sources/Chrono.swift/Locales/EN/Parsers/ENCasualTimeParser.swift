// ENCasualTimeParser.swift
import Foundation

/// Parser for casual time expressions in English like "this evening", "tonight", "noon", etc.
public struct ENCasualTimeParser: Parser {
    public init() {}
    
    public func pattern(context: ParsingContext) -> String {
        return "(this)\\s*(morning|afternoon|evening|noon|night|midnight)(?=\\W|$)"
    }
    
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        // This morning => 9am
        // This afternoon => 3pm
        // This evening => 8pm
        // This night => 11pm
        // Noon => 12pm
        // Midnight => 12am
        
        let text = match.text
        let lowerText = text.lowercased()
        
        let components = ParsingComponents(reference: context.reference)
        if lowerText.contains("this morning") {
            components.assign(.hour, value: 9)
            components.assign(.minute, value: 0)
            components.assign(.second, value: 0)
            components.assign(.meridiem, value: Meridiem.am.rawValue)
        } else if lowerText.contains("this afternoon") {
            components.assign(.hour, value: 3)
            components.assign(.minute, value: 0)
            components.assign(.second, value: 0)
            components.assign(.meridiem, value: Meridiem.pm.rawValue)
        } else if lowerText.contains("this evening") {
            components.assign(.hour, value: 8)
            components.assign(.minute, value: 0)
            components.assign(.second, value: 0)
            components.assign(.meridiem, value: Meridiem.pm.rawValue)
        } else if lowerText.contains("this night") {
            components.assign(.hour, value: 11)
            components.assign(.minute, value: 0)
            components.assign(.second, value: 0)
            components.assign(.meridiem, value: Meridiem.pm.rawValue)
        } else if lowerText.contains("noon") {
            components.assign(.hour, value: 12)
            components.assign(.minute, value: 0)
            components.assign(.second, value: 0)
            components.assign(.meridiem, value: Meridiem.pm.rawValue)
        } else if lowerText.contains("midnight") {
            components.assign(.hour, value: 0)
            components.assign(.minute, value: 0)
            components.assign(.second, value: 0)
            components.assign(.meridiem, value: Meridiem.am.rawValue)
        }
        
        return components
    }
}