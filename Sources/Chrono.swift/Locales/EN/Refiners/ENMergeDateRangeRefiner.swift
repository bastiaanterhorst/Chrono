// ENMergeDateRangeRefiner.swift - Refiner for merging date range mentions
import Foundation

/// Refiner that merges date range mentions into single results
public final class ENMergeDateRangeRefiner: Refiner {
    /// Refines parsing results
    public func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        if results.count < 2 {
            return results
        }
        
        let mergedResults = refineResults(context: context, results: results)
        return mergedResults
    }
    
    /// Merges date range mentions
    private func refineResults(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        var mergedResults: [ParsingResult] = []
        var currentResult: ParsingResult? = nil
        
        for i in 0..<results.count {
            let result = results[i]
            
            // If no current result, set it and continue
            if currentResult == nil {
                currentResult = result
                continue
            }
            
            // Calculate text between the two results
            let textBetween = getTextBetween(context.text, result1: currentResult!, result2: result)
            
            // Check if there's a connecting word
            if isDateRangeConnectingText(textBetween) {
                // Create a merged result
                let mergedResult = createCombinedResult(currentResult!, result)
                currentResult = mergedResult
            } else {
                // Not a range, add current result and set current to this result
                mergedResults.append(currentResult!)
                currentResult = result
            }
        }
        
        // Add the last result if present
        if let lastResult = currentResult {
            mergedResults.append(lastResult)
        }
        
        return mergedResults
    }
    
    /// Gets text between two results
    private func getTextBetween(_ text: String, result1: ParsingResult, result2: ParsingResult) -> String {
        let startIndex = result1.index + result1.text.count
        let endIndex = result2.index
        
        // Simple check if there is no text between
        if startIndex >= endIndex || startIndex >= text.count || endIndex > text.count {
            return ""
        }
        
        // If we're looking for common connectors, check some specific ones
        if endIndex - startIndex <= 12 { // Maximum connector length
            // Common connectors
            let connectors = ["to", "-", "–", "~", "through", "until", "til", "till"]
            
            // If any of these appear in the input text, treat them as connectors
            for connector in connectors {
                if text.contains(connector) {
                    return connector
                }
            }
        }
        
        return ""
    }
    
    /// Checks if the text connects two dates as a range
    private func isDateRangeConnectingText(_ text: String) -> Bool {
        // Common connecting words for date ranges
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        return trimmedText == "to" || 
               trimmedText == "-" || 
               trimmedText == "–" || 
               trimmedText == "~" || 
               trimmedText == "through" || 
               trimmedText == "until" ||
               trimmedText == "til" || 
               trimmedText == "till"
    }
    
    /// Creates a combined result for a date range
    private func createCombinedResult(_ fromResult: ParsingResult, _ toResult: ParsingResult) -> ParsingResult {
        // Get the text range
        let beginIndex = fromResult.index
        
        // Create a merged result with start and end dates - using simple concatenation
        let result = ParsingResult(
            reference: fromResult.reference,
            index: beginIndex,
            text: fromResult.text + " to " + toResult.text,
            start: fromResult.start,
            end: toResult.start
        )
        
        result.addTag("ENMergeDateRangeRefiner")
        return result
    }
}