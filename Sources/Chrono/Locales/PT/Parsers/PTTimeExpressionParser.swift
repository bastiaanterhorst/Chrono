// PTTimeExpressionParser.swift - Parser for time expressions in Portuguese
import Foundation

/// Parser for Portuguese time expressions like "às 3", "3:30", "15:45", etc.
public final class PTTimeExpressionParser: Parser {
    /// Returns the pattern for matching Portuguese time expressions
    public func pattern(context: ParsingContext) -> String {
        let hourMinuteRegex = "\\d{1,2}(?:h|:)\\d{2}(?:min|\\.)?";
        let hourRegex = "\\d{1,2}(?:h|\\.)?";
        
        return "(?:às|as|[àa]s)?\\s*(" + hourMinuteRegex + "|" + hourRegex + ")(?:\\s*(da|pela|de|do|na|no)\\s*(manhã|manha|tarde|noite))?(?=\\W|$)"
    }
    
    /// Extracts time components from a matched time expression
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let timeText = match.string(at: 1)?.lowercased() else { return nil }
        
        // Extract reference date components
        let refDate = context.refDate
        let calendar = Calendar.current
        
        // Implicitly set to reference date
        let component = context.createParsingComponents()
        component.imply(.day, value: calendar.component(.day, from: refDate))
        component.imply(.month, value: calendar.component(.month, from: refDate))
        component.imply(.year, value: calendar.component(.year, from: refDate))
        
        // Extract hour and minute
        let hourMinuteSeparators = [":", "h"]
        var hour: Int? = nil
        var minute: Int = 0
        
        for separator in hourMinuteSeparators {
            if timeText.contains(separator) {
                let components = timeText.components(separatedBy: separator)
                if components.count >= 2 {
                    hour = Int(components[0].trimmingCharacters(in: .whitespacesAndNewlines))
                    
                    // Extract minute, removing any "min" suffix
                    let minuteText = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    let cleanMinuteText = minuteText.replacingOccurrences(of: "min", with: "")
                                                   .replacingOccurrences(of: "\\.", with: "", options: .regularExpression)
                    minute = Int(cleanMinuteText) ?? 0
                    break
                }
            }
        }
        
        // Handle case where only the hour is specified (e.g., "3h")
        if hour == nil {
            let cleanTimeText = timeText.replacingOccurrences(of: "h", with: "")
                                       .replacingOccurrences(of: "\\.", with: "", options: .regularExpression)
            hour = Int(cleanTimeText)
            minute = 0
        }
        
        guard let hour = hour else { return nil }
        
        // Apply AM/PM meridiem from period mentions
        var meridiem: Int? = nil
        if let period = match.string(at: 3)?.lowercased() {
            if period.contains("manhã") || period.contains("manha") {
                meridiem = Meridiem.am.rawValue
            } else if period.contains("tarde") || period.contains("noite") {
                meridiem = Meridiem.pm.rawValue
            }
        }
        
        // Handle the 12-hour clock
        if meridiem == Meridiem.am.rawValue && hour == 12 {
            component.assign(.hour, value: 0)
        } else if meridiem == Meridiem.pm.rawValue && hour < 12 {
            component.assign(.hour, value: hour + 12)
        } else {
            component.assign(.hour, value: hour)
        }
        
        component.assign(.minute, value: minute)
        
        // If meridiem was assigned explicitly
        if let meridiem = meridiem {
            component.assign(.meridiem, value: meridiem)
        } 
        // Otherwise infer based on hour
        else if hour < 12 {
            component.imply(.meridiem, value: Meridiem.am.rawValue)
        } else {
            component.imply(.meridiem, value: Meridiem.pm.rawValue)
        }
        
        component.addTag("PTTimeExpressionParser")
        return component
    }
}