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
    
    /// Gets the text actually between two results (so a connector check can't false-positive on a
    /// substring of the input — e.g. the "to" inside "tomorrow" must not turn "tomorrow bla 3pm"
    /// into a "tomorrow → 3pm" range that drops the time).
    private func getTextBetween(_ text: String, result1: ParsingResult, result2: ParsingResult) -> String {
        let ns = text as NSString
        let startIndex = min(result1.index + (result1.text as NSString).length, ns.length)
        let endIndex = min(result2.index, ns.length)
        guard endIndex > startIndex else { return "" }
        return ns.substring(with: NSRange(location: startIndex, length: endIndex - startIndex))
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