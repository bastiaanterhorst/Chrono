// PTMergeDateTimeRefiner.swift - Refiner to merge date and time components in Portuguese text
import Foundation

/// Refiner that merges date and time components in Portuguese text
public final class PTMergeDateTimeRefiner: Refiner {
    /// Refines parsing results to merge date and time components
    public func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        if results.count < 2 {
            return results
        }
        
        var mergedResults: [ParsingResult] = []
        var i = 0
        
        while i < results.count {
            // Get the first result
            let result1 = results[i]
            i += 1
            
            // If we've reached the end, just add the result and finish
            if i >= results.count {
                mergedResults.append(result1)
                break
            }
            
            // Get the next result
            let result2 = results[i]
            
            // Check if this could be a "date" then "time" situation
            let isDateThenTime = (
                !result1.start.isCertain(.hour) &&
                !result1.start.isCertain(.minute) &&
                result2.start.isCertain(.hour) &&
                result2.start.isCertain(.minute) &&
                !result2.start.isCertain(.month) &&
                !result2.start.isCertain(.year) &&
                !result2.start.isCertain(.day)
            )
            
            // Check if this could be a "time" then "date" situation
            let isTimeThenDate = (
                !result2.start.isCertain(.hour) &&
                !result2.start.isCertain(.minute) &&
                result1.start.isCertain(.hour) &&
                result1.start.isCertain(.minute) &&
                !result1.start.isCertain(.month) &&
                !result1.start.isCertain(.year) &&
                !result1.start.isCertain(.day)
            )
            
            // Check if we should merge these results
            let shouldMerge = isDateThenTime || isTimeThenDate
            let abutting = result2.index - (result1.index + result1.text.count) <= 5
            
            // Check for connecting text "às", "a", "de", etc.
            let hasConnectingText = {
                // Get text between the two results
                let startIndex = result1.index + result1.text.count
                let endIndex = result2.index
                
                guard startIndex < endIndex, 
                      startIndex >= 0,
                      endIndex <= context.text.count else {
                    return false
                }
                
                // Get text between the two results safely
                let startStringIndex = context.text.index(context.text.startIndex, offsetBy: startIndex)
                let endStringIndex = context.text.index(context.text.startIndex, offsetBy: endIndex)
                let textBetween = String(context.text[startStringIndex..<endStringIndex])
                
                // Look for connecting words
                return textBetween.range(of: "\\s*(às|as|a|de|,)\\s*", options: [.regularExpression]) != nil
            }()
            
            if shouldMerge && (abutting || hasConnectingText) {
                // Decide which one has the date and which has the time
                let dateResult = isDateThenTime ? result1 : result2
                let timeResult = isDateThenTime ? result2 : result1
                
                // Create a combined result
                let combinedText = isDateThenTime ? 
                    "\(result1.text) \(result2.text)" : 
                    "\(result2.text) \(result1.text)"
                
                // Start with the date result and add time components
                let combined = ParsingResult(
                    reference: context.reference,
                    index: isDateThenTime ? result1.index : result2.index,
                    text: combinedText,
                    start: dateResult.start
                )
                
                // Copy time-related values from timeResult to combined
                if timeResult.start.isCertain(.hour) {
                    combined.start.assign(.hour, value: timeResult.start.get(.hour) ?? 0)
                }
                
                if timeResult.start.isCertain(.minute) {
                    combined.start.assign(.minute, value: timeResult.start.get(.minute) ?? 0)
                }
                
                if timeResult.start.isCertain(.second) {
                    combined.start.assign(.second, value: timeResult.start.get(.second) ?? 0)
                }
                
                if timeResult.start.isCertain(.meridiem) {
                    combined.start.assign(.meridiem, value: timeResult.start.get(.meridiem) ?? 0)
                }
                
                // Handle end components if present
                if timeResult.end != nil || dateResult.end != nil {
                    // Default to the date's end component, if available
                    let endComponent = dateResult.end?.clone() 
                                    ?? (dateResult.start.clone() as ParsingComponents)
                    
                    // If timeResult has an end, use its hours/minutes
                    if let timeEnd = timeResult.end {
                        if timeEnd.isCertain(.hour) {
                            endComponent.assign(.hour, value: timeEnd.get(.hour) ?? 0)
                        }
                        
                        if timeEnd.isCertain(.minute) {
                            endComponent.assign(.minute, value: timeEnd.get(.minute) ?? 0)
                        }
                        
                        if timeEnd.isCertain(.second) {
                            endComponent.assign(.second, value: timeEnd.get(.second) ?? 0)
                        }
                    }
                    // Otherwise, use timeResult's start time for the end
                    else if timeResult.start.isCertain(.hour) {
                        endComponent.assign(.hour, value: timeResult.start.get(.hour) ?? 0)
                        endComponent.assign(.minute, value: timeResult.start.get(.minute) ?? 0)
                        
                        if timeResult.start.isCertain(.second) {
                            endComponent.assign(.second, value: timeResult.start.get(.second) ?? 0)
                        }
                        
                        if timeResult.start.isCertain(.meridiem) {
                            endComponent.assign(.meridiem, value: timeResult.start.get(.meridiem) ?? 0)
                        }
                    }
                    
                    combined.end = endComponent
                }
                
                // Add the merged result
                combined.addTag("PTMergeDateTimeRefiner")
                mergedResults.append(combined)
                i += 1 // Skip the second result since we merged it
            } else {
                // If we don't merge, just add the first result as is
                mergedResults.append(result1)
            }
        }
        
        return mergedResults
    }
}