// ESPrioritizeWeekNumberRefiner.swift - Prioritize Spanish week-based parser results
import Foundation

/// Prioritizes Spanish week parser results over conflicting results at the same index
final class ESPrioritizeWeekNumberRefiner: Refiner, @unchecked Sendable {
    func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        if results.count <= 1 {
            return results
        }

        var groupedByIndex: [Int: [ParsingResult]] = [:]
        for result in results {
            groupedByIndex[result.index, default: []].append(result)
        }

        var filtered: [ParsingResult] = []
        for (_, indexedResults) in groupedByIndex {
            if indexedResults.count == 1 {
                filtered.append(indexedResults[0])
                continue
            }

            let weekResults = indexedResults.filter { result in
                result.hasTag("ESISOWeekParser") || result.hasTag("ESRelativeWeekParser")
            }

            if weekResults.isEmpty {
                filtered.append(contentsOf: indexedResults)
            } else {
                filtered.append(contentsOf: weekResults)
            }
        }

        return filtered.sorted { $0.index < $1.index }
    }
}
