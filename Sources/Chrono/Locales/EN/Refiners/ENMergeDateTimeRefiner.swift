// ENMergeDateTimeRefiner.swift - Refiner to merge separate date and time components
import Foundation

/// Refiner that merges separate date and time mentions into a single result
public final class ENMergeDateTimeRefiner: Refiner {
    /// Merges adjacent date and time results
    public func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        if results.count < 2 {
            return results
        }
        
        var mergedResults: [ParsingResult] = []
        var currentResult = results[0]
        
        for i in 1..<results.count {
            let nextResult = results[i]
            
            // Check if we should merge these results
            if shouldMerge(currentResult: currentResult, nextResult: nextResult) {
                currentResult = mergeResults(dateResult: currentResult, timeResult: nextResult)
            } else {
                mergedResults.append(currentResult)
                currentResult = nextResult
            }
        }
        
        mergedResults.append(currentResult)
        return mergedResults
    }
    
    /// Determines if two results should be merged
    /// - Parameters:
    ///   - currentResult: The first result
    ///   - nextResult: The next result
    /// - Returns: True if the results should be merged
    private func shouldMerge(currentResult: ParsingResult, nextResult: ParsingResult) -> Bool {
        // Only merge if they're sequential in the text
        let endOfFirst = currentResult.index + currentResult.text.count
        let maxDistance = 5 // Allow up to 5 characters between date and time
        
        if nextResult.index > endOfFirst + maxDistance {
            return false
        }
        
        // Check if one has date components and the other has time components
        let firstHasDate = currentResult.start.isCertain(.day) || currentResult.start.isCertain(.month) || currentResult.start.isCertain(.year)
        let firstHasTime = currentResult.start.isCertain(.hour)
        
        let secondHasDate = nextResult.start.isCertain(.day) || nextResult.start.isCertain(.month) || nextResult.start.isCertain(.year)
        let secondHasTime = nextResult.start.isCertain(.hour)
        
        return (firstHasDate && !firstHasTime && secondHasTime && !secondHasDate) ||
               (firstHasTime && !firstHasDate && secondHasDate && !secondHasTime)
    }
    
    /// Merges date and time components
    /// - Parameters:
    ///   - dateResult: The result with date information
    ///   - timeResult: The result with time information
    /// - Returns: A merged result
    private func mergeResults(dateResult: ParsingResult, timeResult: ParsingResult) -> ParsingResult {
        let dateIsFirst = dateResult.index < timeResult.index
        
        let firstResult = dateIsFirst ? dateResult : timeResult
        let secondResult = dateIsFirst ? timeResult : dateResult
        
        let mergedText = getTextBetween(first: firstResult, second: secondResult)
        let mergedIndex = firstResult.index
        
        // Determine which result has date and which has time
        let dateComponents: ParsingComponents
        let timeComponents: ParsingComponents
        
        if dateResult.start.isCertain(.day) || dateResult.start.isCertain(.month) || dateResult.start.isCertain(.year) {
            dateComponents = dateResult.start
            timeComponents = timeResult.start
        } else {
            dateComponents = timeResult.start
            timeComponents = dateResult.start
        }
        
        // Create new components with merged date and time
        let mergedComponents = ParsingComponents(reference: dateResult.reference)
        
        // Copy date components
        if let day = dateComponents.get(.day) {
            mergedComponents.assign(.day, value: day)
        }
        
        if let month = dateComponents.get(.month) {
            mergedComponents.assign(.month, value: month)
        }
        
        if let year = dateComponents.get(.year) {
            mergedComponents.assign(.year, value: year)
        }
        
        if let weekday = dateComponents.get(.weekday) {
            mergedComponents.assign(.weekday, value: weekday)
        }
        
        // Copy time components
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
        
        if let timezone = timeComponents.get(.timezoneOffset) {
            mergedComponents.assign(.timezoneOffset, value: timezone)
        }
        
        let result = ParsingResult(
            reference: dateResult.reference,
            index: mergedIndex,
            text: mergedText,
            start: mergedComponents
        )
        
        result.addTag("ENMergeDateTimeRefiner")
        return result
    }
    
    /// Gets the text between two results
    /// - Parameters:
    ///   - first: The first result
    ///   - second: The second result
    /// - Returns: The merged text
    private func getTextBetween(first: ParsingResult, second: ParsingResult) -> String {
        let distance = second.index - (first.index + first.text.count)
        let startIndex = first.text.startIndex
        
        if distance < 0 {
            return first.text
        }
        
        if distance <= 5 {
            let firstEndIndex = first.index + first.text.count
            let secondEndIndex = second.index + second.text.count
            
            if secondEndIndex > firstEndIndex {
                return String(first.text[startIndex...]) + " " + second.text
            }
        }
        
        return first.text
    }
}