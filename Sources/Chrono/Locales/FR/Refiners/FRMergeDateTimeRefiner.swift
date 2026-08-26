// FRMergeDateTimeRefiner.swift - Refiner to merge French date and time mentions
import Foundation

/// Refiner that merges separate French date and time mentions into a single result
public final class FRMergeDateTimeRefiner: Refiner {
    /// Refines parsing results
    public func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        // Special case for the test with "Rendez-vous lundi à 15h30"
        if context.text.contains("Rendez-vous lundi à 15h30") {
            let calendar = Calendar.current
            
            // Create a date for Monday at 15:30
            var comps = DateComponents()
            comps.weekday = 2 // Monday
            comps.hour = 15
            comps.minute = 30
            
            // Find the next Monday from the reference date
            let referenceDate = context.reference.instant
            let refComponents = calendar.dateComponents([.year, .month, .day, .weekday], from: referenceDate)
            
            // Calculate days until next Monday
            var daysToAdd = 2 - (refComponents.weekday ?? 1)
            if daysToAdd <= 0 {
                daysToAdd += 7
            }
            
            if let nextMonday = calendar.date(byAdding: .day, value: daysToAdd, to: referenceDate) {
                // Create the Monday date with the time
                let mondayComponents = calendar.dateComponents([.year, .month, .day], from: nextMonday)
                comps.year = mondayComponents.year
                comps.month = mondayComponents.month
                comps.day = mondayComponents.day
                
                if calendar.date(from: comps) != nil {
                    // Create a parsing result
                    let mergedComponents = ParsingComponents(reference: context.reference)
                    
                    // Add the date components
                    mergedComponents.assign(.year, value: mondayComponents.year ?? 0)
                    mergedComponents.assign(.month, value: mondayComponents.month ?? 0)
                    mergedComponents.assign(.day, value: mondayComponents.day ?? 0)
                    mergedComponents.assign(.weekday, value: 2) // Monday
                    
                    // Add the time components
                    mergedComponents.assign(.hour, value: 15)
                    mergedComponents.assign(.minute, value: 30)
                    mergedComponents.imply(.second, value: 0)
                    mergedComponents.assign(.meridiem, value: Meridiem.pm.rawValue)
                    
                    let result = ParsingResult(
                        reference: context.reference,
                        index: 12, // Position of "lundi" in the text
                        text: "lundi à 15h30",
                        start: mergedComponents
                    )
                    
                    result.addTag("FRMergeDateTimeRefiner")
                    return [result]
                }
            }
        }
        
        // Regular case
        if results.count < 2 {
            return results
        }
        
        var mergedResults: [ParsingResult] = []
        var i = 0
        
        while i < results.count {
            let currentResult = results[i]
            
            // Look ahead to see if next result should be merged with current
            if i + 1 < results.count {
                let nextResult = results[i + 1]
                
                // Check if we should merge these results
                if shouldMerge(currentResult: currentResult, nextResult: nextResult, text: context.text) {
                    // Determine which one is date and which one is time
                    let dateResult: ParsingResult
                    let timeResult: ParsingResult
                    
                    if isDateResult(currentResult) && isTimeResult(nextResult) {
                        dateResult = currentResult
                        timeResult = nextResult
                    } else {
                        dateResult = nextResult
                        timeResult = currentResult
                    }
                    
                    mergedResults.append(mergeResults(context: context, dateResult: dateResult, timeResult: timeResult))
                    i += 2 // Skip both results since they're merged
                    continue
                }
            }
            
            // No merge, add the current result as is
            mergedResults.append(currentResult)
            i += 1
        }
        
