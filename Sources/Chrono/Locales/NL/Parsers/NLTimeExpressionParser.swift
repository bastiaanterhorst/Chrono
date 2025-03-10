// NLTimeExpressionParser.swift - Parser for time expressions in Dutch
import Foundation

/// Parser for standard time expressions in Dutch
final class NLTimeExpressionParser: Parser {
    func pattern(context: ParsingContext) -> String {
        return "(?:(?:\\s|^))" +
            "(?:" +
                "(?:om|vanaf|om\\s+ongeveer|ongeveer\\s+om|ongeveer)\\s*" +
            ")?" +
            "(?:" +
                "(\\d{1,2})(?::|\\.|\\s*uur\\s*)(?:(\\d{1,2})(?::|\\.)?(\\d{0,2})?)?" +
                "(?:\\s*(?:uur))?" +
                "(?:\\s*(?:([ap])\\.?m\\.?|([ap])))?" +
            "|" +
                "(\\d{1,2})(?:\\s*|\\s*[:.\\s])\\s*(?:([ap])\\.?m\\.?|([ap]))" +
            ")" +
            "(?:\\s*(?:uur))?" +
            "(?=\\W|$)"
    }
    
    func extract(context: ParsingContext, match: TextMatch) -> Any? {
        // Check if this is a valid time expression
        if !match.hasValue(at: 1) && !match.hasValue(at: 6) {
            return nil
        }
        
        var hour: Int
        var minute = 0
        var second = 0
        var meridiem: Meridiem?
        
        if match.hasValue(at: 1) {
            // HH:mm or HH.mm format
            if let hourStr = match.string(at: 1), let hourVal = Int(hourStr) {
                hour = hourVal
                
                if let minuteStr = match.string(at: 2), let minuteVal = Int(minuteStr) {
                    minute = minuteVal
                    
                    if minuteVal >= 60 {
                        return nil
                    }
                    
                    if let secondStr = match.string(at: 3), let secondVal = Int(secondStr) {
                        second = secondVal
                        
                        if secondVal >= 60 {
                            return nil
                        }
                    }
                }
                
                // Check for AM/PM
                if let ap1 = match.string(at: 4)?.lowercased() {
                    if ap1.starts(with: "a") {
                        meridiem = .am
                        if hour == 12 {
                            hour = 0
                        }
                    }
                    if ap1.starts(with: "p") {
                        meridiem = .pm
                        if hour != 12 {
                            hour += 12
                        }
                    }
                } else if let ap2 = match.string(at: 5)?.lowercased() {
                    if ap2.starts(with: "a") {
                        meridiem = .am
                        if hour == 12 {
                            hour = 0
                        }
                    }
                    if ap2.starts(with: "p") {
                        meridiem = .pm
                        if hour != 12 {
                            hour += 12
                        }
                    }
                }
                
                // Invalid hour
                if hour > 24 {
                    return nil
                }
            } else {
                return nil
            }
        } else if match.hasValue(at: 6) {
            // H am/pm format
            if let hourStr = match.string(at: 6), let hourVal = Int(hourStr) {
                hour = hourVal
                
                // Check for AM/PM
                if let ap1 = match.string(at: 7)?.lowercased() {
                    if ap1.starts(with: "a") {
                        meridiem = .am
                        if hour == 12 {
                            hour = 0
                        }
                    }
                    if ap1.starts(with: "p") {
                        meridiem = .pm
                        if hour != 12 {
                            hour += 12
                        }
                    }
                } else if let ap2 = match.string(at: 8)?.lowercased() {
                    if ap2.starts(with: "a") {
                        meridiem = .am
                        if hour == 12 {
                            hour = 0
                        }
                    }
                    if ap2.starts(with: "p") {
                        meridiem = .pm
                        if hour != 12 {
                            hour += 12
                        }
                    }
                }
                
                // Invalid hour
                if hour > 24 {
                    return nil
                }
            } else {
                return nil
            }
        } else {
            return nil
        }
        
        // Build the result
        var result: [Component: Int] = [:]
        result[.hour] = hour
        result[.minute] = minute
        
        if second > 0 {
            result[.second] = second
        }
        
        if let m = meridiem {
            result[.meridiem] = m.rawValue
        }
        
        return result
    }
}