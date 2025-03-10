// ENTimeUnitCasualRelativeFormatParser.swift
import Foundation

/// Parser for casual relative time expressions in English like "last week", "next month", "this year", "next 2 days", "+5 hours", etc.
public struct ENTimeUnitCasualRelativeFormatParser: Parser {
    /// Determines if abbreviations (like 'min', 'hr', 'wk') are allowed
    private let allowAbbreviations: Bool
    
    /// Time unit patterns based on abbreviation setting
    private var timeUnitsPattern: String {
        return allowAbbreviations ? timeUnitsWithAbbr : timeUnitsNoAbbr
    }
    
    /// Pattern for time units with abbreviations
    private let timeUnitsWithAbbr = "(?:(?:about|around)\\s{0,3})?(?:(?:\\d+|few|half|couple(?:\\s+of)?|several|an?|the)\\s{0,3}(?:seconds?|mins?|minutes?|hours?|days?|weeks?|months?|years?|s|m|h|d|w|mo|y)(?:\\s{0,5},?(?:\\s*and)?\\s{0,5}(?:\\d+|few|half|couple(?:\\s+of)?|several|an?|the)\\s{0,3}(?:seconds?|mins?|minutes?|hours?|days?|weeks?|months?|years?|s|m|h|d|w|mo|y)){0,10})"
    
    /// Pattern for time units without abbreviations
    private let timeUnitsNoAbbr = "(?:(?:about|around)\\s{0,3})?(?:(?:\\d+|few|half|couple(?:\\s+of)?|several|an?|the)\\s{0,3}(?:seconds?|minutes?|hours?|days?|weeks?|months?|years?)(?:\\s{0,5},?(?:\\s*and)?\\s{0,5}(?:\\d+|few|half|couple(?:\\s+of)?|several|an?|the)\\s{0,3}(?:seconds?|minutes?|hours?|days?|weeks?|months?|years?)){0,10})"
    
    /// Initialize the parser with abbreviation preference
    /// - Parameter allowAbbreviations: Whether to allow abbreviated units (s, min, hr, etc.)
    public init(allowAbbreviations: Bool = true) {
        self.allowAbbreviations = allowAbbreviations
    }
    
    public func pattern(context: ParsingContext) -> String {
        return "(\\W|^)" +
               "(this|last|past|next|after|\\+|-)\\s*" +
               "(\(timeUnitsPattern))" +
               "(?=\\W|$)"
    }
    
    /// Maps text representations of numbers to their numeric values
    /// - Parameter text: The text to parse
    /// - Returns: The numeric value
    private func parseNumberText(_ text: String) -> Double {
        let normalized = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Word-based numbers
        switch normalized {
        case "a", "an", "the":
            return 1
        case "few":
            return 3
        case "half", "half an", "half a":
            return 0.5
        case "couple", "a couple", "couple of", "a couple of":
            return 2
        case "several":
            return 7
        default:
            break
        }
        
        // Numeric values
        if let number = Double(normalized) {
            return number
        }
        
        return 0
    }
    
    /// Parses time units from text and returns a dictionary of components and values
    /// - Parameter text: The time unit text
    /// - Returns: Dictionary mapping components to values
    private func parseTimeUnits(_ text: String) -> [Component: Double]? {
        // Match time unit patterns like "2 days", "1 hour", "30 minutes"
        let pattern = "(\\d+|few|half|couple(?:\\s+of)?|several|an?|the)\\s{0,3}(seconds?|mins?|minutes?|hours?|days?|weeks?|months?|years?|s|m|h|d|w|mo|y)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        
        var components: [Component: Double] = [:]
        
        guard let regex = regex else { return nil }
        
        let nsText = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
        
        for match in matches {
            guard match.numberOfRanges >= 3 else { continue }
            
            // Safely extract texts using ranges with verification
            guard match.range(at: 1).location != NSNotFound,
                  match.range(at: 2).location != NSNotFound,
                  match.range(at: 1).location + match.range(at: 1).length <= nsText.length,
                  match.range(at: 2).location + match.range(at: 2).length <= nsText.length else {
                continue
            }
            
            let numberText = nsText.substring(with: match.range(at: 1))
            let unitText = nsText.substring(with: match.range(at: 2)).lowercased()
            
            let number = parseNumberText(numberText)
            
            // Map unit text to Component
            let component: Component
            if unitText.hasPrefix("s") {
                component = .second
            } else if unitText.hasPrefix("m") && !unitText.hasPrefix("mo") {
                component = .minute
            } else if unitText.hasPrefix("h") {
                component = .hour
            } else if unitText.hasPrefix("d") {
                component = .day
            } else if unitText.hasPrefix("w") {
                component = .weekday
            } else if unitText.hasPrefix("mo") || unitText == "month" || unitText == "months" {
                component = .month
            } else if unitText.hasPrefix("y") {
                component = .year
            } else {
                continue
            }
            
            // Add to or update components
            if let existing = components[component] {
                components[component] = existing + number
            } else {
                components[component] = number
            }
        }
        
        return components.isEmpty ? nil : components
    }
    
