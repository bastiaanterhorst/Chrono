// ZHMergeDateTimeRefiner.swift - Merge an adjacent Chinese date and time into one result
import Foundation

/// Merges a date-only result with the time-only result that immediately follows it:
/// `明天下午3点` → tomorrow at 15:00, `3月15日 14:30` → that day at 14:30, `明天的下午3点`,
/// `明天早上9点`, `下周三上午10点`, `2026年3月15日晚上8点`.
///
/// Why Chinese needs its own rule: the Latin locales key their merge on a connector *word*
/// ("om", "at", "à") and therefore always expect a non-empty gap between the two matches. Chinese
/// writes no spaces, so the normal gap here is **zero characters** — `明天` and `下午3点` abut.
/// When a connector is present at all it is a single particle (`的`, `在`, `于`, `於`) or a comma.
///
/// The gap is capped at two UTF-16 units and every non-space character in it must come from that
/// particle set, which is what keeps two unrelated dates elsewhere in a long sentence from being
/// welded together. The rule is purely structural: it never inspects the surrounding sentence.
public struct ZHMergeDateTimeRefiner: Refiner {
    public init() {}

    /// The particles that may sit between a date and the time belonging to it.
    ///
    /// `的` is the attributive marker (`明天的下午3点`), `在`/`于`/`於` are the locative prepositions
    /// ("at"), and the two commas cover `3月15日，下午3点`. Whitespace — including the ideographic
    /// space U+3000, which `CharacterSet.whitespaces` covers — is trimmed away before this set is
    /// consulted, so it needs no entry of its own.
    private static let connectorCharacters: Set<Character> = ["的", "在", "于", "於", "，", ","]

    /// The widest gap, in UTF-16 units, tolerated between the date match and the time match.
    /// Two is enough for `，` plus a space, or a particle plus a space; anything longer is prose.
    private static let maximumGapLength = 2

    /// The components copied from the time match onto the date. `.millisecond` and
    /// `.timezoneOffset` are carried too because an ISO-style time match can supply them.
    private static let clockComponents: [Component] = [
        .hour, .minute, .second, .millisecond, .meridiem, .timezoneOffset
    ]

    public func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        guard results.count >= 2 else { return results }

        let nsText = context.text as NSString
        let ordered = sortedByIndex(results)

        var output: [ParsingResult] = []
        var i = 0

        while i < ordered.count {
            let dateResult = ordered[i]

            if i + 1 < ordered.count {
                let timeResult = ordered[i + 1]
                if isDateOnly(dateResult),
                   isTimeOnly(timeResult),
                   let gap = textBetween(dateResult, timeResult, in: nsText),
                   isMergeableGap(gap) {
                    output.append(merge(date: dateResult, time: timeResult, context: context, nsText: nsText))
                    i += 2 // both results are consumed by the merge
                    continue
                }
            }

            // Anything that does not take part in a merge survives untouched.
            output.append(dateResult)
            i += 1
        }

        return output
    }

    // MARK: - Classification

    /// True when `component` carries a real, explicitly parsed value.
    ///
    /// `isCertain(_:)` on its own is not enough: `assignNull(_:)` records the sentinel -1 among the
    /// *known* values to stop a component from being implied, and every week parser applies it to
    /// `.hour` so a week number is never read back as a clock time. Such a component reports
    /// `isCertain == true` while `get` returns nil, so both checks are always paired here —
    /// otherwise `下周三上午10点` would look like a result that already knows its hour and would
    /// never merge.
    private func hasKnownValue(_ components: ParsingComponents, _ component: Component) -> Bool {
        return components.isCertain(component) && components.get(component) != nil
    }

    /// A date: a specific day (or a whole ISO week, for `第12周` / `下周`) and no clock time of its
    /// own. Results that already span a range are left alone — their end date would be lost.
    private func isDateOnly(_ result: ParsingResult) -> Bool {
        guard result.end == nil else { return false }
        let start = result.start
        let namesADate = hasKnownValue(start, .day) || hasKnownValue(start, .isoWeek)
        return namesADate && !hasKnownValue(start, .hour)
    }

    /// A time: a clock hour that names no day of its own.
    private func isTimeOnly(_ result: ParsingResult) -> Bool {
        guard result.end == nil else { return false }
        let start = result.start
        return hasKnownValue(start, .hour)
            && !hasKnownValue(start, .day)
            && !hasKnownValue(start, .isoWeek)
    }

    // MARK: - Text between the matches

    /// The end of a result, in UTF-16 units, clamped to the input. A result's
    /// `index + text.length` can run past the input (some week parsers report a text longer than
    /// their own span), which would otherwise trap in `NSString.substring`.
    private func endOffset(of result: ParsingResult, in nsText: NSString) -> Int {
        let start = max(0, min(result.index, nsText.length))
        return min(start + (result.text as NSString).length, nsText.length)
    }

    /// The text strictly between two results, or nil when they overlap (in which case they are
    /// alternative readings of the same span, not two halves of one phrase).
    private func textBetween(_ first: ParsingResult, _ second: ParsingResult, in nsText: NSString) -> String? {
        let gapStart = endOffset(of: first, in: nsText)
        let gapEnd = max(0, min(second.index, nsText.length))
        guard gapEnd >= gapStart else { return nil }
        return nsText.substring(with: NSRange(location: gapStart, length: gapEnd - gapStart))
    }

    /// Whether a gap is short enough, and made only of connector particles and whitespace, for the
    /// two matches to be one phrase. An empty gap — the common Chinese case — passes trivially.
    private func isMergeableGap(_ gap: String) -> Bool {
        guard (gap as NSString).length <= Self.maximumGapLength else { return false }
        let trimmed = gap.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.allSatisfy { Self.connectorCharacters.contains($0) }
    }

    // MARK: - Merging

    private func merge(date: ParsingResult, time: ParsingResult,
                       context: ParsingContext, nsText: NSString) -> ParsingResult {
        // Start from the date so everything it established survives — year/month/day, and also the
        // ISO week behind an expression like 下周三 — then overwrite the clock fields from the time.
        let merged = date.start.clone()
        for component in Self.clockComponents {
            guard let value = time.start.get(component) else { continue }
            if time.start.isCertain(component) {
                merged.assign(component, value: value)
            } else {
                // A merely implied minute/second (`下午3点` implies :00) stays implied, so
                // `isCertain` keeps meaning "the user actually said this".
                merged.imply(component, value: value)
            }
        }

        // The time always follows the date here, so the date's index is the earlier one.
        let startLocation = max(0, min(date.index, nsText.length))
        let endLocation = max(startLocation, endOffset(of: time, in: nsText))
        let mergedText = nsText.substring(
            with: NSRange(location: startLocation, length: endLocation - startLocation))

        let result = context.createParsingResult(
            index: startLocation,
            text: mergedText,
            start: merged
        )

        // Carry both halves' tags forward so later refiners (notably ZHPrioritizeWeekNumberRefiner)
        // can still tell which parser the date came from.
        for tag in date.getTags() + time.getTags() {
            result.addTag(tag)
        }
        result.addTag("ZHMergeDateTimeRefiner")
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
