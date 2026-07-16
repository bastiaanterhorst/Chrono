// DETimeUnitRelativeFormatParser.swift - Parser for relative time expressions in German
import Foundation

/// Parser for relative time expressions in German like "in 3 Tagen", "vor 1 Woche", etc.
public struct DETimeUnitRelativeFormatParser: Parser {
    public init() {}
    
    public func pattern(context: ParsingContext) -> String {
        // A real direction word is required; approximation words alone ("etwa 2 Stunden") are
        // durations, not deadlines, and must not match. Case-insensitive: units are capitalized
        // nouns in German ("in 5 Stunden").
        return "(?i)(?:\\W|^)" +
               "(in|vor)\\s*(?:(?:etwa|ungefähr|ungefaehr|ca\\.|circa)\\s*)?" +
               "((?:eine[mr]?|\\d+)(?:\\.\\d+)?)\\s*" +
               "(minuten?|stunden?|tag(?:en)?|wochen?|monat(?:en)?|jahr(?:en)?|(?:m|h|d|w|j))" +
               "(?:\\s*(?:zuvor|danach|später|spaeter))?" +
               "(?=\\W|$)"
    }
    
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let result = ParsingComponents(reference: context.reference)
        
        // Get direction (future or past)
        let directionStr = match.string(at: 1)?.lowercased() ?? ""
        let modifier: Int
        if directionStr == "vor" || directionStr.starts(with: "vor") {
            modifier = -1 // Past
        } else {
            modifier = 1 // Future
        }
        
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
            if unitStr == "m" {
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
        
        // Calculate target date
        let calendar = Calendar.current
        let referenceDate = context.reference.instant
        
        guard let targetDate = calendar.date(byAdding: unit, value: number * modifier, to: referenceDate) else {
            return nil
        }
        
        // The date portion is known; the time-of-day is only known for time units
        // (e.g. "in 5 Stunden"), otherwise it is merely implied (e.g. "in 3 Tagen").
        let isTimeUnit = (unit == .minute || unit == .hour)
        result.assignRelativeDate(from: targetDate, unitIsTime: isTimeUnit, calendar: calendar)

        return result
    }
}