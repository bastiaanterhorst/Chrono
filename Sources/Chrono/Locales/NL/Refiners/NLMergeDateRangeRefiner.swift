// NLMergeDateRangeRefiner.swift - Refiner for date ranges in Dutch
import Foundation

/// Refiner for merging date ranges in Dutch texts (e.g., "van 1 januari tot 3 januari")
final class NLMergeDateRangeRefiner: Refiner {
    // Pattern for date range connectors
    private let PATTERN = "^\\s*(?:(?:van|vanaf)\\s*)?(?:tot|tot\\s+aan|\\-|\\–|\\s*t\\/m|\\s*tm)\\s*$"
    
    func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        if results.count < 2 {
            return results
        }
        
        var mergedResults: [ParsingResult] = []
        var i = 0
        
        while i < results.count {
            let currentResult = results[i]
            
            // Skip if this result already has an end date or is not a date
            if currentResult.end != nil || !isDateResult(currentResult) {
                mergedResults.append(currentResult)
                i += 1
                continue
            }
            
            // Look for a connector after this date
            let textBetween = getTextBetweenResults(context, currentResult, i + 1 < results.count ? results[i + 1] : nil)
            if textBetween == nil || i + 1 >= results.count {
                mergedResults.append(currentResult)
                i += 1
                continue
            }
            
            // Check if the text between matches a date connector pattern
            let regex = try? NSRegularExpression(pattern: PATTERN, options: [])
            guard let matches = regex?.matches(in: textBetween!, options: [], range: NSRange(location: 0, length: textBetween!.count)),
                  !matches.isEmpty else {
                mergedResults.append(currentResult)
                i += 1
                continue
            }
            
            // Get the next result as potential end date
            let nextResult = results[i + 1]
            
            // Check if the next result is a compatible date
            if isDateResult(nextResult) && areCompatibleDateResults(currentResult, nextResult) {
                let start = currentResult.start
                let end = nextResult.start
                
                // Create a new range result
                let rangeStart = currentResult.index
                let rangeEnd = nextResult.index + nextResult.text.count
                let rangeText = (context.text as NSString).substring(with: NSRange(location: rangeStart, length: rangeEnd - rangeStart))
                
                let mergedResult = context.createParsingResult(
                    index: rangeStart,
                    text: rangeText,
                    start: start,
                    end: end
                )
                
                mergedResults.append(mergedResult)
                
                // Skip both the current and next results
                i += 2
                continue
            }
            
            // If no merging was possible, keep the current result as is
            mergedResults.append(currentResult)
            i += 1
        }
        
        return mergedResults
    }
    
    /// Gets the text between two parsing results
    private func getTextBetweenResults(_ context: ParsingContext, _ currentResult: ParsingResult, _ nextResult: ParsingResult?) -> String? {
        let currentEnd = currentResult.index + currentResult.text.count
        guard let nextStart = nextResult?.index else { return nil }
        
        // If the next result starts at or before the end of the current result, there's no text between
        if nextStart <= currentEnd {
            return nil
        }
        
        // Extract the text between the results
        let nsText = context.text as NSString
        return nsText.substring(with: NSRange(location: currentEnd, length: nextStart - currentEnd))
    }
    
    /// Checks if a result is a date (has at least one date component)
    private func isDateResult(_ result: ParsingResult) -> Bool {
        return result.start.isCertain(.day) || result.start.isCertain(.month) || result.start.isCertain(.year) || result.start.isCertain(.weekday)
    }
    
    /// Checks if two date results are compatible for forming a range
    private func areCompatibleDateResults(_ result1: ParsingResult, _ result2: ParsingResult) -> Bool {
        // Both should be date components
        if !isDateResult(result1) || !isDateResult(result2) {
            return false
        }
        
        // Both should have the same level of specificity
        let day1 = result1.start.isCertain(.day)
        let day2 = result2.start.isCertain(.day)
        if day1 != day2 {
            return false
        }
        
        let month1 = result1.start.isCertain(.month)
        let month2 = result2.start.isCertain(.month)
        if month1 != month2 {
            return false
        }
        
        let year1 = result1.start.isCertain(.year)
        let year2 = result2.start.isCertain(.year)
        if year1 != year2 {
            return false
        }
        
        // End date should be after start date
        guard let startDate = result1.start.date(), let endDate = result2.start.date() else {
            return false
        }
        
        return endDate > startDate
    }
}