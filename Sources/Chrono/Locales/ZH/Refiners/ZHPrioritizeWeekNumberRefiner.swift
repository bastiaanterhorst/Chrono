// ZHPrioritizeWeekNumberRefiner.swift - Prioritize Chinese week-based parser results
import Foundation

/// Prioritizes Chinese week parser results over conflicting results at the same index.
///
/// Several parsers can claim the same starting position — `下周` is a relative week to
/// `ZHRelativeWeekParser` and a plain day offset to the casual/relative-unit parsers, and `第12周`
/// is a week number that another parser may read as a bare numeral. When that happens the
/// week-based reading is the intended one, so any result tagged by a week parser wins and the
/// others at that index are dropped. Positions with a single result, or with no week result at
/// all, are left exactly as they are.
public struct ZHPrioritizeWeekNumberRefiner: Refiner {
    public init() {}

    /// The tags the two ZH week parsers stamp on their results.
    private static let weekParserTags = ["ZHISOWeekParser", "ZHRelativeWeekParser"]

    public func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        if results.count <= 1 {
            return results // nothing can conflict
        }

        // Group the results by their position in the text.
        var groupedByIndex: [Int: [ParsingResult]] = [:]
        for result in results {
            groupedByIndex[result.index, default: []].append(result)
        }

        // Walk the positions in ascending order — dictionary iteration order is unspecified, and
        // the output has to be ordered by index deterministically. Within a position the original
        // relative order is preserved.
        var filtered: [ParsingResult] = []
        for index in groupedByIndex.keys.sorted() {
            guard let indexedResults = groupedByIndex[index] else { continue }

            if indexedResults.count == 1 {
                filtered.append(indexedResults[0])
                continue
            }

            let weekResults = indexedResults.filter { isWeekParserResult($0) }

            if weekResults.isEmpty {
                // No week reading is in play at this position, so nothing to prioritize.
                filtered.append(contentsOf: indexedResults)
            } else {
                filtered.append(contentsOf: weekResults)
            }
        }

        return filtered
    }

    /// Whether a result came from one of the ZH week parsers.
    ///
    /// Both the result and its start components are checked: a parser may tag either (the
    /// components' tags are the ones that survive `clone()`, so they still identify the origin of a
    /// result that a merge refiner has since rebuilt).
    private func isWeekParserResult(_ result: ParsingResult) -> Bool {
        return Self.weekParserTags.contains { tag in
            result.hasTag(tag) || result.start.hasTag(tag)
        }
    }
}
