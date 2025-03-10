// NLWeekdayParser.swift - Parser for weekday mentions in Dutch
import Foundation

/// Parser for weekday expressions in Dutch like "maandag", "dinsdag", etc.
final class NLWeekdayParser: Parser {
    func pattern(context: ParsingContext) -> String {
        let weekdays = PatternUtils.matchAnyPattern(NLConstants.WEEKDAY_DICTIONARY)
        
        let start = "(?:(?:\\s|^)"
        let prefix = "(?:op\\s*?)?"
        let modifier = "(?:(deze|dit|vorige|afgelopen|komende|komend|volgende|volgend|laatste|laatst|eerste|eerst)\\s*(?:week\\s*)?)?"
        let day = "(" + weekdays + ")"
        let suffix = "(?:\\s*(?:om|,|om\\s+ongeveer|ongeveer\\s+om|ongeveer)\\s*)?"
        let end = "(?=\\W|$))"
        
        return start + prefix + modifier + day + suffix + end
    }
    
    func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let dayOfWeekText = match.string(at: 2)?.lowercased()
        guard let dayOfWeek = dayOfWeekText, let offset = NLConstants.WEEKDAY_DICTIONARY[dayOfWeek] else {
            return nil
        }
        
        let prefix = match.string(at: 1)?.lowercased()
        let modifier = prefix ?? ""
        
        let date = context.refDate
        let components = Calendar.current.dateComponents([.weekday], from: date)
        guard let currentDayOfWeek = components.weekday else {
            return nil
        }
        
        // In Swift Calendar, 1 is Sunday, 2 is Monday, etc.
        // We need to convert to our system where 0 is Sunday, 1 is Monday, etc.
        let currentDayOfWeekIndex = currentDayOfWeek - 1
        
        var dayToAdd = offset - currentDayOfWeekIndex
        
        // Adjust based on modifier
        if modifier.contains("vorige") || modifier.contains("afgelopen") || modifier.contains("laatste") || modifier.contains("laatst") {
            // If dayToAdd is positive, we need to go back a week
            if dayToAdd > 0 {
                dayToAdd -= 7
            }
        } else if modifier.contains("komende") || modifier.contains("komend") || modifier.contains("volgende") || modifier.contains("volgend") {
            // If dayToAdd is negative, we need to go forward a week
            if dayToAdd < 0 {
                dayToAdd += 7
            }
            
            // Special case for "volgende" on same day of week
            if dayToAdd == 0 && (modifier.contains("volgende") || modifier.contains("volgend") || 
                                modifier.contains("komende") || modifier.contains("komend")) {
                dayToAdd = 7
            }
        } else if modifier.contains("eerste") || modifier.contains("eerst") {
            // "eerste" should find the first occurrence of the day of week in the current month
            let calendar = Calendar.current
            
            // Get the first day of the current month
            let comps = calendar.dateComponents([.year, .month], from: date)
            var newComps = DateComponents()
            newComps.year = comps.year
            newComps.month = comps.month
            newComps.day = 1
            
            guard let firstDay = calendar.date(from: newComps) else {
                return nil
            }
            
            // Find the first occurrence of the specified day of week in this month
            let firstDayWeekday = calendar.component(.weekday, from: firstDay) - 1
            let targetWeekday = offset
            
            // Calculate days to add to reach the target weekday
            dayToAdd = (targetWeekday - firstDayWeekday + 7) % 7
            
            // Adjust the reference date to the first day of the month
            var targetDate = firstDay
            targetDate = calendar.date(byAdding: .day, value: dayToAdd, to: targetDate) ?? targetDate
            
            // Get components from the calculated date
            let targetComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)
            
            var result: [Component: Int] = [:]
            
            if let year = targetComponents.year {
                result[.year] = year
            }
            
            if let month = targetComponents.month {
                result[.month] = month
            }
            
            if let day = targetComponents.day {
                result[.day] = day
            }
            
            return result
        } else if modifier.contains("deze") || modifier.contains("dit") {
            // If it's "deze/dit" (this), keep it in the current week
            // If the day has passed, it could refer to next week
            if dayToAdd < 0 && context.options.forwardDate {
                dayToAdd += 7
            }
        } else {
            // No modifier
            // If the day has passed, it could refer to next week
            if dayToAdd <= 0 && context.options.forwardDate {
                dayToAdd += 7
            }
        }
        
        let targetDate = Calendar.current.date(byAdding: .day, value: dayToAdd, to: date) ?? date
        let targetComponents = Calendar.current.dateComponents([.year, .month, .day], from: targetDate)
        
        var result: [Component: Int] = [:]
        
        if let year = targetComponents.year {
            result[.year] = year
        }
        
        if let month = targetComponents.month {
            result[.month] = month
        }
        
        if let day = targetComponents.day {
            result[.day] = day
        }
        
        return result
    }
}