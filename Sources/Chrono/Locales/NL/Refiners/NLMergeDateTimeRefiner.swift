// NLMergeDateTimeRefiner.swift - Refiner for merging date and time in Dutch
import Foundation

/// Refiner for merging date and time components in Dutch texts
final class NLMergeDateTimeRefiner: Refiner {
    // Patterns for connecting words between date and time
    private let PATTERN = "^\\s*(?:om|om\\s+ongeveer|ongeveer\\s+om|ongeveer|\\,|\\-|om|om\\s+ongeveer|ongeveer\\s+om|ongeveer)?\\s*$"
    
    func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        if results.count < 2 {
            return results
        }
        
        var mergedResults: [ParsingResult] = []
        var currentResults = results
        
        var i = 0
        while i < currentResults.count {
            // Get the date component
            let currentResult = currentResults[i]
            let currentText = (context.text as NSString).substring(with: NSRange(location: currentResult.index, length: currentResult.text.count))
            let hasDate = isDateOnlyComponent(currentResult)
            
            // If this is not a date-only component, consider it standalone
            if !hasDate {
                mergedResults.append(currentResult)
                i += 1
                continue
            }
            
            // Look for the next component after this date
            let textAfterLoc = currentResult.index + currentResult.text.count
            let textAfter = (context.text as NSString).substring(from: textAfterLoc)
            
            // Look for potential connecting words
            let regex = try? NSRegularExpression(pattern: PATTERN, options: [])
            let matches = regex?.matches(in: textAfter, options: [], range: NSRange(location: 0, length: textAfter.count))
            
            // If we have a match for connecting words and there is a next result
            if let match = matches?.first, i + 1 < currentResults.count {
                let connectingText = (textAfter as NSString).substring(with: match.range)
                let nextResult = currentResults[i + 1]
                
                // Distance from end of current result to start of next result
                let distanceToNextResult = nextResult.index - (currentResult.index + currentResult.text.count)
                
                // If the connecting text bridges the two results exactly
                if distanceToNextResult == connectingText.count && isTimeOnlyComponent(nextResult) {
                    
                    // We can merge these components
                    let combinedText = currentText + connectingText + nextResult.text
                    
                    let mergedResult = context.createParsingResult(
                        index: currentResult.index,
                        text: combinedText,
                        start: mergeDateTimeComponents(currentResult.start, nextResult.start)
                    )
                    
                    mergedResults.append(mergedResult)
                    
                    // Skip both the current and next results
                    i += 2
                    continue
                }
            }
            
            // If no merging was possible, keep the result as is
            mergedResults.append(currentResult)
            i += 1
        }
        
        return mergedResults
    }
    
    /// Checks if the result has only date components
    private func isDateOnlyComponent(_ result: ParsingResult) -> Bool {
        // Check if this component has only date-related values
        let hasDate = result.start.isCertain(.day) || result.start.isCertain(.month) || result.start.isCertain(.year) || result.start.isCertain(.weekday)
        let hasTime = result.start.isCertain(.hour) || result.start.isCertain(.minute) || result.start.isCertain(.second)
        
        return hasDate && !hasTime
    }
    
    /// Checks if the result has only time components
    private func isTimeOnlyComponent(_ result: ParsingResult) -> Bool {
        // Check if this component has only time-related values
        let hasDate = result.start.isCertain(.day) || result.start.isCertain(.month) || result.start.isCertain(.year) || result.start.isCertain(.weekday)
        let hasTime = result.start.isCertain(.hour) || result.start.isCertain(.minute) || result.start.isCertain(.second)
        
        return !hasDate && hasTime
    }
    
    /// Merges date and time components
    private func mergeDateTimeComponents(_ dateComponent: ParsingComponents, _ timeComponent: ParsingComponents) -> ParsingComponents {
        let merged = dateComponent.clone()
        
        // Copy time components from the time result
        if let hour = timeComponent.get(.hour) {
            merged.assign(.hour, value: hour)
        }
        
        if let minute = timeComponent.get(.minute) {
            merged.assign(.minute, value: minute)
        }
        
        if let second = timeComponent.get(.second) {
            merged.assign(.second, value: second)
        }
        
        // Copy meridiem if present
        if let meridiem = timeComponent.get(.meridiem) {
            merged.assign(.meridiem, value: meridiem)
        }
        
        // Copy timezone if present
        if let timezoneOffset = timeComponent.get(.timezoneOffset) {
            merged.assign(.timezoneOffset, value: timezoneOffset)
        }
        
        return merged
    }
}