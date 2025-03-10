import Foundation

/**
 * Refiner that removes overlapping date results, keeping the longest/most specific ones.
 */
public final class OverlapRemovalRefiner: Refiner {
    
    public func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        if results.count <= 1 {
            return results
        }
        
        let sortedResults = results.sorted { (a, b) -> Bool in
            if a.index != b.index {
                return a.index < b.index
            }
            
            return a.text.count > b.text.count
        }
        
        let filteredResults = sortedResults.filter { (result) -> Bool in
            // Check for any longer results that fully contain this one
            for otherResult in sortedResults {
                if otherResult === result {
                    continue
                }
                
                if isContained(result, in: otherResult) {
                    return false
                }
            }
            
            return true
        }
        
        return filteredResults
    }
    
    private func isContained(_ result: ParsingResult, in otherResult: ParsingResult) -> Bool {
        if result.index >= otherResult.index && 
           result.index + result.text.count <= otherResult.index + otherResult.text.count {
            return true
        }
        
        return false
    }
}