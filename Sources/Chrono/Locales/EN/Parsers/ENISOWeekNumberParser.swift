// ENISOWeekNumberParser.swift - Parser for ISO week numbers in English text
import Foundation

/// Parser for ISO 8601 week numbers in English text
public class ENISOWeekNumberParser: AbstractParserWithWordBoundaryChecking {
    
    // MARK: - Pattern definitions
    
    /// Matches formal "Week xx" pattern with optional year
    private static let WEEK_PATTERN = "(?:week\\s*(?:number)?\\s*|the\\s*|\\#)?(\\d{1,2})(?:st|nd|rd|th)?(?:\\s*week(?:\\s*of)?)?(?:(?:[,\\s]*(?:in|of))?\\s*(\\d{4}|'\\d{2}|\\d{2}))?\\b"
    
    /// Matches ISO format patterns
    private static let ISO_PATTERN = "(?:(\\d{4})[-W]?(\\d{1,2}))|(?:W(\\d{1,2})[-/]?(\\d{4}|'\\d{2}|\\d{2})?)\\b"
    
    /// Matches week number patterns in text
    override func innerPattern(context: ParsingContext) -> String {
        let weekPattern = "(?:week\\s*(?:number)?\\s*|the\\s*|\\#)?(\\d{1,2})(?:st|nd|rd|th)?(?:\\s*week(?:\\s*of)?)?(?:(?:[,\\s]*(?:in|of))?\\s*(\\d{4}|'\\d{2}|\\d{2}))?\\b"
        let isoPattern = "(?:(\\d{4})[-W]?(\\d{1,2}))|(?:W(\\d{1,2})[-/]?(\\d{4}|'\\d{2}|\\d{2})?)\\b"
        
        return "\\b(?:(?:week\\s+#?|week\\s+number\\s+|the\\s+\\d{1,2}(?:st|nd|rd|th)\\s+week\\s+)?(\\d{1,2})(?:st|nd|rd|th)?\\s*(?:week)?(?:\\s*(?:of|,)\\s*(\\d{4}|'\\d{2}))?|(?:(\\d{4})[-W]?(\\d{1,2}))|(?:W(\\d{1,2})(?:[-/](\\d{4}|'\\d{2}))?))\\b"
    }
    
    // MARK: - Extraction logic
    
    override func innerExtract(context: ParsingContext, match: TextMatch) -> Any? {
        let text = match.text
        
        // We'll store the matched week number and year in these variables
        var weekNumber: Int?
        var weekYear: Int?
        
        // Extract from patterns like "Week 15" or "Week 15 of 2023"
        if let weekMatch = text.range(of: "\\b(?:week\\s+#?|week\\s+number\\s+|the\\s+\\d{1,2}(?:st|nd|rd|th)\\s+week\\s+)?(\\d{1,2})(?:st|nd|rd|th)?\\s*(?:week)?(?:\\s*(?:of|,)\\s*(\\d{4}|'\\d{2}))?\\b", options: [.regularExpression, .caseInsensitive]) {
            let matchedText = String(text[weekMatch])
            let numberRegex = "\\d{1,2}"
            let yearRegex = "\\d{4}|'\\d{2}"
            
            if let weekRange = matchedText.range(of: numberRegex, options: .regularExpression) {
                weekNumber = Int(matchedText[weekRange])
            }
            
            if let yearRange = matchedText.range(of: yearRegex, options: .regularExpression) {
                let yearText = String(matchedText[yearRange])
                if yearText.starts(with: "'") {
                    // Handle abbreviated year format '23
                    let yearSuffix = String(yearText.dropFirst())
                    if let year = Int(yearSuffix) {
                        weekYear = 2000 + year
                    }
                } else {
                    weekYear = Int(yearText)
                }
            }
        }
        
        // Extract from ISO format like "2023-W15" or "W15-2023"
        else if let isoMatch = text.range(of: "(?:(\\d{4})[-W]?(\\d{1,2}))|(?:W(\\d{1,2})(?:[-/](\\d{4}|'\\d{2}))?)", options: [.regularExpression, .caseInsensitive]) {
            let matchedText = String(text[isoMatch])
            
            // Pattern 1: "2023-W15" or "2023W15"
            if matchedText.matches(pattern: "^\\d{4}[-W]?\\d{1,2}$") {
                let components = matchedText.components(separatedBy: CharacterSet(charactersIn: "-W"))
                    .filter { !$0.isEmpty }
                
                if components.count >= 2 {
                    weekYear = Int(components[0])
                    weekNumber = Int(components[1])
                }
            }
            // Pattern 2: "W15-2023" or "W15/2023" or "W15"
            else if matchedText.matches(pattern: "^W\\d{1,2}(?:[-/](?:\\d{4}|'\\d{2}))?$") {
                let components = matchedText.dropFirst() // Drop the 'W'
                    .components(separatedBy: CharacterSet(charactersIn: "-/"))
                    .filter { !$0.isEmpty }
                
                if components.count >= 1 {
                    weekNumber = Int(components[0])
                    
                    if components.count >= 2 {
                        let yearText = components[1]
                        if yearText.starts(with: "'") {
                            // Handle abbreviated year format '23
                            let yearSuffix = String(yearText.dropFirst())
                            if let year = Int(yearSuffix) {
                                weekYear = 2000 + year
                            }
                        } else {
                            weekYear = Int(yearText)
                        }
                    }
                }
            }
        }
        
        // Validate the week number
        guard let week = weekNumber, week >= 1, week <= 53 else {
            return nil
        }
        
        // Create result
        let index = match.index
        let referenceDate = context.reference
        
        let components = ParsingComponents(reference: referenceDate)
        components.assign(.isoWeek, value: week)
        
        // If year was specified, use it; otherwise use the current year
        if let year = weekYear {
            components.assign(.isoWeekYear, value: year)
        } else {
            // Use the reference date's year if no year was specified
            let calendar = Calendar(identifier: .iso8601)
            let currentYear = calendar.component(.yearForWeekOfYear, from: referenceDate.instant)
            components.imply(.isoWeekYear, value: currentYear)
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