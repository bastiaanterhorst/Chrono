// ESCasualTimeParser.swift - Parser for casual time expressions in Spanish
import Foundation

/// Parser for casual time expressions in Spanish (e.g., "medianoche", "mediodía")
public final class ESCasualTimeParser: Parser {
    public func pattern(context: ParsingContext) -> String {
        return "(?:(?:al?|en\\s+la|a\\s+la|por\\s+la)?\\s*)(medianoche|mediodía|media\\s*noche|medio\\s*día|mediodia|medio\\s*dia)(?=\\W|$)"
    }
    
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let text = match.string(at: 1)?.lowercased() else { return nil }
        let components = ParsingComponents(reference: context.reference)
        
        switch text {
        case "medianoche", "media noche":
            components.assign(.hour, value: 0)
            components.assign(.minute, value: 0)
            components.assign(.second, value: 0)
            components.assign(.meridiem, value: Meridiem.am.rawValue)
            return components
            
        case "mediodía", "medio día", "mediodia", "medio dia":
            components.assign(.hour, value: 12)
            components.assign(.minute, value: 0)
            components.assign(.second, value: 0)
            components.assign(.meridiem, value: Meridiem.pm.rawValue)
            return components
            
        default:
            return nil
        }
    }
}