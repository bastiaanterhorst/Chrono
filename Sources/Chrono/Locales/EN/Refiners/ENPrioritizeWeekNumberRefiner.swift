// ENPrioritizeWeekNumberRefiner.swift - Filter to prioritize week-based parsing results
import Foundation

/// Prioritizes week number results over other parsings that might conflict
public class ENPrioritizeWeekNumberRefiner: Refiner, @unchecked Sendable {
    
    public func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        if results.count <= 1 {
            return results // Nothing to filter
        }
        
        // Group results by their index (their position in the text)
        var resultsByIndex: [Int: [ParsingResult]] = [:]
        for result in results {
            let index = result.index
            if resultsByIndex[index] == nil {
                resultsByIndex[index] = []
            }
            resultsByIndex[index]?.append(result)
        }
        
        // For each position that has multiple results, prioritize week numbers
        var filteredResults: [ParsingResult] = []
        
        for (_, resultsAtIndex) in resultsByIndex {
            if resultsAtIndex.count == 1 {
                // Only one result at this position, keep it
                filteredResults.append(resultsAtIndex[0])
            } else {
                // Check if any results have the Week parser tag
                let weekResults = resultsAtIndex.filter { result in
                    return result.hasTag("ENISOWeekParser") || result.hasTag("ENRelativeWeekParser")
                }
                
                if !weekResults.isEmpty {
                    // Prioritize week-based results
                    filteredResults.append(contentsOf: weekResults)
                    
                    // Debug the prioritization
                    if let debug = context.options.debug as? Bool, debug {
                        print("[Chrono] Prioritizing week-based result at index \(weekResults[0].index)")
                    }
                } else {
                    // No week results, keep all results at this position
                    filteredResults.append(contentsOf: resultsAtIndex)
                }
            }
        }
        
        return filteredResults
    }
}