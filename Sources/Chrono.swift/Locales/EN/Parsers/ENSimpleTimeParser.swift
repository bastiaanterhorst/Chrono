// ENSimpleTimeParser.swift - Simple parser for specific time formats
import Foundation

/// A simpler parser for specific time formats like "HH:MMpm"
public final class ENSimpleTimeParser: Parser {
    /// The pattern to match time expressions like "6:30pm"
    public func pattern(context: ParsingContext) -> String {
        return "(\\d{1,2}):(\\d{2})(am|pm)?"
    }
    
    /// Extracts time components from a time expression
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let component = context.createParsingComponents()
        
        guard let hourStr = match.string(at: 1),
              let minuteStr = match.string(at: 2),
              let hour = Int(hourStr),
              let minute = Int(minuteStr) else {
            return nil
        }
        
        let meridiem = match.string(at: 3)?.lowercased()
        
        component.assign(.minute, value: minute)
        
        if let meridiem = meridiem {
            if meridiem == "am" {
                component.assign(.meridiem, value: Meridiem.am.rawValue)
                if hour == 12 {
                    component.assign(.hour, value: 0)
                } else {
                    component.assign(.hour, value: hour)
                }
            } else if meridiem == "pm" {
                component.assign(.meridiem, value: Meridiem.pm.rawValue)
                if hour == 12 {
                    component.assign(.hour, value: 12)
                } else {
                    component.assign(.hour, value: hour + 12)
                }
                
                // Debug
                print("PM time: \(hour) -> \(component.get(.hour) ?? 0)")
            }
        } else {
            component.assign(.hour, value: hour)
        }
        
        component.imply(.second, value: 0)
        component.addTag("ENSimpleTimeParser")
        return component
    }
}