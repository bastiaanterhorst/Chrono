// FRCasualTimeParser.swift - Parser for French casual time expressions
import Foundation

/// Parser for French casual time expressions like "midi", "minuit", etc.
public final class FRCasualTimeParser: Parser {
    /// The pattern to match French casual time references
    public func pattern(context: ParsingContext) -> String {
        return "(?:(?:\\a|à|vers|vers l[ae']|pour|dans l[ae'])?\\s*)?(midi|minuit)(?:\\s*(?:pile|précise|exactement|environ|passé de))?"
    }
    
    /// Extracts time components from a French casual time expression
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let component = context.createParsingComponents()
        
        let refDate = context.refDate
        let calendar = Calendar.current
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: refDate)
        
        guard let timeText = match.string(at: 1)?.lowercased() else {
            return nil
        }
        
        // Set date components
        component.assign(.year, value: dayComponents.year ?? 0)
        component.assign(.month, value: dayComponents.month ?? 0)
        component.assign(.day, value: dayComponents.day ?? 0)
        
        // Set time components
        switch timeText {
        case "midi":
            // Noon
            component.assign(.hour, value: 12)
            component.assign(.minute, value: 0)
            component.assign(.second, value: 0)
            component.assign(.meridiem, value: Meridiem.am.rawValue)
            
        case "minuit":
            // Midnight
            component.assign(.hour, value: 0)
            component.assign(.minute, value: 0)
            component.assign(.second, value: 0)
            component.assign(.meridiem, value: Meridiem.am.rawValue)
            
        default:
            return nil
        }
        
        component.addTag("FRCasualTimeParser")
        return component
    }
}