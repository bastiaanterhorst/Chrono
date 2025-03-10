// NLTimeUnitRelativeFormatParser.swift - Parser for relative time expressions in Dutch
import Foundation

/// Parser for relative time expressions in Dutch like "3 dagen geleden" or "over 2 weken"
final class NLTimeUnitRelativeFormatParser: Parser {
    func pattern(context: ParsingContext) -> String {
        let timeUnits = PatternUtils.matchAnyPattern(NLConstants.TIME_UNIT_DICTIONARY)
        
        // Pattern components
        let start = "(?:(?:\\s|^)(?:"
        
        // Past pattern
        let numPattern = "((?:een|[0-9]+)(?:\\s+(?:paar|aantal))?(?:\\s*[,.])?)\\s*"
        let pastTimeUnit = "(" + timeUnits + ")"
        let pastSuffix = "(?:\\s+geleden|\\s+terug)"
        let pastPattern = "(?:" + numPattern + pastTimeUnit + pastSuffix + ")"
        
        // Future pattern
        let futurePrefix = "(?:(?:binnen|over|nog)\\s+)"
        let futureNum = "((?:een|[0-9]+)(?:\\s+(?:paar|aantal))?(?:\\s*[,.])?)\\s*"
        let futureTimeUnit = "(" + timeUnits + ")"
        let futureNegation = "(?!\\s*(?:in|op|vanaf)(?:\\s|$))"
        let futurePattern = "(?:" + futurePrefix + futureNum + futureTimeUnit + futureNegation + ")"
        
        // Specific relative patterns (volgende week/maand/jaar, vorige week/maand/jaar, etc.)
        let relativePrefix = "((?:volgende|volgend|komende|komend|vorige|vorig|afgelopen|deze|dit)\\s+)"
        let relativeTimeUnit = "(" + timeUnits + ")"
        let relativePattern = "(?:" + relativePrefix + relativeTimeUnit + ")"
        
        let end = ")(?=\\W|$))"
        
        return start + pastPattern + "|" + futurePattern + "|" + relativePattern + end
    }
    
    func extract(context: ParsingContext, match: TextMatch) -> Any? {
        var targetDate = context.refDate
        
        // Extract quantity
        var timeText: String?
        var unitText: String?
        var num: Int = 0
        var modifier: Component?
        
        if match.hasValue(at: 1) && match.hasValue(at: 2) {
            // past - "3 dagen geleden"
            timeText = match.string(at: 1)?.lowercased()
            unitText = match.string(at: 2)?.lowercased()
            num = extractNumber(from: timeText ?? "")
            modifier = NLConstants.TIME_UNIT_DICTIONARY[unitText ?? ""]
            
            // Negative for past
            num *= -1
        } else if match.hasValue(at: 4) && match.hasValue(at: 5) {
            // future - "over 3 dagen"
            timeText = match.string(at: 4)?.lowercased()
            unitText = match.string(at: 5)?.lowercased()
            num = extractNumber(from: timeText ?? "")
            modifier = NLConstants.TIME_UNIT_DICTIONARY[unitText ?? ""]
        } else if match.hasValue(at: 7) && match.hasValue(at: 8) {
            // relative - "volgende week", "vorige maand"
            let relativeModifier = match.string(at: 7)?.lowercased() ?? ""
            unitText = match.string(at: 8)?.lowercased()
            modifier = NLConstants.TIME_UNIT_DICTIONARY[unitText ?? ""]
            
            // Set the number based on the modifier
            switch relativeModifier {
            case "vorige", "vorig", "afgelopen":
                num = -1
            case "volgende", "volgend", "komende", "komend":
                num = 1
            case "deze", "dit":
                // "deze"/"dit" refers to the current time unit, no adjustment needed
                num = 0
            default:
                return nil
            }
        } else {
            return nil
        }
        
        guard let component = modifier else {
            return nil
        }
        
        // Handle time units directly using the Calendar API
        let calendarComponent: Calendar.Component
        
        // Check if this is a week unit, which needs special handling
        let isWeekUnit = unitText != nil && NLConstants.isWeek(unitText!)
        
        if isWeekUnit {
            // For weeks, convert to days (1 week = 7 days)
            calendarComponent = .day
            num *= 7
        } else {
            // For other units, use the standard mapping
            switch component {
            case .day:
                calendarComponent = .day
            case .hour:
                calendarComponent = .hour
            case .minute:
                calendarComponent = .minute
            case .second:
                calendarComponent = .second
            case .month:
                calendarComponent = .month
            case .year:
                calendarComponent = .year
            default:
                return nil
            }
        }
        
        // Special handling for months and years with relative expressions to get the first day
        if match.hasValue(at: 7) && (component == .month || component == .year) {
            // For "volgende maand" / "vorige maand" / "volgend jaar" / "vorig jaar"
            // Go to the first day of the target month/year
            var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: targetDate)
            
            if component == .month {
                // Add the specified number of months
                if let currentMonth = dateComponents.month {
                    dateComponents.month = currentMonth + num
                }
                // Set to the first day of the month
                dateComponents.day = 1
            } else if component == .year {
                // Add the specified number of years
                if let currentYear = dateComponents.year {
                    dateComponents.year = currentYear + num
                }
                // For years, optionally reset to January 1st
                dateComponents.month = 1
                dateComponents.day = 1
            }
            
            // Create the date from components
            if let newDate = Calendar.current.date(from: dateComponents) {
                targetDate = newDate
            }
        } else {
            // Normal adjustment for other cases
            targetDate = Calendar.current.date(byAdding: calendarComponent, value: num, to: targetDate) ?? targetDate
        }
        
        // Get components from calculated date
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: targetDate)
        
        // Build result
        var result: [Component: Int] = [:]
        
        if let year = components.year {
            result[.year] = year
        }
        
        if let month = components.month {
            result[.month] = month
        }
        
        if let day = components.day {
            result[.day] = day
        }
        
        // Add time components if the unit is hour or smaller
        if component == .hour || component == .minute || component == .second {
            if let hour = components.hour {
                result[.hour] = hour
            }
            
            if let minute = components.minute {
                result[.minute] = minute
            }
            
            if let second = components.second {
                result[.second] = second
            }
        }
        
        return result
    }
    
    /// Extracts a number from text, handling Dutch number words
    private func extractNumber(from text: String) -> Int {
        let cleanText = text.trimmingCharacters(in: .whitespaces)
        
        if cleanText == "een" || cleanText.contains("een") {
            return 1
        }
        
        if let num = Int(cleanText) {
            return num
        }
        
        if let word = NLConstants.INTEGER_WORD_DICTIONARY[cleanText] {
            return word
        }
        
        return 1 // Default if we can't determine the number
    }
}