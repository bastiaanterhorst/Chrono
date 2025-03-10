// PTMergeDateRangeRefiner.swift - Refiner to merge date ranges in Portuguese text
import Foundation

/// Refiner that merges date ranges in Portuguese text like "10 de janeiro a 15 de fevereiro"
public final class PTMergeDateRangeRefiner: Refiner {
    /// Refines parsing results to merge date ranges
    public func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        if results.count < 2 {
            return results
        }
        
        var mergedResults: [ParsingResult] = []
        var currentResult: ParsingResult? = nil
        var i = 0
        
        while i < results.count {
            // Check if this is a new potential range start
            if currentResult == nil {
                currentResult = results[i]
                i += 1
                continue
            }
            
            // Check if this could be a range "START-END"
            let result1 = currentResult!
            let result2 = results[i]
            
            // Only merge if both results have certain day and month
            guard result1.start.isCertain(.day) && result1.start.isCertain(.month) &&
                  result2.start.isCertain(.day) && result2.start.isCertain(.month) else {
                mergedResults.append(result1)
                currentResult = result2
                i += 1
                continue
            }
            
            // Check for a range connector between the dates
            let distance = result2.index - (result1.index + result1.text.count)
            
            // Only check for range indicators if the results are reasonably close
            if distance <= 0 || distance > 20 {
                mergedResults.append(result1)
                currentResult = result2
                i += 1
                continue
            }
            
            // Get text between results
            let startIndex = result1.index + result1.text.count
            let endIndex = result2.index
            
            guard startIndex < endIndex, 
                  startIndex >= 0, 
                  endIndex <= context.text.count else {
                mergedResults.append(result1)
                currentResult = result2
                i += 1
                continue
            }
            
            // Get text between the two results safely
            let startStringIndex = context.text.index(context.text.startIndex, offsetBy: startIndex)
            let endStringIndex = context.text.index(context.text.startIndex, offsetBy: endIndex)
            let textBetween = String(context.text[startStringIndex..<endStringIndex])
            
            // Check for range indicators like "a", "até", "-", etc.
            let hasRangeIndicator = textBetween.range(of: "\\s*(a|até|\\-|ao?|para)\\s*", options: [.regularExpression]) != nil
            
            if hasRangeIndicator {
                // Create a merged result
                let start = result1.start
                let end = result2.start
                
                // Use simple concatenation with "-" as the connector
                let mergedText = result1.text + " - " + result2.text
                
                let newResult = ParsingResult(
                    reference: context.reference,
                    index: result1.index,
                    text: String(mergedText),
                    start: start,
                    end: end
                )
                
                newResult.addTag("PTMergeDateRangeRefiner")
                currentResult = nil
                mergedResults.append(newResult)
                i += 1
            } else {
                mergedResults.append(result1)
                currentResult = result2
                i += 1
            }
        }
        
        // Don't forget the last result if we didn't merge it
        if let lastResult = currentResult {
            mergedResults.append(lastResult)
        }
        
        return mergedResults
    }
}