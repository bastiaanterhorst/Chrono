// ENPrioritizeSpecificDateRefiner.swift - Refiner to prioritize specific date matches
import Foundation

/// Refiner that prioritizes more specific date/time mentions over more ambiguous ones
public final class ENPrioritizeSpecificDateRefiner: Refiner {
    /// Refines parsing results
    public func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        if results.count <= 1 {
            return results
        }
        
        // First, clone the results to avoid modifying the originals
        let clonedResults = results
        
        // Find and remove overlapping results, keeping the more specific ones
        var filteredResults: [ParsingResult] = []
        
        for result in clonedResults {
            // Check if this result overlaps with any existing result
            let resultStart = result.index
            let resultEnd = resultStart + result.text.count
            var shouldAdd = true
            
            // Check against each existing result for overlap
            var overlappingResults: [ParsingResult] = []
            
            for existingResult in filteredResults {
                let existingStart = existingResult.index
                let existingEnd = existingStart + existingResult.text.count
                
                // Check for overlap
                if (resultStart <= existingEnd && resultEnd >= existingStart) ||
                   (existingStart <= resultEnd && existingEnd >= resultStart) {
                    overlappingResults.append(existingResult)
                }
            }
            
            if !overlappingResults.isEmpty {
                // There are overlapping results - check which is more specific
                for existingResult in overlappingResults {
                    // Compare specificity
                    if isMoreSpecific(result, than: existingResult) {
                        // Remove less specific result
                        filteredResults.removeAll { $0 === existingResult }
                    } else {
                        // Current result is less specific, don't add it
                        shouldAdd = false
                    }
                }
            }
            
            if shouldAdd {
                filteredResults.append(result)
            }
        }
        
        return filteredResults
    }
    
    /// Determines if result1 is more specific than result2
    private func isMoreSpecific(_ result1: ParsingResult, than result2: ParsingResult) -> Bool {
        let tags1 = result1.getTags()
        let tags2 = result2.getTags()
        
        // Specific parsers are more specific than casual parsers
        let isCasual1 = tags1.contains { $0.contains("Casual") }
        let isCasual2 = tags2.contains { $0.contains("Casual") }
        
        if isCasual1 && !isCasual2 {
            return false
        }
        
        if !isCasual1 && isCasual2 {
            return true
        }
        
        // Compare component certainty
        let components1 = result1.start.getCertainComponents().count
        let components2 = result2.start.getCertainComponents().count
        
        if components1 != components2 {
            return components1 > components2
        }
        
        // Compare text length
        return result1.text.count > result2.text.count
    }
}