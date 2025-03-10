// ENTimeExpressionParser.swift - Parser for time expressions
import Foundation

/// Parser for time expressions like "6:30pm", "4:00", etc.
public final class ENTimeExpressionParser: Parser {
    /// The pattern to match time expressions
    public func pattern(context: ParsingContext) -> String {
        return "(?:(?:at|from|after|before|on|,|\\s)\\s*)" +
               "(noon|midnight|\\d{1,2}(?:[:.]\\d{2})?(?:\\s*[ap][m|\\.])?)(?=\\W|$)"
    }
    
    /// Extracts time components from a time expression
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let component = context.createParsingComponents()
        
        guard let text = match.string(at: 1)?.lowercased() else { return nil }
        
        // Special cases: noon and midnight
        if text == "noon" {
            component.assign(.hour, value: 12)
            component.assign(.minute, value: 0)
            component.assign(.second, value: 0)
            component.assign(.meridiem, value: Meridiem.pm.rawValue)
            return component
        }
        
        if text == "midnight" {
            component.assign(.hour, value: 0)
            component.assign(.minute, value: 0)
            component.assign(.second, value: 0)
            component.assign(.meridiem, value: Meridiem.am.rawValue)
            return component
        }
        
        // Handle time like "6:30pm"
        if text.contains(":") {
            let parts = text.split(separator: ":")
            guard parts.count == 2 else { return nil }
            
            // Get hour
            guard let hourStr = parts.first,
                  let hour = Int(hourStr) else { return nil }
            component.assign(.hour, value: hour)
            
            // Get minute with possible meridiem
            let minutePart = parts[1]
            if minutePart.lowercased().contains("p") {
                // PM case
                let minuteStr = minutePart.lowercased()
                    .replacingOccurrences(of: "pm", with: "")
                    .replacingOccurrences(of: "p.", with: "")
                    .replacingOccurrences(of: "p", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                guard let minute = Int(minuteStr) else { return nil }
                component.assign(.minute, value: minute)
                component.assign(.meridiem, value: Meridiem.pm.rawValue)
                
                // Convert to 24-hour time
                if hour != 12 {
                    component.assign(.hour, value: hour + 12)
                }
            } else if minutePart.lowercased().contains("a") {
                // AM case
                let minuteStr = minutePart.lowercased()
                    .replacingOccurrences(of: "am", with: "")
                    .replacingOccurrences(of: "a.", with: "")
                    .replacingOccurrences(of: "a", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                guard let minute = Int(minuteStr) else { return nil }
                component.assign(.minute, value: minute)
                component.assign(.meridiem, value: Meridiem.am.rawValue)
                
                // Convert to 24-hour time
                if hour == 12 {
                    component.assign(.hour, value: 0)
                }
            } else {
                // No meridiem specified
                guard let minute = Int(minutePart) else { return nil }
                component.assign(.minute, value: minute)
                component.imply(.meridiem, value: Meridiem.am.rawValue)
            }
        } else {
            // Simple hour only
            // Check if there's AM/PM
            if text.lowercased().contains("pm") || text.lowercased().contains("p.") || text.lowercased().hasSuffix("p") {
                let hourStr = text.lowercased()
                    .replacingOccurrences(of: "pm", with: "")
                    .replacingOccurrences(of: "p.", with: "")
                    .replacingOccurrences(of: "p", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                guard let hour = Int(hourStr) else { return nil }
                component.assign(.meridiem, value: Meridiem.pm.rawValue)
                
                // Convert to 24-hour time
                if hour != 12 {
                    component.assign(.hour, value: hour + 12)
                } else {
                    component.assign(.hour, value: hour)
                }
                component.imply(.minute, value: 0)
            } else if text.lowercased().contains("am") || text.lowercased().contains("a.") || text.lowercased().hasSuffix("a") {
                let hourStr = text.lowercased()
                    .replacingOccurrences(of: "am", with: "")
                    .replacingOccurrences(of: "a.", with: "")
                    .replacingOccurrences(of: "a", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                guard let hour = Int(hourStr) else { return nil }
                component.assign(.meridiem, value: Meridiem.am.rawValue)
                
                // Convert to 24-hour time
                if hour == 12 {
                    component.assign(.hour, value: 0)
                } else {
                    component.assign(.hour, value: hour)
                }
                component.imply(.minute, value: 0)
            } else {
                // No meridiem specified
                guard let hour = Int(text) else { return nil }
                component.assign(.hour, value: hour)
                component.imply(.minute, value: 0)
                component.imply(.meridiem, value: hour < 12 ? Meridiem.am.rawValue : Meridiem.pm.rawValue)
            }
        }
        
        component.imply(.second, value: 0)
        component.addTag("ENTimeExpressionParser")
        return component
    }
}