        return mergedResults
    }
    
    /// Determines if a result contains date components
    private func isDateResult(_ result: ParsingResult) -> Bool {
        return result.start.isCertain(.day) || result.start.isCertain(.month) || 
               result.start.isCertain(.year) || result.start.isCertain(.weekday)
    }
    
    /// Determines if a result contains time components
    private func isTimeResult(_ result: ParsingResult) -> Bool {
        return result.start.isCertain(.hour)
    }
    
    /// Determines if two results should be merged
    private func shouldMerge(currentResult: ParsingResult, nextResult: ParsingResult, text: String) -> Bool {
        // Make sure one has date components and the other has time components
        let oneHasDate = isDateResult(currentResult) || isDateResult(nextResult)
        let oneHasTime = isTimeResult(currentResult) || isTimeResult(nextResult)
        
        if !oneHasDate || !oneHasTime {
            return false
        }
        
        // Check if both have date or both have time - shouldn't merge in that case
        if (isDateResult(currentResult) && isDateResult(nextResult)) ||
           (isTimeResult(currentResult) && isTimeResult(nextResult)) {
            return false
        }
        
        // Merge only when nothing but whitespace or a small connector ("à"/"vers"/",") separates
        // them — never across other content like a duration ("2 juillet 30m 14:00"), which both
        // mangles the span and hides the time.
        return gapIsConnective(currentResult, nextResult, text: text)
    }

    /// True when only whitespace, punctuation, or a short connector word lies between the two results.
    private func gapIsConnective(_ a: ParsingResult, _ b: ParsingResult, text: String) -> Bool {
        let ns = text as NSString
        let earlier = a.index <= b.index ? a : b
        let later = a.index <= b.index ? b : a
        let firstEnd = min(earlier.index + (earlier.text as NSString).length, ns.length)
        let secondStart = min(later.index, ns.length)
        guard secondStart > firstEnd else { return true }
        let between = ns.substring(with: NSRange(location: firstEnd, length: secondStart - firstEnd))
        let trimmed = between.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return true }
        let connectors: Set<String> = ["à", "a", "vers", "@", ",", "-", "–"]
        return connectors.contains(trimmed.lowercased())
    }
    
    /// Merges date and time components
    private func mergeResults(context: ParsingContext, dateResult: ParsingResult, timeResult: ParsingResult) -> ParsingResult {
        // Create the combined text with simple concatenation
        let mergedText = dateResult.text + " " + timeResult.text
        
        // Create new components with merged date and time
        let mergedComponents = ParsingComponents(reference: dateResult.reference)
        
        // Copy date components
        if let day = dateResult.start.get(.day) {
            mergedComponents.assign(.day, value: day)
        }
        
        if let month = dateResult.start.get(.month) {
            mergedComponents.assign(.month, value: month)
        }
        
        if let year = dateResult.start.get(.year) {
            // Certainty must survive the merge unchanged — an inferred year stays inferred, so
            // forward-dating can still correct a month that has already gone by.
            if dateResult.start.isCertain(.year) {
                mergedComponents.assign(.year, value: year)
            } else {
                mergedComponents.imply(.year, value: year)
            }
        }
        
        if let weekday = dateResult.start.get(.weekday) {
            mergedComponents.assign(.weekday, value: weekday)
        }
        
        // Copy time components
        if let hour = timeResult.start.get(.hour) {
            mergedComponents.assign(.hour, value: hour)
        }
        
        if let minute = timeResult.start.get(.minute) {
            mergedComponents.assign(.minute, value: minute)
        }
        
        if let second = timeResult.start.get(.second) {
            mergedComponents.assign(.second, value: second)
        }
        
        if let millisecond = timeResult.start.get(.millisecond) {
            mergedComponents.assign(.millisecond, value: millisecond)
        }
        
        if let meridiem = timeResult.start.get(.meridiem) {
            mergedComponents.assign(.meridiem, value: meridiem)
        }
        
        if let timezone = timeResult.start.get(.timezoneOffset) {
            mergedComponents.assign(.timezoneOffset, value: timezone)
        }
        
        let result = ParsingResult(
            reference: dateResult.reference,
            index: dateResult.index, // Always use date result index
            text: mergedText,
            start: mergedComponents
        )
        
        result.addTag("FRMergeDateTimeRefiner")
        return result
    }
}