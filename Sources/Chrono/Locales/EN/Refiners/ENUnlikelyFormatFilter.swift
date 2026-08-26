// ENUnlikelyFormatFilter.swift
import Foundation

/// A refiner that filters out unlikely date formats to reduce false positives
public struct ENUnlikelyFormatFilter: Refiner {
    public init() {}
    
    public func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        // Filter out results that are unlikely to be valid dates
        return results.filter { result in
            // Keep the result unless we explicitly filter it out
            
            // Get the start components
            let startComponents = result.start
            
            // Check if the result text looks like part of a URL, email, or other pattern
            if isWithinUnlikelyPattern(result: result, text: context.text) {
                return false
            }
            
            // Look for specific date formats that are likely to be false positives
            if isUnlikelyDate(components: startComponents, text: result.text) {
                return false
            }
            
            // If it's a date without time, verify the date components are valid
            let hasTimeComponent = startComponents.get(.hour) != nil
            if !hasTimeComponent && !isReasonableDate(components: startComponents) {
                return false
            }
            
            // Default to keeping the result
            return true
        }
    }
    
    /// Checks if the matched text is part of a URL, email, or other pattern where dates are unlikely
    private func isWithinUnlikelyPattern(result: ParsingResult, text: String) -> Bool {
        // Get some context around the match
        let startIdx = max(0, result.index - 10)
        let endIdx = min(text.count, result.index + result.text.count + 10)
        
        guard startIdx < endIdx && startIdx < text.count && endIdx <= text.count else {
            return false
        }
        
        let contextStartIndex = text.index(text.startIndex, offsetBy: startIdx)
        let contextEndIndex = text.index(text.startIndex, offsetBy: endIdx)
        let context = String(text[contextStartIndex..<contextEndIndex])
        
        // Check for URL pattern
        if context.contains("http://") || context.contains("https://") || context.contains("www.") {
            return true
        }
        
        // Check for email pattern
        if context.contains("@") && context.contains(".") {
            return true
        }
        
        // Check for path-like pattern. At least one side must contain a letter: "docs/readme" is a
        // path, but "12/25" is a date, and requiring a letter is what tells them apart.
        let pathPattern = try? NSRegularExpression(
            pattern: "[\\w\\-_.]*[A-Za-z][\\w\\-_.]*/[\\w\\-_.]+|[\\w\\-_.]+/[\\w\\-_.]*[A-Za-z][\\w\\-_.]*",
            options: [])
        if let matches = pathPattern?.matches(in: context, options: [], range: NSRange(location: 0, length: context.utf16.count)),
           !matches.isEmpty {
            return true
        }
        
        return false
    }
    
    /// Checks if the date components are likely to be a false match based on specific patterns
    ///
    /// This used to reject any two `/`-separated numbers under 50 as a score or ratio, which is
    /// every slash date there is — "12/25" and "4/22" included. English was the only locale unable
    /// to read the format its own users reach for first, while every day-first locale has shipped
    /// slash dates all along (and reads "3/4 cup" as a date too — the same trade, already made).
    private func isUnlikelyDate(components _: ParsingComponents, text _: String) -> Bool {
        return false
    }
    
    /// Checks if the date components form a reasonable date (not out of bounds)
    private func isReasonableDate(components: ParsingComponents) -> Bool {
        // Validate month
        if let month = components.get(.month), (month < 1 || month > 12) {
            return false
        }
        
        // Validate day based on month
        if let day = components.get(.day), let month = components.get(.month) {
            let maxDays: [Int: Int] = [
                1: 31, 2: 29, 3: 31, 4: 30, 5: 31, 6: 30, 
                7: 31, 8: 31, 9: 30, 10: 31, 11: 30, 12: 31
            ]
            
            if let maxDay = maxDays[month], day > maxDay {
                return false
            }
        }
        
        return true
    }
}
