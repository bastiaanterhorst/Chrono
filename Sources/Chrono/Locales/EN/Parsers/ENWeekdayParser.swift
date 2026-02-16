// ENWeekdayParser.swift - Parser for weekday expressions
import Foundation

/// Parser for weekday mentions like "Monday", "Tuesday", etc.
public final class ENWeekdayParser: Parser {
    private static let PATTERN = "(?:(this|last|next|past|previous)\\s+)?" +
                                 "(sunday|sun|monday|mon|tuesday|tues|tue|wednesday|wed|thursday|thur|thu|friday|fri|saturday|sat)" +
                                 "(?=\\W|$)"
    
    private static let WEEKDAY_DICTIONARY: [String: Int] = [
        "sunday": 0, "sun": 0,
        "monday": 1, "mon": 1,
        "tuesday": 2, "tues": 2, "tue": 2,
        "wednesday": 3, "wed": 3,
        "thursday": 4, "thur": 4, "thu": 4,
        "friday": 5, "fri": 5,
        "saturday": 6, "sat": 6
    ]
    
    /// Returns the regex pattern for this parser
    public func pattern(context: ParsingContext) -> String {
        return ENWeekdayParser.PATTERN
    }
    
    /// Extracts date from weekday mentions
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let component = context.createParsingComponents()
        let calendar = Calendar.current
        
        // Get the modifier (this, last, next, etc.)
        let modifier = match.string(at: 1)?.lowercased()
        // Get the weekday text
        guard let weekdayText = match.string(at: 2)?.lowercased(),
              let weekday = ENWeekdayParser.WEEKDAY_DICTIONARY[weekdayText] else {
            return nil
        }
        
        component.assign(.weekday, value: weekday)
        
        // Calculate the date
        let refDate = context.refDate
        let currentDay = calendar.component(.weekday, from: refDate) - 1 // Swift weekday is 1-7, we need 0-6
        
        // Figure out the day difference
        var dayDiff = weekday - currentDay
        
        // Adjust based on modifier
        if let modifier = modifier {
            switch modifier {
            case "last", "past", "previous":
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
        
        component.addTag("ENWeekdayParser")
        return component
    }
}
