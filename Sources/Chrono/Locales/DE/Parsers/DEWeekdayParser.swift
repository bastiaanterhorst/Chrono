// DEWeekdayParser.swift - Parser for weekday mentions in German
import Foundation

/// Parser for weekday mentions in German like "Montag", "am Dienstag", etc.
public struct DEWeekdayParser: Parser {
    public init() {}
    
    public func pattern(context: ParsingContext) -> String {
        let weekdayRegex = DEConstants.WEEKDAY_DICTIONARY.keys
            .map { "[" + $0.prefix(1).uppercased() + $0.prefix(1).lowercased() + "]" + $0.dropFirst() }
            .joined(separator: "|")
        
        return "(?:\\W|^)" +
               "(?:(?:\\,|\\(|\\（)\\s*)?" +
               "(?:([Aa][nm])\\s*?)?" +
               "(?:([Dd]iese[nm]?|[Ll]etzte[nm]?|[Nn]ächste[nm]?|[Nn]aechste[nm]?|[Kk]ommende[nm]?)\\s*)?" +
               "(" + weekdayRegex + ")" +
               "(?:\\s*(?:\\,|\\)|\\）))?" +
               "(?:\\s*([Dd]iese|[Ll]etzte|[Nn]ächste|[Nn]aechste|[Kk]ommende)\\s*[Ww]oche)?" +
               "(?=\\W|$)"
    }
    
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let result = ParsingComponents(reference: context.reference)
        
        // Extract weekday - find by prefix match or exact match
        guard let weekdayStr = match.string(at: 3)?.lowercased() else {
            return nil
        }
        
        var weekday: Int?
        
        // Try exact match first
        if let exactMatch = DEConstants.WEEKDAY_DICTIONARY[weekdayStr] {
            weekday = exactMatch
        } else {
            // Try to match by prefix
            for (day, value) in DEConstants.WEEKDAY_DICTIONARY {
                if weekdayStr.starts(with: day) || 
                   weekdayStr.lowercased().contains(day) {
                    weekday = value
                    break
                }
            }
        }
        
        guard let weekday = weekday else {
            return nil
        }
        
        // Determine modifier (this/last/next week)
        var modifier = 0
        
        if let modifierStr1 = match.string(at: 2)?.lowercased() {
            if modifierStr1.starts(with: "letzte") {
                modifier = -1
            } else if modifierStr1.starts(with: "nächste") || modifierStr1.starts(with: "kommende") {
                modifier = 1
            }
        }
        
        if modifier == 0, let modifierStr2 = match.string(at: 4)?.lowercased() {
            if modifierStr2.starts(with: "letzte") {
                modifier = -1
            } else if modifierStr2.starts(with: "nächste") || modifierStr2.starts(with: "kommende") {
                modifier = 1
            }
        }
        
        let calendar = Calendar.current
        let refDate = context.reference.instant
        
        // Calculate target date
        let refWeekday = calendar.component(.weekday, from: refDate) - 1 // Sunday = 0, Monday = 1, etc.
        
        var dayDiff = weekday - refWeekday
        
        // Adjust based on modifier
        if dayDiff < 0 {
            dayDiff += 7
        }
        
        if dayDiff == 0 && modifier == 0 {
            // Today and no modifier, don't adjust
        } else if dayDiff == 0 && modifier > 0 {
            // Next week
            dayDiff = 7
        } else if dayDiff == 0 && modifier < 0 {
            // Last week
            dayDiff = -7
        } else if modifier > 0 {
            // Next [weekday]
            if dayDiff <= 0 {
                dayDiff += 7
            }
        } else if modifier < 0 {
            // Last [weekday]
            if dayDiff > 0 {
                dayDiff -= 7
            }
        }
        
        // Create the target date by adding dayDiff to reference date
        guard let targetDate = calendar.date(byAdding: .day, value: dayDiff, to: refDate) else {
            return nil
        }
        
        // Extract relevant components from the target date
        let components = calendar.dateComponents([.year, .month, .day], from: targetDate)
        
        if let year = components.year {
            result.assign(.year, value: year)
        }
        if let month = components.month {
            result.assign(.month, value: month)
        }
        if let day = components.day {
            result.assign(.day, value: day)
        }
        
        return result
    }
}