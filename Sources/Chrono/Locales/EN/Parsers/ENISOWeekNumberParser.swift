// ENISOWeekNumberParser.swift - Parser for ISO week numbers in English text
import Foundation

/// Parser for ISO 8601 week numbers in English text
public class ENISOWeekNumberParser: AbstractParserWithWordBoundaryChecking, @unchecked Sendable {
    
    // MARK: - Pattern definitions
    
    /// Matches formal "Week xx" pattern with optional year
    private static let WEEK_PATTERN = "(?:week\\s*(?:number)?\\s*|the\\s*|\\#)?(\\d{1,2})(?:st|nd|rd|th)?(?:\\s*week(?:\\s*of)?)?(?:(?:[,\\s]*(?:in|of))?\\s*(\\d{4}|'\\d{2}|\\d{2}))?\\b"
    
    /// Matches ISO format patterns
    private static let ISO_PATTERN = "(?:(\\d{4})[-W]?(\\d{1,2}))|(?:W(\\d{1,2})[-/]?(\\d{4}|'\\d{2}|\\d{2})?)\\b"
    
    /// Matches week number patterns in text
    override func innerPattern(context: ParsingContext) -> String {
        // Pattern for "Week XX" or "Week XX of 2023"
        let weekNumPattern = "(?:(?:week|wk)\\s+(?:number\\s+)?(?:#\\s*)?|the\\s+)(\\d{1,2})(?:st|nd|rd|th)?(?:\\s*(?:week|wk))?(?:\\s*(?:of|,|in)\\s+(\\d{4}|'\\d{2}|\\d{2}))?\\b"
        
        // Pattern for "the XXth week" or "the XXth week of 2023"
        let ordinalWeekPattern = "the\\s+(\\d{1,2})(?:st|nd|rd|th)\\s+(?:week|wk)(?:\\s+(?:of|in)\\s+(\\d{4}|'\\d{2}|\\d{2}))?\\b"
        
        // Pattern for formal ISO format "2023-W15" or "2023W15"
        let isoFormat1 = "(\\d{4})[-W](\\d{1,2})\\b"
        let isoFormat2 = "(\\d{4})W(\\d{1,2})\\b"
        
        // Pattern for "W15-2023" or "W15/2023"
        let isoFormat3 = "W(\\d{1,2})[-/](\\d{4}|'\\d{2})\\b"
        
        // Pattern for just "W15"
        let isoFormat4 = "W(\\d{1,2})\\b"
        
        // Combine all patterns
        return "\\b(?:" + 
               [weekNumPattern, ordinalWeekPattern, isoFormat1, isoFormat2, isoFormat3, isoFormat4].joined(separator: "|") + 
               ")\\b"
    }
    
    // MARK: - Extraction logic
    
    override func innerExtract(context: ParsingContext, match: TextMatch) -> Any? {
        // Get the matched text
        let text = match.text
        let lowercaseText = text.lowercased()
        
        // We'll store the matched week number and year in these variables
        var weekNumber: Int?
        var weekYear: Int?
        
        // Used for capturing all digits in the text
        let digitPattern = "\\d+"
        let digitRegex = try? NSRegularExpression(pattern: digitPattern, options: [])
        let nsText = text as NSString
        let matchRange = NSRange(location: 0, length: nsText.length)
        
        // Find all numbers in the text
        let digitMatches = digitRegex?.matches(in: text, options: [], range: matchRange) ?? []
        let numbers: [Int] = digitMatches.compactMap {
            let numberRange = $0.range
            let numberSubstring = nsText.substring(with: numberRange)
            return Int(numberSubstring)
        }
        
        // Pattern matching approaches based on text format
        
        // Check for ISO format "2023-W15" or "2023W15"
        if lowercaseText.matches(pattern: "\\d{4}[-w]\\d{1,2}") || lowercaseText.matches(pattern: "\\d{4}w\\d{1,2}") {
            if numbers.count >= 2 {
                weekYear = numbers[0]
                weekNumber = numbers[1]
            }
        }
        
        // Check for format "W15-2023" or "W15/2023"
        else if lowercaseText.matches(pattern: "w\\d{1,2}[-/]\\d{4}") || lowercaseText.matches(pattern: "w\\d{1,2}[-/]'\\d{2}") {
            if numbers.count >= 2 {
                weekNumber = numbers[0]
                
                // Handle year format
                if lowercaseText.contains("'") && numbers[1] < 100 {
                    weekYear = 2000 + numbers[1]  // For '23 format
                } else {
                    weekYear = numbers[1]
                }
            }
        }
        
        // Check for format "W15"
        else if lowercaseText.matches(pattern: "\\bw\\d{1,2}\\b") {
            if numbers.count >= 1 {
                weekNumber = numbers[0]
            }
        }
        
        // Check for various "Week XX" formats
        else if lowercaseText.contains("week") || lowercaseText.contains("wk") {
            // Find week number
            if numbers.count >= 1 {
                weekNumber = numbers[0]
            }
            
            // Check for year if present
            if numbers.count >= 2 && !lowercaseText.matches(pattern: "\\d+\\s*weeks?") { // Avoid "3 weeks" pattern
                let potentialYear = numbers[1]
                if potentialYear >= 1000 || (lowercaseText.contains("'") && potentialYear < 100) {
                    weekYear = potentialYear >= 1000 ? potentialYear : 2000 + potentialYear
                }
            }
        }
        
        // If we couldn't extract a week number, try to just get the first number 
        // This is for patterns like "Week 15"
        if weekNumber == nil && numbers.count >= 1 {
            weekNumber = numbers[0]
        }
        
        // Validate the week number
        guard let week = weekNumber, week >= 1, week <= 53 else {
            return nil
        }
        
        // Create components and set values properly
        let components = ParsingComponents(reference: context.reference)
        
        // Week is always a KNOWN value when using this parser, never implied
        components.assign(.isoWeek, value: week)
        
        // If year was specified, it's a KNOWN value; otherwise imply from reference date
        if let year = weekYear {
            components.assign(.isoWeekYear, value: year)
        } else {
            // Use the reference date's year if no year was specified
            let calendar = Calendar(identifier: .iso8601)
            let currentYear = calendar.component(.yearForWeekOfYear, from: context.reference.instant)
            components.imply(.isoWeekYear, value: currentYear)
        }
        
        // Calculate the start of the week (Monday)
        var calendar = Calendar(identifier: .iso8601)
        calendar.firstWeekday = 2 // Monday is the first day
        
        var dateComponents = DateComponents()
        dateComponents.weekOfYear = week
        dateComponents.yearForWeekOfYear = weekYear ?? calendar.component(.yearForWeekOfYear, from: context.reference.instant)
        dateComponents.weekday = 2 // Monday (2 in ISO 8601)
        
        if let weekStart = calendar.date(from: dateComponents) {
            // Set year, month, day as KNOWN values (derived from week)
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
            text: text,
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