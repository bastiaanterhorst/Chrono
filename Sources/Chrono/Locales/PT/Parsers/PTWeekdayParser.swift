// PTWeekdayParser.swift - Parser for weekday names in Portuguese
import Foundation

/// Parser for Portuguese weekday expressions like "segunda-feira", "domingo", etc.
public final class PTWeekdayParser: Parser {
    /// Returns the pattern for matching Portuguese weekday names
    public func pattern(context: ParsingContext) -> String {
        let weekdayNames = PatternUtils.matchAnyPattern(PTConstants.WEEKDAY_DICTIONARY)
        return "(?:(?:\\,|\\(|\\（)\\s*)?(?:na\\s*)?(" + weekdayNames + ")(?:(?:\\,|\\)|\\）)\\s*)?(?:\\s*(passada|passado|[uú]ltim[ao]|pr[oó]xim[ao]))?(?=\\W|$)"
    }
    
    /// Extracts weekday information from matched text
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let dayOfWeekText = match.string(at: 1)?.lowercased() else { return nil }
        
        guard let dayOfWeek = PTConstants.WEEKDAY_DICTIONARY.matchValue(for: dayOfWeekText) else { return nil }
        
        let component = context.createParsingComponents()
        let refDate = context.refDate
        let calendar = Calendar.current
        
        let modifier = match.string(at: 2)?.foldedForMatching()
        
        let startDate = createDateWithExactWeekday(calendar, refDate, dayOfWeek)
        
        // Handle modifiers like "próxima" (next), "última" (last)
        if let modifier = modifier {
            if ["passada", "passado", "ultima", "ultimo"].contains(modifier) {
                // Use the previous occurrence
                let date = calendar.date(byAdding: .day, value: -7, to: startDate) ?? startDate
                component.assign(.day, value: calendar.component(.day, from: date))
                component.assign(.month, value: calendar.component(.month, from: date))
                component.assign(.year, value: calendar.component(.year, from: date))
            } else if ["proxima", "proximo"].contains(modifier) {
                // Use the next occurrence
                let date = calendar.date(byAdding: .day, value: 7, to: startDate) ?? startDate
                component.assign(.day, value: calendar.component(.day, from: date))
                component.assign(.month, value: calendar.component(.month, from: date))
                component.assign(.year, value: calendar.component(.year, from: date))
            }
        } else {
            // Use the next occurrence (or the current day if today is that day)
            component.assign(.day, value: calendar.component(.day, from: startDate))
            component.assign(.month, value: calendar.component(.month, from: startDate))
            component.assign(.year, value: calendar.component(.year, from: startDate))
        }
        
        component.imply(.hour, value: 12)
        component.addTag("PTWeekdayParser")
        return component
    }
    
    /// Creates a date with the next occurrence of the given weekday
    private func createDateWithExactWeekday(_ calendar: Calendar, _ refDate: Date, _ dayOfWeek: Int) -> Date {
        let currentWeekday = calendar.component(.weekday, from: refDate)
        
        // Calculate days to add to reach target weekday
        var daysToAdd = dayOfWeek - currentWeekday
        
        // If target weekday is earlier in the week, move to next week
        if daysToAdd <= 0 {
            daysToAdd += 7
        }
        
        // Special case: If today is the target weekday, use today
        if dayOfWeek == currentWeekday {
            daysToAdd = 0
        }
        
        return calendar.date(byAdding: .day, value: daysToAdd, to: refDate) ?? refDate
    }
}