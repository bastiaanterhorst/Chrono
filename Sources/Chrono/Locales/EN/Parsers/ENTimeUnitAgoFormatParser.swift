// ENTimeUnitAgoFormatParser.swift
import Foundation

/// Parser for time expressions with 'ago' in English like "3 days ago", "5 months ago", etc.
public struct ENTimeUnitAgoFormatParser: Parser {
    public init() {}
    
    public func pattern(context: ParsingContext) -> String {
        return "(\\W|^)" +
               "(?:within\\s*)?" +
               "([0-9]+|a(?:n)?|half(?:\\s*an)?|some|couple(?:\\s*of)?)" +
               "\\s*" +
               "(seconds?|minutes?|hours?|days?|weeks?|months?|years?)" +
               "\\s*" +
               "(?:ago|before|earlier)(?=(?:\\W|$))"
    }
    
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let text = match.text
        let result = ParsingComponents(reference: context.reference)
        
        let referenceDate = context.reference.instant
        let modifier = -1 // Past (ago)
        
        // Number value
        var number: Int
        if let numStr = match.string(at: 2), let num = Int(numStr) {
            number = num
        } else if let numberText = match.string(at: 2)?.lowercased(),
                  numberText.contains("a") || numberText.contains("an") {
            number = 1
        } else if let numberText = match.string(at: 2)?.lowercased(),
                  numberText.contains("half") {
            // Half a [unit] ago
            number = 1
            // TODO: Support fractional units
        } else if let numberText = match.string(at: 2)?.lowercased(),
                  numberText.contains("couple") {
            number = 2
        } else if let numberText = match.string(at: 2)?.lowercased(),
                  numberText.contains("some") {
            number = 2 // Approximate
        } else {
            return nil
        }
        
        // Time unit
        guard let unitText = match.string(at: 3)?.lowercased() else { return nil }
        var timeUnit: Calendar.Component
        var calendar = Calendar.current
        
        if unitText.starts(with: "second") {
            timeUnit = .second
        } else if unitText.starts(with: "minute") {
            timeUnit = .minute
        } else if unitText.starts(with: "hour") {
            timeUnit = .hour
        } else if unitText.starts(with: "day") {
            timeUnit = .day
        } else if unitText.starts(with: "week") {
            timeUnit = .weekOfYear
        } else if unitText.starts(with: "month") {
            timeUnit = .month
        } else if unitText.starts(with: "year") {
            timeUnit = .year
        } else {
            return nil
        }
        
        // Calculate the date by adjusting the reference date
        guard let date = calendar.date(byAdding: timeUnit, value: number * modifier, to: referenceDate) else {
            return nil
        }
        
        // Extract components from the calculated date
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        // Assign the components to the ParsingComponents
        if let year = components.year {
            result.assign(.year, value: year)
        }
        if let month = components.month {
            result.assign(.month, value: month)
        }
        if let day = components.day {
            result.assign(.day, value: day)
        }
        if let hour = components.hour {
            result.assign(.hour, value: hour)
        }
        if let minute = components.minute {
            result.assign(.minute, value: minute)
        }
        if let second = components.second {
            result.assign(.second, value: second)
        }
        
        return result
    }
}