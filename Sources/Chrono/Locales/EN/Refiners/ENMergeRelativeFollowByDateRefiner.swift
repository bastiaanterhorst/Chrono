// ENMergeRelativeFollowByDateRefiner.swift
import Foundation

/// A refiner that merges relative date expressions with specific dates that follow
/// E.g., "Next Friday at 3pm" will merge "Next Friday" with "at 3pm"
public struct ENMergeRelativeFollowByDateRefiner: Refiner {
    public init() {}
    
    public func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        // Check if we have enough results to process
        if results.count < 2 {
            return results
        }
        
        var resultsCopy = results
        var mergedResults: [ParsingResult] = []
        
        var i = 0
        while i < resultsCopy.count {
            let currentResult = resultsCopy[i]
            let currentText = currentResult.text.lowercased()
            
            // Skip if current result is not a relative date expression
            if !isRelativeDate(text: currentText) {
                mergedResults.append(currentResult)
                i += 1
                continue
            }
            
            // Look ahead for a date that can be merged with this relative expression
            if i + 1 < resultsCopy.count {
                let nextResult = resultsCopy[i + 1]
                
                // Check if the next result follows right after the current one
                let gapBetweenResults = nextResult.index - (currentResult.index + currentResult.text.count)
                
                // Check if there's a preposition "at", "on", etc. in the gap
                let hasFollowingPreposition = hasPrepositionInGap(text: context.text, currentResult: currentResult, nextResult: nextResult)
                
                // If the next result is close enough and there's a preposition, merge them
                if gapBetweenResults <= 5 && hasFollowingPreposition {
                    let mergedResult = mergeResults(currentResult, nextResult, context: context)
                    mergedResults.append(mergedResult)
                    i += 2 // Skip the next result since we've merged it
                    continue
                }
            }
            
            mergedResults.append(currentResult)
            i += 1
        }
        
        return mergedResults
    }
    
    /// Checks if a text contains a relative date expression
    private func isRelativeDate(text: String) -> Bool {
        // Phrases like "next Friday", "last month", "this weekend", etc.
        let relativePatterns = [
            "next\\s+\\w+",
            "last\\s+\\w+",
            "this\\s+\\w+",
            "tomorrow",
            "yesterday",
            "tonight",
            "today"
        ]
        
        for pattern in relativePatterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let range = NSRange(text.startIndex..<text.endIndex, in: text)
                
                if regex.firstMatch(in: text, options: [], range: range) != nil {
                    return true
                }
            } catch {
                continue
            }
        }
        
        return false
    }
    
    /// Checks if there's a preposition in the gap between results
    private func hasPrepositionInGap(text: String, currentResult: ParsingResult, nextResult: ParsingResult) -> Bool {
        // Get the text between the current and next result
        let startIndex = currentResult.index + currentResult.text.count
        let endIndex = nextResult.index
        
        // Ensure valid indices
        guard startIndex < endIndex && startIndex < text.count && endIndex <= text.count else {
            return false
        }
        
        // Skip direct extraction and check the whole text
        let lowercasedText = text.lowercased()
        let hasPreposition = lowercasedText.contains(" at ") || 
                             lowercasedText.contains(" on ") || 
                             lowercasedText.contains(" from ") || 
                             lowercasedText.contains(" in ") ||
                             text.contains(",")
                             
        return hasPreposition
    }
    
    /// Merges two parsing results
    private func mergeResults(_ relativeResult: ParsingResult, _ timeResult: ParsingResult, context: ParsingContext) -> ParsingResult {
        // Get relative date components and time components
        let relativeDateComponents = relativeResult.start
        let timeComponents = timeResult.start
        
        // Create a new component set that combines both
        let mergedComponents = relativeDateComponents.clone()
        
        // Copy time components from the second result
        if let hour = timeComponents.get(.hour) {
            mergedComponents.assign(.hour, value: hour)
        }
        if let minute = timeComponents.get(.minute) {
            mergedComponents.assign(.minute, value: minute)
        }
        if let second = timeComponents.get(.second) {
            mergedComponents.assign(.second, value: second)
        }
        if let meridiem = timeComponents.get(.meridiem) {
            mergedComponents.assign(.meridiem, value: meridiem)
        }
        if let timezoneOffset = timeComponents.get(.timezoneOffset) {
            mergedComponents.assign(.timezoneOffset, value: timezoneOffset)
        }
        
        // Combine the text with simple concatenation
        let combinedText = relativeResult.text + " " + timeResult.text
        
        // Create a new result that spans both parts
        return context.createParsingResult(
            index: relativeResult.index,
            text: combinedText,
            start: mergedComponents,
            end: timeResult.end
        )
    }
}