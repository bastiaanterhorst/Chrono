// FRSpecificTimeExpressionParser.swift - Parser for specific French time expressions
import Foundation

/// Parser for specific French time expressions like "à 8h du matin", "7h du soir", etc.
public final class FRSpecificTimeExpressionParser: Parser {
    /// The pattern to match specific French time expressions
    public func pattern(context: ParsingContext) -> String {
        return "(?:(?:\\à|a|vers|de)?\\s*)" +
               "(\\d{1,2})(?:h|:)(?:(\\d{1,2})(?:min|\\'|m)?)?" +
               "(?:\\s*(?:du|dans|le|la|l'|au|en|à|a)\\s*(matin|matinée|après-midi|apres-midi|soir|soirée|nuit))?"
    }
    
    /// Extracts time components from a specific French time expression
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let component = context.createParsingComponents()
        
        // Get hour, minute, and period from match
        guard let hourText = match.string(at: 1), !hourText.isEmpty,
              let hour = Int(hourText) else {
            return nil
        }
        
        // Parse minute
        let minute: Int
        if let minuteText = match.string(at: 2), !minuteText.isEmpty,
           let parsedMinute = Int(minuteText) {
            minute = parsedMinute
        } else {
            minute = 0
        }
        
        // Determine meridiem based on time period
        let period = match.string(at: 3)?.lowercased()
        
        var meridiem = hour >= 12 ? Meridiem.pm : Meridiem.am
        var adjustedHour = hour
        
        if let period = period {
            switch period {
            case "matin", "matinée":
                // Morning
                meridiem = .am
                if hour == 12 {
                    adjustedHour = 0
                }
            case "après-midi", "apres-midi":
                // Afternoon
                meridiem = .pm
                if hour < 12 {
                    adjustedHour = hour + 12
                }
            case "soir", "soirée", "nuit":
                // Evening/night
                meridiem = .pm
                if hour < 12 {
                    adjustedHour = hour + 12
                }
            default:
                break
            }
        }
        
        component.assign(.hour, value: adjustedHour)
        component.assign(.minute, value: minute)
        component.assign(.second, value: 0)
        component.assign(.meridiem, value: meridiem.rawValue)
        
        component.addTag("FRSpecificTimeExpressionParser")
        return component
    }
}