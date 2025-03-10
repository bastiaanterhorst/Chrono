// ESMergeDateTimeRefiner.swift - Refiner for merging date and time in Spanish
import Foundation

/// Refiner for merging date components with time components in Spanish
public final class ESMergeDateTimeRefiner: Refiner {
    // Pattern to match text between date and time, including "a las" (at)
    private let patternBetween = "^\\s*(?:,|de|aslas|a|a\\s+las|al?|hasta|y)?\\s*$"
    
    // Special handling for "el lunes a las 3:30 PM" type pattern
    private let specialPattern = "\\b(el|la)\\s+(lunes|martes|miércoles|miercoles|jueves|viernes|sábado|sabado|domingo)\\s+a\\s+las\\s+([0-9]{1,2}(?::[0-9]{2})?)(?:\\s*(am|pm|a\\.m\\.|p\\.m\\.))?\\b"
    
    public func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        var processedResults = results
        
        // First try direct pattern match for common formats like "el lunes a las 3:30 PM"
        processedResults = tryDirectPattern(context: context, results: processedResults)
        
        // Then do regular merging between separate date and time components
        processedResults = mergeCloseDateTimeResults(context: context, results: processedResults)
        
        return processedResults
    }
    
    // Try to match direct patterns like "el lunes a las 3:30 PM"
    private func tryDirectPattern(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        let text = context.text
        var newResults = [ParsingResult]()
        
        // Check for direct matches in the text
        if let regex = try? NSRegularExpression(pattern: specialPattern, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) {
            
            // Get the weekday, time, and AM/PM parts
            let nsText = text as NSString
            let weekdayText = nsText.substring(with: match.range(at: 2)).lowercased()
            let timeText = nsText.substring(with: match.range(at: 3))
            var meridiemText = ""
            if match.numberOfRanges > 4 && match.range(at: 4).location != NSNotFound {
                meridiemText = nsText.substring(with: match.range(at: 4)).lowercased()
            }
            
            // Get the weekday number
            if let weekdayNumber = ESConstants.WEEKDAY_DICTIONARY[weekdayText] {
                // Create components for the date
                let components = ParsingComponents(reference: context.reference)
                
                // Set weekday
                components.assign(.weekday, value: weekdayNumber + 1) // Convert from 0-based to 1-based
                
                // Parse the time
                let timeParts = timeText.split(separator: ":")
                if let hour = Int(timeParts[0]) {
                    components.assign(.hour, value: hour)
                    
                    // Set minutes if present
                    if timeParts.count > 1, let minute = Int(timeParts[1]) {
                        components.assign(.minute, value: minute)
                    } else {
                        components.assign(.minute, value: 0)
                    }
                    
                    // Handle AM/PM
                    if meridiemText.contains("p") {
                        // PM
                        if hour != 12 {
                            components.assign(.hour, value: hour + 12)
                        }
                    } else if meridiemText.contains("a") && hour == 12 {
                        // 12 AM is 0
                        components.assign(.hour, value: 0)
                    }
                    
                    components.assign(.second, value: 0)
                    
                    // Create result
                    let result = ParsingResult(
                        reference: context.reference,
                        index: match.range.location,
                        text: nsText.substring(with: match.range),
                        start: components
                    )
                    
                    newResults.append(result)
                }
            }
        }
        
        // If we found direct matches, return them. Otherwise, continue with the original results
        return newResults.isEmpty ? results : newResults
    }
    
    // Regular date-time component merging
    private func mergeCloseDateTimeResults(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        // Skip if there are no results
        if results.count <= 1 {
            return results
        }
        
        let patternRegex = try? NSRegularExpression(pattern: patternBetween, options: [])
        var mergedResults: [ParsingResult] = []
        var currentResult: ParsingResult? = nil
        
        // For all results
        for result in results {
            // We want to find a date result followed by a time result
            if let current = currentResult {
                // Check if this result contains only time components
                let timeComponents: [Component] = [.hour, .minute, .second, .millisecond, .meridiem, .timezoneOffset]
                let onlyTimeComponents = result.start.getCertainComponents().allSatisfy { timeComponents.contains($0) }
                
                // Check if current result contains date components
                let dateComponents: [Component] = [.year, .month, .day, .weekday]
                let hasDateComponents = current.start.getCertainComponents().contains { dateComponents.contains($0) }
                
                if onlyTimeComponents && hasDateComponents {
                    // Check if there is a match between the two results
                    let text = context.text
                    let from = current.index + current.text.count
                    let to = result.index
                    
                    // Only merge if the results are close to each other
                    if from <= to {
                        let textBetween = (text as NSString).substring(with: NSRange(location: from, length: to - from))
                        
                        if let regex = patternRegex,
                           regex.firstMatch(in: textBetween, options: [], range: NSRange(location: 0, length: textBetween.utf16.count)) != nil {
                            
                            // Create new merged component 
                            let startComponents = current.start.clone()
                            
                            // Transfer time components
                            for component in timeComponents {
                                if result.start.isCertain(component) {
                                    if let value = result.start.get(component) {
                                        startComponents.assign(component, value: value)
                                    }
                                }
                            }
                            
                            // Get the combined text
                            let nsText = text as NSString
                            let endIndex = to + result.text.count
                            let newText = nsText.substring(with: NSRange(location: current.index, length: endIndex - current.index))
                            
                            // Create the merged result
                            let merged = ParsingResult(
                                reference: context.reference,
                                index: current.index,
                                text: newText,
                                start: startComponents
                            )
                            
                            // End components if applicable
                            if let currentEnd = current.end, let resultEnd = result.end {
                                let endComponents = currentEnd.clone()
                                
                                // Transfer time components to end
                                for component in timeComponents {
                                    if resultEnd.isCertain(component) {
                                        if let value = resultEnd.get(component) {
                                            endComponents.assign(component, value: value)
                                        }
                                    }
                                }
                                
                                merged.end = endComponents
                            }
                            
                            mergedResults.append(merged)
                            currentResult = nil
                            continue
                        }
                    }
                }
            }
            
            // If no merge happened, add the previous result to the output
            if let current = currentResult {
                mergedResults.append(current)
            }
            
            // Set up the next currentResult
            currentResult = result
        }
        
        // Add the last result
        if let current = currentResult {
            mergedResults.append(current)
        }
        
        return mergedResults
    }
}