// DEMergeDateRangeRefiner.swift - Refiner to merge date ranges in German
import Foundation

/// Refiner that merges date ranges in German.
/// Handles cases like "vom 1. bis 3. Mai", or "1-3. Mai 2021"
public struct DEMergeDateRangeRefiner: Refiner {
    public init() {}
    
    public func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        if results.count < 2 {
            return results
        }
        
        var mergedResults: [ParsingResult] = []
        
        var i = 0
        while i < results.count {
            let result = results[i]
            
            // If this is a date and there are more results after this one
            if i < results.count - 1 {
                let nextResult = results[i + 1]
                
                // Check if they can be merged as a range
                if isDateRangeCandidates(result, nextResult, context: context) {
                    // Create a new merged result
                    let mergedResult = createMergedResult(result, nextResult, context: context)
                    mergedResults.append(mergedResult)
                    i += 2 // Skip the next result since we've merged it
                    continue
                }
            }
            
            // If no merge occurred, keep the original result
            mergedResults.append(result)
            i += 1
        }
        
        return mergedResults
    }
    
    /// Checks if two results can be merged into a date range
    private func isDateRangeCandidates(_ first: ParsingResult, _ second: ParsingResult, context: ParsingContext) -> Bool {
        // Both need to have start components with at least a day
        if !first.start.isCertain(.day) || !second.start.isCertain(.day) {
            return false
        }
        
        // They should be close to each other in the text
        let startIndex1 = first.index
        let endIndex1 = startIndex1 + first.text.count
        let startIndex2 = second.index
        
        // If they're too far apart, they're probably not a range
        if startIndex2 - endIndex1 > 5 {
            return false
        }
        
        // Check if the full text contains German range indicators
        let containsBis = context.text.lowercased().contains("bis")
        let containsDash = context.text.contains("-") || context.text.contains("–")
        let containsZum = context.text.lowercased().contains("zum")
        
        // Check if there's a range connector
        return containsBis || containsDash || containsZum
    }
    
    /// Creates a new result that merges two dates into a range
    private func createMergedResult(_ firstResult: ParsingResult, _ secondResult: ParsingResult, context: ParsingContext) -> ParsingResult {
        let startComponents = firstResult.start
        let endComponents = secondResult.start
        
        // When creating a range, if the end is missing some components (like year or month),
        // copy them from the start
        let endComponentsAdjusted = endComponents.clone()
        
        // Copy year from start if not present in end
        if startComponents.isCertain(.year) && !endComponents.isCertain(.year) {
            if let year = startComponents.get(.year) {
                endComponentsAdjusted.assign(.year, value: year)
            }
        }
        
        // Copy month from start if not present in end
        if startComponents.isCertain(.month) && !endComponents.isCertain(.month) {
            if let month = startComponents.get(.month) {
                endComponentsAdjusted.assign(.month, value: month)
            }
        }
        
        // Create a text by simple concatenation rather than using string indices
        let indexStart = firstResult.index
        let text = firstResult.text + " bis " + secondResult.text
        
        // Create the merged result with a date range
        return context.createParsingResult(
            index: indexStart,
            text: text,
            start: startComponents,
            end: endComponentsAdjusted
        )
    }
}