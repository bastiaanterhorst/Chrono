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
            if shouldMerge(context: context, currentResult: currentResult, nextResult: nextResult) {
                currentResult = mergeResults(context: context, dateResult: currentResult, timeResult: nextResult)
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
    private func shouldMerge(context: ParsingContext, currentResult: ParsingResult, nextResult: ParsingResult) -> Bool {
        // Check if one has date components and the other has time components
        let firstHasDate = currentResult.start.isCertain(.day) || currentResult.start.isCertain(.month) || currentResult.start.isCertain(.year)
        let firstHasTime = currentResult.start.isCertain(.hour)

        let secondHasDate = nextResult.start.isCertain(.day) || nextResult.start.isCertain(.month) || nextResult.start.isCertain(.year)
        let secondHasTime = nextResult.start.isCertain(.hour)

        let complementary = (firstHasDate && !firstHasTime && secondHasTime && !secondHasDate) ||
                            (firstHasTime && !firstHasDate && secondHasDate && !secondHasTime)
        guard complementary else { return false }

        // Only merge when nothing but whitespace or a tiny connector ("at"/"on"/",") separates them.
        // Never merge across other content like a duration ("2 jul 30m 2pm") — that both mangles the
        // span and hides the time, since the two are not really one "date at time" phrase.
        return gapIsConnective(context: context, first: currentResult, second: nextResult)
    }

    /// True when only whitespace, punctuation, or a short connector word lies between the two results.
    private func gapIsConnective(context: ParsingContext, first: ParsingResult, second: ParsingResult) -> Bool {
        let ns = context.text as NSString
        let firstEnd = min(first.index + (first.text as NSString).length, ns.length)
        let secondStart = min(second.index, ns.length)
        guard secondStart > firstEnd else { return true } // adjacent or overlapping
        let between = ns.substring(with: NSRange(location: firstEnd, length: secondStart - firstEnd))
        let trimmed = between.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return true }
        let connectors: Set<String> = ["at", "on", "by", "around", "@", ",", "-", "–"]
        return connectors.contains(trimmed.lowercased())
    }
    
    /// Merges date and time components
    /// - Parameters:
    ///   - dateResult: The result with date information
    ///   - timeResult: The result with time information
    /// - Returns: A merged result
    private func mergeResults(context: ParsingContext, dateResult: ParsingResult, timeResult: ParsingResult) -> ParsingResult {
        let dateIsFirst = dateResult.index < timeResult.index

        let firstResult = dateIsFirst ? dateResult : timeResult
        let secondResult = dateIsFirst ? timeResult : dateResult

        // The real contiguous substring spanning both (we only merge across a trivial gap), so the
        // span is correct rather than a fabricated concatenation.
        let ns = context.text as NSString
        let mergedIndex = min(firstResult.index, ns.length)
        let mergedEnd = min(secondResult.index + (secondResult.text as NSString).length, ns.length)
        let mergedText = ns.substring(with: NSRange(location: mergedIndex, length: max(0, mergedEnd - mergedIndex)))
        
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
}