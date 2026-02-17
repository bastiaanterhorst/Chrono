// ENTimeUnitWithinFormatParser.swift
import Foundation

/// Parser for time expressions with "within" or time intervals like "within 2 weeks", "in the last 3 days", etc.
public struct ENTimeUnitWithinFormatParser: Parser {
    public init() {}
    
    public func pattern(context: ParsingContext) -> String {
        return "(\\W|^)" +
               "(?:within|in|for)\\s*" +
               "(?:(?:about|around|roughly|approximately|just)\\s*(?:~\\s*)?)?" +
               "(?:the\\s*)?(?:(past|last|next|coming)\\s*)?" +
               "([0-9]+|a(?:n)?|half(?:\\s*an?)?|some|couple(?:\\s*of)?)" +
               "\\s*" +
               "(seconds?|minutes?|hours?|days?|weeks?|months?|years?)" +
               "(?=\\W|$)"
    }
    
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let text = match.text
        let result = ParsingComponents(reference: context.reference)
        
        let referenceDate = context.reference.instant
        
        // Default to future for phrases like "in 2 days"
        var modifier = 1

        // Get the direction (past/last vs next/coming)
        if let directionStr = match.string(at: 2)?.lowercased() {
            if directionStr == "past" || directionStr == "last" {
                modifier = -1
            } else if directionStr == "next" || directionStr == "coming" {
                modifier = 1
            }
        }
        
        // Get the number
        var number: Int
        if let numStr = match.string(at: 3), let num = Int(numStr) {
            number = num
        } else if let numberText = match.string(at: 3)?.lowercased(),
                  numberText.contains("a") || numberText.contains("an") {
            number = 1
        } else if let numberText = match.string(at: 3)?.lowercased(),
                  numberText.contains("half") {
            number = 1
            // TODO: Support fractional units
        } else if let numberText = match.string(at: 3)?.lowercased(),
                  numberText.contains("couple") {
            number = 2
        } else if let numberText = match.string(at: 3)?.lowercased(),
                  numberText.contains("some") {
            number = 2 // Approximate
        } else {
            return nil
        }
        
        // Get the time unit
        guard let unitText = match.string(at: 4)?.lowercased() else { return nil }
        var timeUnit: Calendar.Component
        
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
        
        // Create an interval from now to X units in the past/future
        let calendar = Calendar.current
        
        // Calculate the target date
        guard let date = calendar.date(byAdding: timeUnit, value: number * modifier, to: referenceDate) else {
            return nil
        }
        
        // This represents a date range from the reference date to the calculated date
        // Because Chrono doesn't natively support ranges in the API, we'll return the furthest date
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
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
