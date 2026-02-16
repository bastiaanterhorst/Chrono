import Foundation

/**
 * Refiner that removes overlapping date results, keeping the longest/most specific ones.
 */
public final class OverlapRemovalRefiner: Refiner {
    
    public func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        if results.count <= 1 {
            return results
        }
        
        let sortedResults = results.sorted { lhs, rhs in
            if lhs.index != rhs.index {
                return lhs.index < rhs.index
            }
            if endIndex(of: lhs) != endIndex(of: rhs) {
                return endIndex(of: lhs) > endIndex(of: rhs)
            }
            return lhs.text.count > rhs.text.count
        }

        var selected: [ParsingResult] = []

        for candidate in sortedResults {
            var shouldAdd = true
            var toRemove: [Int] = []

            for (idx, existing) in selected.enumerated() {
                if strictlyContains(existing, candidate) {
                    shouldAdd = false
                    break
                }

                if strictlyContains(candidate, existing) {
                    toRemove.append(idx)
                    continue
                }

                if hasSameRange(existing, candidate) {
                    if isPreferred(candidate, over: existing) {
                        toRemove.append(idx)
                    } else {
                        shouldAdd = false
                    }
                }
            }

            if !shouldAdd {
                continue
            }

            for idx in toRemove.sorted(by: >) {
                selected.remove(at: idx)
            }

            selected.append(candidate)
        }

        return selected.sorted { lhs, rhs in
            if lhs.index != rhs.index {
                return lhs.index < rhs.index
            }
            return endIndex(of: lhs) < endIndex(of: rhs)
        }
    }

    private func endIndex(of result: ParsingResult) -> Int {
        return result.index + result.text.count
    }

    private func hasSameRange(_ lhs: ParsingResult, _ rhs: ParsingResult) -> Bool {
        return lhs.index == rhs.index && endIndex(of: lhs) == endIndex(of: rhs)
    }

    private func strictlyContains(_ outer: ParsingResult, _ inner: ParsingResult) -> Bool {
        let outerStart = outer.index
        let outerEnd = endIndex(of: outer)
        let innerStart = inner.index
        let innerEnd = endIndex(of: inner)

        guard innerStart >= outerStart, innerEnd <= outerEnd else {
            return false
        }

        // Equal-span matches are not strict containment.
        return innerStart > outerStart || innerEnd < outerEnd
    }

    private func certaintyScore(_ result: ParsingResult) -> Int {
        let startScore = result.start.getCertainComponents().count
        let endScore = result.end?.getCertainComponents().count ?? 0
        return startScore + endScore
    }

    private func hasCertainISOWeek(_ result: ParsingResult) -> Bool {
        return result.start.isCertain(.isoWeek) || result.start.isCertain(.isoWeekYear)
    }

    private func isPreferred(_ lhs: ParsingResult, over rhs: ParsingResult) -> Bool {
        let lhsISOWeek = hasCertainISOWeek(lhs)
        let rhsISOWeek = hasCertainISOWeek(rhs)
        if lhsISOWeek != rhsISOWeek {
            return lhsISOWeek
        }

        let lhsCertainty = certaintyScore(lhs)
        let rhsCertainty = certaintyScore(rhs)
        if lhsCertainty != rhsCertainty {
            return lhsCertainty > rhsCertainty
        }

        let lhsHasRange = lhs.end != nil
        let rhsHasRange = rhs.end != nil
        if lhsHasRange != rhsHasRange {
            return lhsHasRange
        }

        if lhs.text.count != rhs.text.count {
            return lhs.text.count > rhs.text.count
        }

        // Stable final tie-breaker.
        return lhs.index <= rhs.index
    }
}
