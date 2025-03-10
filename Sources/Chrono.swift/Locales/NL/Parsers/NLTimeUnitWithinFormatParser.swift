// NLTimeUnitWithinFormatParser.swift - Parser for time expressions with "binnen" in Dutch
import Foundation

/// Parser for time expressions with "binnen" in Dutch like "binnen 3 dagen"
final class NLTimeUnitWithinFormatParser: Parser {
    func pattern(context: ParsingContext) -> String {
        let timeUnits = PatternUtils.matchAnyPattern(NLConstants.TIME_UNIT_DICTIONARY)
        
        let start = "(?:(?:\\s|^)(?:"
        let prefix = "(?:binnen|in)\\s*"
        let number = "((?:een|[0-9]+)(?:\\s+(?:paar|aantal))?(?:\\s*[,.])?)\\s*"
        let unit = "(" + timeUnits + ")"
        let end = ")(?=\\W|$))"
        
        return start + prefix + number + unit + end
    }
    
    func extract(context: ParsingContext, match: TextMatch) -> Any? {
        // Extract the time amount and unit
        guard let timeText = match.string(at: 1)?.lowercased(),
              let unitText = match.string(at: 2)?.lowercased(),
              let unit = NLConstants.TIME_UNIT_DICTIONARY[unitText] else {
            return nil
        }
        
        let num = extractNumber(from: timeText)
        var targetDate = context.refDate
        
        // Special handling for weeks (convert to days)
        if unitText == "week" || unitText == "weken" {
            targetDate = Calendar.current.date(byAdding: .day, value: num * 7, to: targetDate) ?? targetDate
        } else {
            // Convert unit to Calendar.Component
            let calendarComponent: Calendar.Component
            
            switch unit {
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
        if unit == .hour || unit == .minute || unit == .second {
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