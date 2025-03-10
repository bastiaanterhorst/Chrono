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
        // Pattern for "Week XX" or "Week XX of 2023" - capturing the number and optional year
        let weekNumPattern = "(?:week|wk)\\s+(?:number\\s+)?(?:#\\s*)?(\\d{1,2})(?:st|nd|rd|th)?(?:\\s*(?:of|,|in)\\s+(\\d{4}|'\\d{2}|\\d{2}))?\\b"
        
        // Pattern for "the XXth week" or "the XXth week of 2023" - capturing the number and optional year
        let ordinalWeekPattern = "the\\s+(\\d{1,2})(?:st|nd|rd|th)\\s+(?:week|wk)(?:\\s+(?:of|in)\\s+(\\d{4}|'\\d{2}|\\d{2}))?\\b"
        
        // Pattern for formal ISO format "2023-W15" - capturing year and week number
        let isoFormat1 = "(\\d{4})[-]W(\\d{1,2})\\b"
        
        // Pattern for "2023W15" - capturing year and week number
        let isoFormat2 = "(\\d{4})W(\\d{1,2})\\b"
        
        // Pattern for "W15-2023" or "W15/2023" - capturing week number and year
        let isoFormat3 = "W(\\d{1,2})[-/](\\d{4}|'\\d{2})\\b"
        
        // Pattern for just "W15" - capturing only week number
        let isoFormat4 = "W(\\d{1,2})\\b"
        
        // Combine all patterns with word boundaries
        return "\\b(?:" + 
               [weekNumPattern, ordinalWeekPattern, isoFormat1, isoFormat2, isoFormat3, isoFormat4].joined(separator: "|") + 
               ")\\b"
    }
    
    // MARK: - Extraction logic
    
    override func innerExtract(context: ParsingContext, match: TextMatch) -> Any? {
        // Get the matched text and index where it appears
        let text = match.text
        let index = match.index
        let lowercaseText = text.lowercased()
        
        // Variables to store extracted values
        var weekNumber: Int?
        var weekYear: Int?
        
        // APPROACH 1: First try to extract groups from the regex match
        // This is more accurate for our patterns with capture groups
        
        // Process "week XX" pattern
        if lowercaseText.contains("week") || lowercaseText.contains("wk") {
            // Extract the first number as week
            for i in 1..<match.captureCount {
                if let captureText = match.string(at: i), 
                   let number = Int(captureText) {
                    if weekNumber == nil && number >= 1 && number <= 53 {
                        weekNumber = number
                    } else if weekYear == nil && (number >= 1000 || (captureText.starts(with: "'") && number < 100)) {
                        weekYear = number >= 1000 ? number : 2000 + (number % 100)
                    }
                }
            }
        }
        
        // Process ISO format patterns
        else if lowercaseText.contains("w") || (lowercaseText.matches(pattern: "\\d{4}[-w]\\d{1,2}")) {
            // Extract year and week from capture groups in the regex
            for i in 1..<match.captureCount {
                if let captureText = match.string(at: i), !captureText.isEmpty {
                    let num = Int(captureText) ?? 0
                    
                    // For ISO format 2023-W15 or 2023W15
                    if lowercaseText.matches(pattern: "\\d{4}[-w]\\d{1,2}") {
                        if num >= 1000 && weekYear == nil {
                            weekYear = num
                        } else if num >= 1 && num <= 53 && weekNumber == nil {
                            weekNumber = num
                        }
                    }
                    // For W15 format
                    else if lowercaseText.starts(with: "w") {
                        if num >= 1 && num <= 53 && weekNumber == nil {
                            weekNumber = num
                        } else if (num >= 1000 || captureText.starts(with: "'")) && weekYear == nil {
                            weekYear = num >= 1000 ? num : 2000 + (num % 100)
                        }
                    }
                }
            }
        }
        
        // APPROACH 2: If capture groups didn't work, try a more direct approach
        // This is a fallback method
        
        if weekNumber == nil {
            // Extract all numbers from the text
            let digitPattern = "\\d+"
            let digitRegex = try? NSRegularExpression(pattern: digitPattern, options: [])
            let nsText = text as NSString
            let matchRange = NSRange(location: 0, length: nsText.length)
            
            let digitMatches = digitRegex?.matches(in: text, options: [], range: matchRange) ?? []
            let numbers: [Int] = digitMatches.compactMap {
                let numberRange = $0.range
                let numberSubstring = nsText.substring(with: numberRange)
                return Int(numberSubstring)
            }
            
            if numbers.count >= 1 {
                // ISO format "2023-W15" or "2023W15"
                if lowercaseText.matches(pattern: "\\d{4}[-w]\\d{1,2}") && numbers.count >= 2 {
                    weekYear = numbers[0]
                    weekNumber = numbers[1]
                }
                // Format "W15-2023" or "W15/2023"
                else if lowercaseText.matches(pattern: "w\\d{1,2}[-/]\\d{4}") && numbers.count >= 2 {
                    weekNumber = numbers[0]
                    weekYear = numbers[1]
                }
                // Format with abbreviated year "W15-'23"
                else if lowercaseText.matches(pattern: "w\\d{1,2}[-/]'\\d{2}") && numbers.count >= 2 {
                    weekNumber = numbers[0]
                    weekYear = 2000 + numbers[1]
                }
                // Just "W15"
                else if lowercaseText.matches(pattern: "\\bw\\d{1,2}\\b") {
                    weekNumber = numbers[0]
                }
                // "Week XX" with year
                else if (lowercaseText.contains("week") || lowercaseText.contains("wk")) && numbers.count >= 2 {
                    // Check the potential year
                    if numbers[1] >= 1000 {
                        weekNumber = numbers[0]
                        weekYear = numbers[1]
                    } else if numbers[0] >= 1 && numbers[0] <= 53 {
                        weekNumber = numbers[0]
                    }
                } 
                // "Week XX" without year
                else if (lowercaseText.contains("week") || lowercaseText.contains("wk")) && numbers.count >= 1 {
                    if numbers[0] >= 1 && numbers[0] <= 53 {
                        weekNumber = numbers[0]
                    }
                }
                // Last resort: try the first number if it's in week range
                else if numbers[0] >= 1 && numbers[0] <= 53 {
                    weekNumber = numbers[0]
                }
            }
        }
        
        // Validate the week number
        guard let week = weekNumber, week >= 1, week <= 53 else {
            return nil
        }
        
        // Create components for the result
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
        
        // Calculate the actual date for Monday of that week
        var calendar = Calendar(identifier: .iso8601)
        calendar.firstWeekday = 2 // Monday is the first day
        
        var dateComponents = DateComponents()
        dateComponents.weekOfYear = week
        dateComponents.yearForWeekOfYear = weekYear ?? calendar.component(.yearForWeekOfYear, from: context.reference.instant)
        dateComponents.weekday = 2 // Monday (2 in ISO 8601)
        
        if let weekStart = calendar.date(from: dateComponents) {
            // Set year, month, day as KNOWN values because they're derived from the week
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
        
        // The context.debug function can be used for debugging
        if let debug = context.options.debug as? Bool, debug {
            print("ISO Week Parser matched: \(text), week: \(week), year: \(weekYear ?? 0)")
        }
        
        return ParsedResult(
            index: index,
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