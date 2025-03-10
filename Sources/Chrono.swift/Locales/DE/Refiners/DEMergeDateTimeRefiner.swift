// DEMergeDateTimeRefiner.swift - Refiner to merge date and time components in German
import Foundation

/// Refiner that merges date and time components in German.
/// Handles cases like "am 5. Mai um 12 Uhr", where "am 5. Mai" and "um 12 Uhr" are separate parsed results.
public struct DEMergeDateTimeRefiner: Refiner {
    public init() {}
    
    public func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        if results.count < 2 {
            return results
        }
        
        var mergedResults: [ParsingResult] = []
        
        var i = 0
        while i < results.count {
            let result = results[i]
            
            // If this is a date (has day but no time) and there are more results after this one
            if i < results.count - 1 && 
               result.start.isCertain(.day) && 
               !result.start.isCertain(.hour) {
                
                let nextResult = results[i + 1]
                
                // And the next result starts right after this one and is a time (has hour but no day)
                if nextResult.start.isCertain(.hour) &&
                   !nextResult.start.isCertain(.day) &&
                   isAdjacentOrHasConnector(result, nextResult, context: context) {
                    
                    // Create a new merged result
                    let mergedResult = createMergedResult(result, nextResult, context: context)
                    mergedResults.append(mergedResult)
                    i += 2
                    continue
                }
            }
            
            // If no merge occurred, keep the original result
            mergedResults.append(result)
            i += 1
        }
        
        return mergedResults
    }
    
    /// Checks if two results are adjacent or have time connectors between them (like "um", "gegen")
    private func isAdjacentOrHasConnector(_ first: ParsingResult, _ second: ParsingResult, context: ParsingContext) -> Bool {
        let startIndex1 = first.index
        let endIndex1 = startIndex1 + first.text.count
        let startIndex2 = second.index
        
        // If they're directly adjacent
        if endIndex1 == startIndex2 {
            return true
        }
        
        // Allow a small gap between date and time
        if startIndex2 > endIndex1 && startIndex2 - endIndex1 <= 5 {
            // Look for connectors in the full text
            let lowercasedText = context.text.lowercased()
            
            // Check for connecting words in German
            return lowercasedText.contains("um") || 
                   lowercasedText.contains("gegen") || 
                   lowercasedText.contains("ca") || 
                   context.text.contains(",") ||
                   lowercasedText.contains("circa")
        }
        
        return false
    }
    
    /// Creates a new result that combines date and time information
    private func createMergedResult(_ dateResult: ParsingResult, _ timeResult: ParsingResult, context: ParsingContext) -> ParsingResult {
        let dateComponents = dateResult.start
        let timeComponents = timeResult.start
        
        // Start with date components
        let mergedComponents = dateComponents.clone()
        
        // Add time components
        if let hour = timeComponents.get(.hour) {
            mergedComponents.assign(.hour, value: hour)
        }
        if let minute = timeComponents.get(.minute) {
            mergedComponents.assign(.minute, value: minute)
        }
        if let second = timeComponents.get(.second) {
            mergedComponents.assign(.second, value: second)
        }
        if let millisecond = timeComponents.get(.millisecond) {
            mergedComponents.assign(.millisecond, value: millisecond)
        }
        if let meridiem = timeComponents.get(.meridiem) {
            mergedComponents.assign(.meridiem, value: meridiem)
        }
        
        // Create a text using simple concatenation
        let indexStart = dateResult.index
        let text = dateResult.text + " " + timeResult.text
        
        // Create end components if needed
        var endComponentsObj: ParsingComponents? = nil
        if let dateEnd = dateResult.end {
            endComponentsObj = dateEnd.clone()
            
            // Add time to end components too
            if let hour = timeComponents.get(.hour) {
                endComponentsObj?.assign(.hour, value: hour)
            }
            if let minute = timeComponents.get(.minute) {
                endComponentsObj?.assign(.minute, value: minute)
            }
            if let second = timeComponents.get(.second) {
                endComponentsObj?.assign(.second, value: second)
            }
            if let millisecond = timeComponents.get(.millisecond) {
                endComponentsObj?.assign(.millisecond, value: millisecond)
            }
        } else if let timeEnd = timeResult.end {
            endComponentsObj = dateComponents.clone()
            
            // Add end time components
            if let hour = timeEnd.get(.hour) {
                endComponentsObj?.assign(.hour, value: hour)
            }
            if let minute = timeEnd.get(.minute) {
                endComponentsObj?.assign(.minute, value: minute)
            }
            if let second = timeEnd.get(.second) {
                endComponentsObj?.assign(.second, value: second)
            }
            if let millisecond = timeEnd.get(.millisecond) {
                endComponentsObj?.assign(.millisecond, value: millisecond)
            }
        }
        
        return context.createParsingResult(
            index: indexStart,
            text: text,
            start: mergedComponents,
            end: endComponentsObj
        )
    }
}