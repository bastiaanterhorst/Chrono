// ESMergeDateRangeRefiner.swift - Refiner for merging date ranges in Spanish
import Foundation

/// Refiner for merging date ranges in Spanish (e.g., "5 - 7 de enero")
public final class ESMergeDateRangeRefiner: Refiner {
    // Pattern to match hyphen, "hasta", "al", etc. with optional spaces
    private let patternBetween = "^\\s*(?:a(?:l)?|\\-|\\–|\\~|\\〜|hasta|\\?)\\s*$"
    
    // Special pattern for date ranges formatted like "5 - 7 de enero"
    private let patternRange = "^([0-9]{1,2})\\s*(?:\\-|\\–|\\~|\\〜|a|al)\\s*([0-9]{1,2})\\s+(?:de\\s+)?(\(PatternUtils.matchAnyPattern(ESConstants.MONTH_DICTIONARY)))(?:\\s+(?:de|del)\\s+([0-9]{1,4}))?$"
    
    public func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        var mergedResults = processByPattern(context: context, results: results)
        
        // Try directly parsing date range patterns
        mergedResults = processDateRangePatterns(context: context, results: mergedResults)
        
        return mergedResults
    }
    
    /// Process results by checking the text between them
    private func processByPattern(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        // Skip if there are not enough results
        if results.count <= 1 {
            return results
        }
        
        let patternRegex = try? NSRegularExpression(pattern: patternBetween, options: [])
        var mergedResults: [ParsingResult] = []
        var currentResult: ParsingResult? = nil
        
        // For all results
        for result in results {
            // If we have a current result, see if we can merge
            if let current = currentResult {
                // Check the text between results
                let text = context.text
                let from = current.index + current.text.count
                let to = result.index
                
                // Only merge if the results are close to each other
                if from <= to {
                    let textBetween = (text as NSString).substring(with: NSRange(location: from, length: to - from))
                    
                    // Check if the text between matches our pattern
                    if let regex = patternRegex,
                       regex.firstMatch(in: textBetween, options: [], range: NSRange(location: 0, length: textBetween.utf16.count)) != nil {
                        
                        // Get the combined text
                        let nsText = text as NSString
                        let endIndex = to + result.text.count
                        let newText = nsText.substring(with: NSRange(location: current.index, length: endIndex - current.index))
                        
                        // Create a merged result
                        let mergedResult = ParsingResult(
                            reference: context.reference,
                            index: current.index,
                            text: newText,
                            start: current.start,
                            end: result.start
                        )
                        
                        // If the end result already has an end component, use that instead
                        if let resultEnd = result.end {
                            mergedResult.end = resultEnd
                        }
                        
                        mergedResults.append(mergedResult)
                        currentResult = nil
                        continue
                    }
                }
            }
            
            // If no merge happened, add the previous result to the output
            if let current = currentResult {
                mergedResults.append(current)
            }
            
            // Set up the next current result
            currentResult = result
        }
        
        // Add the last result
        if let current = currentResult {
            mergedResults.append(current)
        }
        
        return mergedResults
    }
    
    /// Process date range patterns directly, like "5 - 7 de enero de 2023"
    private func processDateRangePatterns(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        var newResults = [ParsingResult]()
        let text = context.text
        
        // Check if there's a special date range pattern in the text
        if let regex = try? NSRegularExpression(pattern: patternRange, options: []),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) {
            
            // Extract components
            let nsText = text as NSString
            let startDay = Int(nsText.substring(with: match.range(at: 1))) ?? 0
            let endDay = Int(nsText.substring(with: match.range(at: 2))) ?? 0
            let monthStr = nsText.substring(with: match.range(at: 3)).lowercased()
            
            // Get month number
            if let monthNumber = ESConstants.MONTH_DICTIONARY[monthStr], startDay > 0, endDay > 0 {
                var year = 0
                
                // Get year if present
                if match.numberOfRanges > 4 && match.range(at: 4).location != NSNotFound {
                    year = Int(nsText.substring(with: match.range(at: 4))) ?? 0
                } else {
                    // Use reference year
                    let calendar = Calendar.current
                    year = calendar.component(.year, from: context.refDate)
                }
                
                // Create start component
                let startComponent = ParsingComponents(reference: context.reference)
                startComponent.assign(.day, value: startDay)
                startComponent.assign(.month, value: monthNumber)
                startComponent.assign(.year, value: year)
                
                // Create end component
                let endComponent = ParsingComponents(reference: context.reference)
                endComponent.assign(.day, value: endDay)
                endComponent.assign(.month, value: monthNumber)
                endComponent.assign(.year, value: year)
                
                // Create result
                let result = ParsingResult(
                    reference: context.reference,
                    index: match.range.location,
                    text: nsText.substring(with: match.range),
                    start: startComponent,
                    end: endComponent
                )
                
                newResults.append(result)
            }
        }
        
        // If we found a direct date range, use it, otherwise use the original results
        if !newResults.isEmpty {
            return newResults
        } else {
            return results
        }
    }
}