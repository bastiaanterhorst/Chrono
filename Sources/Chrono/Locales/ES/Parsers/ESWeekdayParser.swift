// ESWeekdayParser.swift - Parser for weekday expressions in Spanish
import Foundation

/// Parser for weekday expressions in Spanish (e.g., "lunes", "este martes", "próximo miércoles")
public final class ESWeekdayParser: Parser {
    private static let PATTERN = "(?:(?:\\,|\\(|\\（)\\s*)?(?:(este|esta|pasado|pr[oó]ximo)\\s*)?(\(PatternUtils.matchAnyPattern(ESConstants.WEEKDAY_DICTIONARY)))(?:\\s*(?:\\,|\\)|\\）))?(?:\\s*(este|esta|pasado|pr[óo]ximo)\\s*semana)?(?=\\W|\\d|$)"
    
    private static let PREFIX_GROUP = 1
    private static let WEEKDAY_GROUP = 2
    private static let POSTFIX_GROUP = 3
    
    public func pattern(context: ParsingContext) -> String {
        return ESWeekdayParser.PATTERN
    }
    
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let weekdayText = match.string(at: ESWeekdayParser.WEEKDAY_GROUP)?.lowercased(),
              let weekday = ESConstants.WEEKDAY_DICTIONARY[weekdayText] else {
            return nil
        }
        
        let prefix = match.string(at: ESWeekdayParser.PREFIX_GROUP) ?? ""
        let postfix = match.string(at: ESWeekdayParser.POSTFIX_GROUP) ?? ""
        let norm = (prefix + postfix).lowercased()
        
        var modifier: String? = nil
        if norm.contains("pasado") {
            modifier = "last"
        } else if norm.contains("próximo") || norm.contains("proximo") {
            modifier = "next"
        } else if norm.contains("este") || norm.contains("esta") {
            modifier = "this"
        }
        
        // Calculate the date directly
        let component = context.createParsingComponents()
        let calendar = Calendar.current
        
        component.assign(.weekday, value: weekday)
        
        // Calculate the date
        let refDate = context.refDate
        let currentDay = calendar.component(.weekday, from: refDate) - 1 // Swift weekday is 1-7, we need 0-6
        
        // Figure out the day difference
        var dayDiff = weekday - currentDay
        
        // Adjust based on modifier
        if let modifier = modifier {
            switch modifier {
            case "last":
                if dayDiff >= 0 {
                    dayDiff -= 7
                }
            case "next":
                if dayDiff <= 0 {
                    dayDiff += 7
                }
            case "this":
                if dayDiff < 0 {
                    dayDiff += 7
                }
            default:
                break
            }
        } else {
            // Default behavior (no modifier)
            if dayDiff < 0 {
                dayDiff += 7
            }
        }
        
        // Calculate the date components
        guard let targetDate = calendar.date(byAdding: .day, value: dayDiff, to: refDate) else {
            return nil
        }
        
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)
        
        if let year = dateComponents.year {
            component.assign(.year, value: year)
        }
        
        if let month = dateComponents.month {
            component.assign(.month, value: month)
        }
        
        if let day = dateComponents.day {
            component.assign(.day, value: day)
        }
        
        component.addTag("ESWeekdayParser")
        return component
    }
}