    /// Reverses the sign of all time units
    /// - Parameter timeUnits: The time units to reverse
    /// - Returns: Time units with reversed signs
    private func reverseTimeUnits(_ timeUnits: [Component: Double]) -> [Component: Double] {
        var reversed: [Component: Double] = [:]
        for (key, value) in timeUnits {
            reversed[key] = -value
        }
        return reversed
    }
    
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        // Extract the modifier prefix
        guard let prefix = match.string(at: 2)?.lowercased(),
              let timeUnitText = match.string(at: 3) else {
            return nil
        }
        
        // Parse the time units from the text
        guard var timeUnits = parseTimeUnits(timeUnitText) else {
            return nil
        }
        
        // Apply modifier based on prefix
        switch prefix {
        case "last", "past", "-":
            timeUnits = reverseTimeUnits(timeUnits)
        case "this":
            // For "this", we need special handling in the ParsingComponents
            return handleThisPrefix(timeUnits: timeUnits, context: context, match: match)
        case "next", "after", "+":
            // Keep time units as is (positive)
            break
        default:
            return nil
        }
        
        // Create result from time units
        return createResultFromTimeUnits(timeUnits: timeUnits, context: context, match: match)
    }
    
    /// Handles special case for "this [unit]" expressions
    /// - Parameters:
    ///   - timeUnits: The time units parsed
    ///   - context: The parsing context
    ///   - match: The text match that produced this result
    /// - Returns: A parsing result
    private func handleThisPrefix(timeUnits: [Component: Double], context: ParsingContext, match: TextMatch) -> ParsingResult? {
        guard let firstUnit = timeUnits.keys.first, timeUnits.count == 1 else {
            // "this" only works with a single unit
            return nil
        }
        
        let result = ParsingComponents(reference: context.reference)
        let referenceDate = context.reference.instant
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: referenceDate)
        
        // Special handling for weekend
        if firstUnit == .weekday && timeUnits[firstUnit] == 1 && components.weekday != nil {
            // Check if we're already on the weekend
            let weekday = components.weekday!
            if weekday == 1 || weekday == 7 {
                // Already on weekend, use current weekend
                if weekday == 1 { // Sunday
                    // Go back to Saturday
                    if let saturday = calendar.date(byAdding: .day, value: -1, to: referenceDate) {
                        let satComponents = calendar.dateComponents([.year, .month, .day], from: saturday)
                        result.assign(.year, value: satComponents.year ?? 0)
                        result.assign(.month, value: satComponents.month ?? 0)
                        result.assign(.day, value: satComponents.day ?? 0)
                    }
                } else { // Saturday
                    result.assign(.year, value: components.year ?? 0)
                    result.assign(.month, value: components.month ?? 0)
                    result.assign(.day, value: components.day ?? 0)
                }
            } else {
                // On weekday, find next Saturday
                let daysToSaturday = (7 - weekday + 6) % 7
                if let saturday = calendar.date(byAdding: .day, value: daysToSaturday, to: referenceDate) {
                    let satComponents = calendar.dateComponents([.year, .month, .day], from: saturday)
                    result.assign(.year, value: satComponents.year ?? 0)
                    result.assign(.month, value: satComponents.month ?? 0)
                    result.assign(.day, value: satComponents.day ?? 0)
                }
            }
            
            result.imply(.hour, value: 0)
            result.imply(.minute, value: 0)
            result.imply(.second, value: 0)
            return context.createParsingResult(
                index: match.index,
                text: match.matchedText,
                start: result
            )
        }
        
        // For "this [unit]", set the unit and reset smaller units
        switch firstUnit {
        case .year:
            result.assign(.year, value: components.year ?? 0)
            result.imply(.month, value: 1)
            result.imply(.day, value: 1)
            result.imply(.hour, value: 0)
            result.imply(.minute, value: 0)
            result.imply(.second, value: 0)
        case .month:
            result.assign(.year, value: components.year ?? 0)
            result.assign(.month, value: components.month ?? 0)
            result.imply(.day, value: 1)
            result.imply(.hour, value: 0)
            result.imply(.minute, value: 0)
            result.imply(.second, value: 0)
        case .weekday:
            // Beginning of current week
            let firstWeekday = calendar.firstWeekday
            let currentWeekday = components.weekday ?? 0
            let dayDiff = (firstWeekday - currentWeekday + 7) % 7
            
            if let weekStart = calendar.date(byAdding: .day, value: dayDiff, to: referenceDate) {
                let weekStartComponents = calendar.dateComponents([.year, .month, .day], from: weekStart)
                result.assign(.year, value: weekStartComponents.year ?? 0)
                result.assign(.month, value: weekStartComponents.month ?? 0)
                result.assign(.day, value: weekStartComponents.day ?? 0)
            }
            result.imply(.hour, value: 0)
            result.imply(.minute, value: 0)
            result.imply(.second, value: 0)
        case .day:
            result.assign(.year, value: components.year ?? 0)
            result.assign(.month, value: components.month ?? 0)
            result.assign(.day, value: components.day ?? 0)
            result.imply(.hour, value: 0)
            result.imply(.minute, value: 0)
            result.imply(.second, value: 0)
        case .hour:
            result.assign(.year, value: components.year ?? 0)
            result.assign(.month, value: components.month ?? 0)
            result.assign(.day, value: components.day ?? 0)
            result.assign(.hour, value: components.hour ?? 0)
            result.imply(.minute, value: 0)
            result.imply(.second, value: 0)
        case .minute:
            result.assign(.year, value: components.year ?? 0)
            result.assign(.month, value: components.month ?? 0)
            result.assign(.day, value: components.day ?? 0)
            result.assign(.hour, value: components.hour ?? 0)
            result.assign(.minute, value: components.minute ?? 0)
            result.imply(.second, value: 0)
        case .second:
            result.assign(.year, value: components.year ?? 0)
            result.assign(.month, value: components.month ?? 0)
            result.assign(.day, value: components.day ?? 0)
            result.assign(.hour, value: components.hour ?? 0)
            result.assign(.minute, value: components.minute ?? 0)
            result.assign(.second, value: components.second ?? 0)
        default:
            break
        }
        
        let parsedResult = context.createParsingResult(
            index: match.index,
            text: match.matchedText,
            start: result
        )
        parsedResult.addTag("relativeDate")
        return parsedResult
    }
    
    /// Creates a parsing result by applying time units to the reference date
    /// - Parameters:
    ///   - timeUnits: Time units to apply
    ///   - context: Parsing context
    ///   - match: The text match that produced this result
    /// - Returns: A parsing result
    private func createResultFromTimeUnits(timeUnits: [Component: Double], context: ParsingContext, match: TextMatch) -> ParsingResult? {
        let result = ParsingComponents(reference: context.reference)
        let referenceDate = context.reference.instant
        let calendar = Calendar.current
        
        // Start with reference date
        var date = referenceDate
        
        // Apply each time unit
        for (component, value) in timeUnits {
            let calendarComponent: Calendar.Component
            
            switch component {
            case .year:
                calendarComponent = .year
            case .month:
                calendarComponent = .month
            case .day:
                calendarComponent = .day
            case .weekday:
                calendarComponent = .weekOfYear
            case .hour:
                calendarComponent = .hour
            case .minute:
                calendarComponent = .minute
            case .second:
                calendarComponent = .second
            default:
                continue
            }
            
            // Apply the value
            if let newDate = calendar.date(byAdding: calendarComponent, value: Int(value), to: date) {
                date = newDate
            }
        }
        
        // Extract components from the calculated date
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        // Assign components to the result
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
        
        // Add relativeDate tag
        let parsedResult = context.createParsingResult(
            index: match.index,
            text: match.matchedText,
            start: result
        )
        parsedResult.addTag("relativeDate")
        
        // If time components were modified, add relativeDateAndTime tag
        if timeUnits.keys.contains(.hour) || 
           timeUnits.keys.contains(.minute) || 
           timeUnits.keys.contains(.second) {
            parsedResult.addTag("relativeDateAndTime")
        }
        
        return parsedResult
    }
}