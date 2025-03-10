// ENRelativeWeekParser.swift - Parser for relative week expressions in English
import Foundation

/// Parser for relative week expressions in English text
public class ENRelativeWeekParser: AbstractParserWithWordBoundaryChecking, @unchecked Sendable {
    
    /// Matches relative week expressions in text
    override func innerPattern(context: ParsingContext) -> String {
        let patternThis = "this\\s+week"
        let patternLast = "last\\s+week"
        let patternNext = "next\\s+week"
        let patternWeeksAgo = "(\\d+)\\s+weeks?\\s+ago"
        let patternInWeeks = "in\\s+(\\d+)\\s+weeks?"
        let patternBeforeLast = "the\\s+week\\s+before\\s+last"
        let patternAfterNext = "the\\s+week\\s+after\\s+next"
        
        return "\\b(?:" +
            [patternThis, patternLast, patternNext, patternWeeksAgo, patternInWeeks, patternBeforeLast, patternAfterNext].joined(separator: "|") +
            ")\\b"
    }
    
    override func innerExtract(context: ParsingContext, match: TextMatch) -> Any? {
        let text = match.text.lowercased()
        let referenceDate = context.reference.instant
        let calendar = Calendar(identifier: .iso8601)
        
        // Calculate the date based on the matched pattern
        var targetDate: Date?
        var weekOffset = 0
        
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
        } else if text.matches(pattern: "(\\d+)\\s+weeks?\\s+ago") {
            if let weeksAgoRange = text.range(of: "\\d+", options: .regularExpression) {
                if let weeksAgo = Int(text[weeksAgoRange]) {
                    weekOffset = -weeksAgo
                }
            }
        } else if text.matches(pattern: "in\\s+(\\d+)\\s+weeks?") {
            if let weeksLaterRange = text.range(of: "\\d+", options: .regularExpression) {
                if let weeksLater = Int(text[weeksLaterRange]) {
                    weekOffset = weeksLater
                }
            }
        }
        
        // Apply the week offset to the reference date
        targetDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: referenceDate)
        
        guard let finalDate = targetDate else {
            return nil
        }
        
        // Create a components object with the ISO week number
        let targetWeek = calendar.component(.weekOfYear, from: finalDate)
        let targetWeekYear = calendar.component(.yearForWeekOfYear, from: finalDate)
        
        let components = ParsingComponents(reference: context.reference)
        components.assign(.isoWeek, value: targetWeek)
        components.assign(.isoWeekYear, value: targetWeekYear)
        
        // Set to Monday of that week (first day of ISO week)
        var dateComponents = DateComponents()
        dateComponents.weekOfYear = targetWeek
        dateComponents.yearForWeekOfYear = targetWeekYear
        dateComponents.weekday = 2 // Monday (2 in ISO 8601)
        dateComponents.hour = 12 // Noon
        
        if let weekStart = calendar.date(from: dateComponents) {
            // Extract the components from the date and assign them
            // These are KNOWN values because they're derived directly from the week
            let dayComponents = calendar.dateComponents([.year, .month, .day], from: weekStart)
            components.assign(.year, value: dayComponents.year!)
            components.assign(.month, value: dayComponents.month!)
            components.assign(.day, value: dayComponents.day!)
            
            // Time components are implied
            components.imply(.hour, value: 12)
            components.imply(.minute, value: 0)
            components.imply(.second, value: 0)
            components.imply(.millisecond, value: 0)
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