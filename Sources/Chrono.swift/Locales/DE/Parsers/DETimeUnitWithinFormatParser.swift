// DETimeUnitWithinFormatParser.swift - Parser for time expressions with "within" in German
import Foundation

/// Parser for time expressions with "within" in German like "innerhalb von 3 Tagen", "binnen 2 Wochen", etc.
public struct DETimeUnitWithinFormatParser: Parser {
    public init() {}
    
    public func pattern(context: ParsingContext) -> String {
        return "(?:\\W|^)" +
               "(innerhalb|binnen|während|waehrend|in)\\s*(?:von)?\\s*" +
               "(?:(?:ca\\.|circa|etwa|ungefähr|ungefaehr)\\s*)?" +
               "((?:einer?|\\d+)(?:\\.\\d+)?)\\s*" +
               "(sekunden?|minuten?|stunden?|tag(?:en)?|wochen?|monat(?:en)?|jahr(?:en)?|(?:s|m|h|d|w|j))" +
               "(?=\\W|$)"
    }
    
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let result = ParsingComponents(reference: context.reference)
        
        // Extract the number part (default to 1)
        var number: Int = 1
        
        // Parse the number from the matched group
        if let numberStr = match.string(at: 2)?.lowercased() {
            if numberStr.starts(with: "ein") {
                number = 1
            } else if let numVal = Double(numberStr) {
                number = Int(numVal)
            }
        }
        
        // Extract time unit
        guard let unitStr = match.string(at: 3)?.lowercased() else {
            return nil
        }
        
        var timeUnit: Calendar.Component?
        
        // Direct matching
        for (unitString, component) in DEConstants.TIMEUNIT_DICTIONARY {
            if unitStr.starts(with: unitString) {
                timeUnit = component
                break
            }
        }
        
        // Single letter abbreviations
        if timeUnit == nil {
            if unitStr == "s" {
                timeUnit = .second
            } else if unitStr == "m" {
                timeUnit = .minute
            } else if unitStr == "h" {
                timeUnit = .hour
            } else if unitStr == "d" {
                timeUnit = .day
            } else if unitStr == "w" {
                timeUnit = .weekOfYear
            } else if unitStr == "j" {
                timeUnit = .year
            }
        }
        
        guard let unit = timeUnit else {
            return nil
        }
        
        // For "within" expressions, we're always looking at future dates
        let modifier = 1
        
        // Calculate target date
        let calendar = Calendar.current
        let referenceDate = context.reference.instant
        
        guard let targetDate = calendar.date(byAdding: unit, value: number * modifier, to: referenceDate) else {
            return nil
        }
        
        // Extract components from the calculated date
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: targetDate)
        
        if let year = dateComponents.year {
            result.assign(.year, value: year)
        }
        if let month = dateComponents.month {
            result.assign(.month, value: month)
        }
        if let day = dateComponents.day {
            result.assign(.day, value: day)
        }
        if let hour = dateComponents.hour {
            result.assign(.hour, value: hour)
        }
        if let minute = dateComponents.minute {
            result.assign(.minute, value: minute)
        }
        if let second = dateComponents.second {
            result.assign(.second, value: second)
        }
        
        return result
    }
}