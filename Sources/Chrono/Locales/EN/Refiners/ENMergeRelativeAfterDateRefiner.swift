// ENMergeRelativeAfterDateRefiner.swift
import Foundation

/// A refiner that merges specific dates with relative expressions that follow
/// E.g., "3pm tomorrow" will merge "3pm" with "tomorrow"
public struct ENMergeRelativeAfterDateRefiner: Refiner {
    public init() {}
    
    public func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        // Check if we have enough results to process
        if results.count < 2 {
            return results
        }
        
        var resultsCopy = results
        var mergedResults: [ParsingResult] = []
        
        var i = 0
        while i < resultsCopy.count {
            let currentResult = resultsCopy[i]
            
            // Look ahead to see if there's a relative date that follows this one
            if i + 1 < resultsCopy.count {
                let nextResult = resultsCopy[i + 1]
                let nextText = nextResult.text.lowercased()
                
                // Skip if the next result is not a relative date expression
                if !isRelativeDate(text: nextText) {
                    mergedResults.append(currentResult)
                    i += 1
                    continue
                }
                
                // Check if the results are close enough to be merged
                let gapBetweenResults = nextResult.index - (currentResult.index + currentResult.text.count)

                // Only merge when a relative WEEK is involved ("thursday next week", "next week
                // next month"). Merging two plain relative dates ("today yesterday") is wrong — those
                // are independent and must stay separate so last-wins / past-skip can choose.
                // (The relative-week+weekday case is also handled earlier by
                // CombineRelativeWeekAndWeekdayRefiner; this remains as a safety net.)
                let weekInvolved = currentResult.start.isCertain(.isoWeek) || nextResult.start.isCertain(.isoWeek)
                if gapBetweenResults <= 3, weekInvolved {
                    let mergedResult = mergeResults(currentResult, nextResult, context: context)
                    mergedResults.append(mergedResult)
                    i += 2 // Skip the next result since we've merged it
                    continue
                }
            }
            
            mergedResults.append(currentResult)
            i += 1
        }
        
        return mergedResults
    }
    
    /// Checks if a text contains a relative date expression
    private func isRelativeDate(text: String) -> Bool {
        // Typical relative date markers
        let relativeMarkers = [
            "tomorrow",
            "yesterday",
            "today",
            "tonight",
            "next week",
            "last week",
            "next month",
            "last month",
            "next year",
            "last year",
            "now"
        ]
        
        // Check if the text contains any of these markers
        for marker in relativeMarkers {
            if text.contains(marker) {
                return true
            }
        }
        
        return false
    }
    
    /// Merges two parsing results
    private func mergeResults(_ timeResult: ParsingResult, _ relativeResult: ParsingResult, context: ParsingContext) -> ParsingResult {
        // Start with the time components
        let timeComponents = timeResult.start
        
        // Get the relative date components
        let relativeDateComponents = relativeResult.start
        
        // Create a new component set that combines both
        let mergedComponents = timeComponents.clone()
        
        // Special case: a weekday combined with a relative WEEK (e.g. "thursday next week") resolves
        // to that weekday WITHIN that week — the more precise day overrides the week's default Monday.
        if let weekday = timeComponents.get(.weekday), relativeDateComponents.isCertain(.isoWeek),
           let weekAnchor = relativeResult.start.date() { // Monday (start) of the relative week
            let calendar = Calendar(identifier: .gregorian)
            let daysFromMonday = (weekday == 0) ? 6 : (weekday - 1) // parser weekdays: Sun=0…Sat=6
            if let target = calendar.date(byAdding: .day, value: daysFromMonday, to: weekAnchor) {
                let dc = calendar.dateComponents([.year, .month, .day], from: target)
                if let y = dc.year { mergedComponents.assign(.year, value: y) }
                if let m = dc.month { mergedComponents.assign(.month, value: m) }
                if let d = dc.day { mergedComponents.assign(.day, value: d) }
                mergedComponents.assign(.weekday, value: weekday)
            }
        } else {
            // Merge date components from the relative result
            if let year = relativeDateComponents.get(.year) {
                mergedComponents.assign(.year, value: year)
            }
            if let month = relativeDateComponents.get(.month) {
                mergedComponents.assign(.month, value: month)
            }
            if let day = relativeDateComponents.get(.day) {
                mergedComponents.assign(.day, value: day)
            }
            if let weekday = relativeDateComponents.get(.weekday) {
                mergedComponents.assign(.weekday, value: weekday)
            }
        }
        
        // If relative result has time components that aren't overridden by the first result, merge those too
        if timeComponents.get(.hour) == nil, let hour = relativeDateComponents.get(.hour) {
            mergedComponents.assign(.hour, value: hour)
        }
        if timeComponents.get(.minute) == nil, let minute = relativeDateComponents.get(.minute) {
            mergedComponents.assign(.minute, value: minute)
        }
        if timeComponents.get(.second) == nil, let second = relativeDateComponents.get(.second) {
            mergedComponents.assign(.second, value: second)
        }
        if timeComponents.get(.meridiem) == nil, let meridiem = relativeDateComponents.get(.meridiem) {
            mergedComponents.assign(.meridiem, value: meridiem)
        }
        
        // Combine the text of both results. Clamp offsets to the string's bounds so a malformed
        // result (index/text length disagreeing) can never overrun and crash.
        let n = context.text.count
        let startOffset = max(0, min(timeResult.index, n))
        let endOffset = max(startOffset, min(relativeResult.index + relativeResult.text.count, n))
        let startPos = context.text.index(context.text.startIndex, offsetBy: startOffset)
        let endPos = context.text.index(context.text.startIndex, offsetBy: endOffset)
        let combinedText = String(context.text[startPos..<endPos])
        
        // Create a new result that spans both parts
        return context.createParsingResult(
            index: timeResult.index,
            text: combinedText,
            start: mergedComponents,
            end: relativeResult.end
        )
    }
}