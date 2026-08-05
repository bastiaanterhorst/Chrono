// ZHMergeDateRangeRefiner.swift - Merge two Chinese dates joined by a range connector
import Foundation

/// Merges `<date><connector><date>` into a single start/end result:
/// `3月1日到3月5日`, `3月1日至3月5日`, `3月1日-3月5日`, `3月1日~3月5日`, `周一到周五`,
/// `从3月1日到3月5日`.
///
/// The test is entirely structural — two date results with nothing but a range connector between
/// them — so it holds for any pair of dates the ZH parsers can produce, anywhere in any sentence.
/// Neither side is inspected for particular words and the surrounding text is never consulted.
public struct ZHMergeDateRangeRefiner: Refiner {
    public init() {}

    /// The complete set of range connectors, matched against the *trimmed* text lying strictly
    /// between the two date matches.
    ///
    /// `到` and `至` are the words ("to", "until"); the rest are the punctuation forms, including
    /// the full-width tilde `～` that a Chinese IME emits and the en/em dashes. `~至` is the
    /// doubled form some writers use.
    ///
    /// `从`/`從` ("from") is deliberately absent: it introduces the *first* date and therefore sits
    /// before it, outside both matches and outside this gap. `从3月1日到3月5日` consequently needs
    /// no special handling — the gap is still just `到` — and the 从 is simply left in place rather
    /// than being absorbed into the merged span.
    private static let rangeConnectors: Set<String> = ["到", "至", "-", "–", "—", "~", "～", "~至"]

    public func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        guard results.count >= 2 else { return results }

        let nsText = context.text as NSString
        let ordered = sortedByIndex(results)

        var output: [ParsingResult] = []
        var i = 0

        while i < ordered.count {
            let first = ordered[i]

            if i + 1 < ordered.count {
                let second = ordered[i + 1]
                if isDate(first),
                   isDate(second),
                   let gap = textBetween(first, second, in: nsText),
                   Self.rangeConnectors.contains(gap.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    output.append(merge(from: first, to: second, context: context, nsText: nsText))
                    i += 2 // both results are consumed by the range
                    continue
                }
            }

            // Results that do not form a range pass through untouched.
            output.append(first)
            i += 1
        }

        return output
    }

    // MARK: - Classification

    /// True when `component` carries a real, explicitly parsed value.
    ///
    /// `isCertain(_:)` on its own is not enough: `assignNull(_:)` records the sentinel -1 among the
    /// *known* values so a component can neither be implied nor re-read as something else (the week
    /// parsers use it on `.hour`). Such a component is certain but valueless, so both checks are
    /// always paired here.
    private func hasKnownValue(_ components: ParsingComponents, _ component: Component) -> Bool {
        return components.isCertain(component) && components.get(component) != nil
    }

    /// A date: a specific day (`3月1日`, `周一`, `明天`) or a whole ISO week (`下周`, `第12周`).
    /// A result that already spans a range is not a candidate — it would lose its own end date.
    private func isDate(_ result: ParsingResult) -> Bool {
        guard result.end == nil else { return false }
        let start = result.start
        return hasKnownValue(start, .day) || hasKnownValue(start, .isoWeek)
    }

    // MARK: - Text between the matches

    /// The end of a result, in UTF-16 units, clamped to the input. A result's
    /// `index + text.length` can run past the input (some week parsers report a text longer than
    /// their own span), which would otherwise trap in `NSString.substring`.
    private func endOffset(of result: ParsingResult, in nsText: NSString) -> Int {
        let start = max(0, min(result.index, nsText.length))
        return min(start + (result.text as NSString).length, nsText.length)
    }

    /// The text strictly between two results, or nil when they overlap — overlapping matches are
    /// competing readings of one span, never the two ends of a range.
    private func textBetween(_ first: ParsingResult, _ second: ParsingResult, in nsText: NSString) -> String? {
        let gapStart = endOffset(of: first, in: nsText)
        let gapEnd = max(0, min(second.index, nsText.length))
        guard gapEnd >= gapStart else { return nil }
        return nsText.substring(with: NSRange(location: gapStart, length: gapEnd - gapStart))
    }

    // MARK: - Merging

    private func merge(from first: ParsingResult, to second: ParsingResult,
                       context: ParsingContext, nsText: NSString) -> ParsingResult {
        // The span runs from the start of the first match to the end of the second, read out of the
        // original text so the connector between them is reproduced exactly as written.
        let startLocation = max(0, min(first.index, nsText.length))
        let endLocation = max(startLocation, endOffset(of: second, in: nsText))
        let rangeText = nsText.substring(
            with: NSRange(location: startLocation, length: endLocation - startLocation))

        let result = context.createParsingResult(
            index: startLocation,
            text: rangeText,
            start: first.start,
            end: second.start
        )

        // Carry both endpoints' tags forward so later refiners can still tell which parser produced
        // each side of the range.
        for tag in first.getTags() + second.getTags() {
            result.addTag(tag)
        }
        result.addTag("ZHMergeDateRangeRefiner")
        return result
    }

    // MARK: - Ordering

    /// Results ordered by index. The offset tie-breaker keeps results that share an index in their
    /// original relative order, because `sorted(by:)` is not guaranteed stable.
    private func sortedByIndex(_ results: [ParsingResult]) -> [ParsingResult] {
        return results.enumerated()
            .sorted { lhs, rhs in
                lhs.element.index == rhs.element.index
                    ? lhs.offset < rhs.offset
                    : lhs.element.index < rhs.element.index
            }
            .map { $0.element }
    }
}
