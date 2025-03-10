// ENRelativeWeekParser.swift - Parser for relative week expressions in English
import Foundation

/// Parser for relative week expressions in English text
public class ENRelativeWeekParser: AbstractParserWithWordBoundaryChecking, @unchecked Sendable {
    
    /// Matches relative week expressions in text
    override func innerPattern(context: ParsingContext) -> String {
        // Basic patterns
        let patternThis = "this\\s+week"
        let patternLast = "last\\s+week"
        let patternNext = "next\\s+week"
        
        // Patterns with numbers
        let patternWeeksAgo = "(\\d+)\\s+weeks?\\s+ago"
        let patternInWeeks = "in\\s+(\\d+)\\s+weeks?"
        let patternWeeksFromNow = "(\\d+)\\s+weeks?\\s+from\\s+now"
        
        // Complex patterns
        let patternBeforeLast = "the\\s+week\\s+before\\s+last"
        let patternAfterNext = "the\\s+week\\s+after\\s+next"
        
        // Combined pattern with word boundaries
        return "\\b(?:" +
            [patternThis, patternLast, patternNext, 
             patternWeeksAgo, patternInWeeks, patternWeeksFromNow,
             patternBeforeLast, patternAfterNext].joined(separator: "|") +
            ")\\b"
    }
    
    override func innerExtract(context: ParsingContext, match: TextMatch) -> Any? {
        let text = match.text.lowercased()
        let referenceDate = context.reference.instant
        let calendar = Calendar(identifier: .iso8601)
        
        // Calculate the week offset based on the matched pattern
        var weekOffset = 0
        
        // Basic relative patterns
        if text.contains("this week") {
            weekOffset = 0
        } else if text.contains("last week") {
            weekOffset = -1
        } else if text.contains("next week") {
            weekOffset = 1
        } else if text.contains("before last") {
            weekOffset = -2
        } else if text.contains("after next") {
            weekOffset = 2
        } 
        // Extract number from "X weeks ago" pattern
        else if text.matches(pattern: "(\\d+)\\s+weeks?\\s+ago") {
            // Try to extract the number from capture groups first
            var weeksAgo: Int? = nil
            for i in 1..<match.captureCount {
                if let captureText = match.string(at: i), let number = Int(captureText) {
                    weeksAgo = number
                    break
                }
            }
            
            // Fallback extraction method
            if weeksAgo == nil, let weeksAgoRange = text.range(of: "\\d+", options: .regularExpression) {
                weeksAgo = Int(text[weeksAgoRange])
            }
            
            if let weeksAgo = weeksAgo {
                weekOffset = -weeksAgo
            }
        } 
        // Extract number from "in X weeks" pattern
        else if text.matches(pattern: "in\\s+(\\d+)\\s+weeks?") {
            // Try to extract the number from capture groups first
            var weeksLater: Int? = nil
            for i in 1..<match.captureCount {
                if let captureText = match.string(at: i), let number = Int(captureText) {
                    weeksLater = number
                    break
                }
            }
            
            // Fallback extraction method
            if weeksLater == nil, let weeksLaterRange = text.range(of: "\\d+", options: .regularExpression) {
                weeksLater = Int(text[weeksLaterRange])
            }
            
            if let weeksLater = weeksLater {
                weekOffset = weeksLater
            }
        }
        // Extract number from "X weeks from now" pattern
        else if text.matches(pattern: "(\\d+)\\s+weeks?\\s+from\\s+now") {
            // Try to extract the number from capture groups first
            var weeksLater: Int? = nil
            for i in 1..<match.captureCount {
                if let captureText = match.string(at: i), let number = Int(captureText) {
                    weeksLater = number
                    break
                }
            }
            
            // Fallback extraction method
            if weeksLater == nil, let weeksLaterRange = text.range(of: "\\d+", options: .regularExpression) {
                weeksLater = Int(text[weeksLaterRange])
            }
            
            if let weeksLater = weeksLater {
                weekOffset = weeksLater
            }
        }
        
        // Apply the week offset to the reference date
        guard let targetDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: referenceDate) else {
            return nil
        }
        
        // Create a components object with the ISO week number
        let targetWeek = calendar.component(.weekOfYear, from: targetDate)
        let targetWeekYear = calendar.component(.yearForWeekOfYear, from: targetDate)
        
        let components = ParsingComponents(reference: context.reference)
        
        // Week number and year are KNOWN values since this is a week-specific parser
        components.assign(.isoWeek, value: targetWeek)
        components.assign(.isoWeekYear, value: targetWeekYear)
        
        // Set to Monday of that week (first day of ISO week)
        var dateComponents = DateComponents()
        dateComponents.weekOfYear = targetWeek
        dateComponents.yearForWeekOfYear = targetWeekYear
        dateComponents.weekday = 2 // Monday (2 in ISO 8601)
        
        if let weekStart = calendar.date(from: dateComponents) {
            // Extract the components from the date and assign them as KNOWN values
            // since they're directly derived from the week number
            let dayComponents = calendar.dateComponents([.year, .month, .day], from: weekStart)
            components.assign(.year, value: dayComponents.year!)
            components.assign(.month, value: dayComponents.month!)
            components.assign(.day, value: dayComponents.day!)
            
            // Time components are implied - we default to noon
            components.imply(.hour, value: 12)
            components.imply(.minute, value: 0)
            components.imply(.second, value: 0)
            components.imply(.millisecond, value: 0)
        }
        
        // Debug output if enabled
        if let debug = context.options.debug as? Bool, debug {
            print("Relative Week Parser matched: \(text), offset: \(weekOffset), target week: \(targetWeek) of \(targetWeekYear)")
        }
        
        return ParsedResult(
            index: match.index,
            text: match.text,
            start: components.toPublicDate()
        )
    }
}

// Helper extension for string matching
fileprivate extension String {
    func matches(pattern: String) -> Bool {
        return self.range(of: pattern, options: .regularExpression) != nil
    }
}