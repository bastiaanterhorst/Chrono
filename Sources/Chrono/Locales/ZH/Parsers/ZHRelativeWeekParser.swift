// ZHRelativeWeekParser.swift - Parser for relative week and weekend expressions in Chinese
import Foundation

/// Parser for relative week expressions in Chinese — `这周`, `下个星期`, `上上礼拜`, `三周后` — and
/// for weekends, `这个周末` / `下周末` / `周末`.
///
/// Three pieces of linguistic reasoning shape the pattern:
///
/// 1. **Weekends must be matched before bare weeks.** `下周末` is 下 + 周末 ("next weekend"), but it
///    literally contains `下周` ("next week"). Listing the weekend alternatives first makes the regex
///    engine claim the whole phrase at the same start position instead of leaving a stray `末` behind.
///    A weekend resolves to a concrete DAY (Saturday) via `WeekendResolver`, not to an ISO week.
///
/// 2. **A bare week must not swallow a weekday.** `下周三` is "next Wednesday" and belongs to
///    `ZHWeekdayParser`; `下周` + `三` would be nonsense. Chinese has no word boundaries — ICU treats
///    every Han character as `\w`, so `\b` never fires between two of them — therefore the bare-week
///    alternative ends in an explicit negative lookahead over the weekday characters (and `末`)
///    rather than in a boundary assertion.
///
/// 3. **A bare 周/週 is never a week.** It opens 周围, 周到 and the surname 周, so every alternative
///    here requires either an offset prefix (`这`/`下`/`上`…), a count, or the 末 of 周末.
///
/// 4. **`每` marks a recurrence, not a date.** `每周末` is "every weekend" — a repeat rule the host
///    schedules, never a specific Saturday — exactly like `每天` ("daily"), which the ZH lexicon
///    already refuses. Only the weekend alternatives need `recurrenceGuard`: the bare-week and
///    count alternatives require an offset prefix or a number, and `每` is neither, so `每周`
///    already falls through.
///
/// Counts accept all three scripts a Chinese writer may use — `3周后`, `３周后`, `三周后`, `两周后` —
/// through `ZHConstants.NUMBER` / `ZHConstants.parseNumber`.
final class ZHRelativeWeekParser: AbstractParserWithWordBoundaryChecking, @unchecked Sendable {

    /// The optional measure word between an offset prefix (or a count) and the week noun:
    /// 下个星期 / 下個星期 / 下星期 are all "next week".
    private static let measureWord = "(?:个|個)?"

    /// Characters that, following a week noun, mean the phrase is *not* a bare week:
    /// 一…六/日/天 name a weekday (下周三 = next Wednesday) and 末 makes it a weekend (下周末).
    private static let bareWeekGuard = "(?![一二三四五六日天末])"

    /// `每` in front of a week noun makes the phrase a recurrence (每周末 = "every weekend"), which is
    /// a repeat rule rather than a date. A lookbehind, not `\b`: Han is `\w` to ICU.
    ///
    /// Three of them, because 每 may be separated from the noun by the measure word — 每个周末 is as
    /// ordinary as 每周末 — and a lookbehind is fixed-width, so each distance needs its own.
    private static let recurrenceGuard = "(?<!每)(?<!每个)(?<!每個)"

    // Capture-group layout of `innerPattern`. These are the only capturing groups in the pattern, so
    // the indices are stable, and `innerExtract` can dispatch on *which* alternative matched instead
    // of inspecting substrings.
    private static let weekendPrefixGroup = 1
    private static let weekPrefixGroup = 2
    private static let weeksLaterGroup = 3
    private static let weeksAgoGroup = 4

    override func innerPattern(context: ParsingContext) -> String {
        let measure = Self.measureWord
        let weekWord = ZHConstants.WEEK_WORD

        // 这个周末 / 下周末 / 下下星期末 / 上礼拜末 — the prefix is captured for `offset(forPrefix:)`.
        let prefixedWeekend = "(?:\(Self.recurrenceGuard)(\(ZHConstants.OFFSET_PREFIX))\(measure)\(weekWord)末)"

        // Bare 周末 / 週末 means *this* weekend. Only the clipped noun forms a bare weekend word;
        // 星期末 and 礼拜末 are not idiomatic on their own. This is where `recurrenceGuard` bites:
        // 每周末 is 每 + 周末, so without it the bare alternative would claim the 周末 one index in.
        let bareWeekend = "(?:\(Self.recurrenceGuard)(?:周|週)末)"

        // 这周 / 这个星期 / 下星期 / 下下个星期 / 上上周 / 上礼拜 … — one generative alternative over the
        // shared prefix and week-noun lexicons, guarded so weekdays and weekends fall through.
        let bareWeek = "(?:(\(ZHConstants.OFFSET_PREFIX))\(measure)\(weekWord)\(Self.bareWeekGuard))"

        // 三周后 / 2个星期以后 / 两周之后. The `(?<!第)` leaves 第10周后 to the week-number parser:
        // 第N周 is an ordinal week, never an offset.
        let weeksLater = "(?:(?<!第)(\(ZHConstants.NUMBER))\(measure)\(weekWord)\(ZHConstants.FUTURE_SUFFIX))"

        // 三周前 / 2个星期以前 / 两周之前.
        let weeksAgo = "(?:(?<!第)(\(ZHConstants.NUMBER))\(measure)\(weekWord)\(ZHConstants.PAST_SUFFIX))"

        return [
            prefixedWeekend,
            bareWeekend,
            bareWeek,
            weeksLater,
            weeksAgo
        ].joined(separator: "|")
    }

    override func innerExtract(context: ParsingContext, match: TextMatch) -> Any? {
        // Inspect only the matched substring so trailing text and other phrases don't leak in.
        let matched = match.string(at: 0) ?? match.text
        let matchedText = matched.trimmingCharacters(in: .whitespacesAndNewlines)
        let matchIndex = match.startIndex(at: 0) ?? match.index
        let referenceDate = context.reference.instant
        let calendar = context.weekCalendar

        let weekOffset: Int
        let isWeekend: Bool

        if let prefix = capturedText(match: match, at: Self.weekendPrefixGroup) {
            weekOffset = ZHConstants.offset(forPrefix: prefix) ?? 0
            isWeekend = true
        } else if let prefix = capturedText(match: match, at: Self.weekPrefixGroup) {
            weekOffset = ZHConstants.offset(forPrefix: prefix) ?? 0
            isWeekend = false
        } else if let count = capturedNumber(match: match, at: Self.weeksLaterGroup) {
            weekOffset = count
            isWeekend = false
        } else if let count = capturedNumber(match: match, at: Self.weeksAgoGroup) {
            weekOffset = -count
            isWeekend = false
        } else {
            // The only alternative without a capture group is the bare 周末 — this weekend.
            weekOffset = 0
            isWeekend = true
        }

        // A weekend is a concrete DAY (the first weekend day of that week), not an ISO week, so it
        // is resolved and returned before the week-level component assignment below.
        if isWeekend {
            guard let components = WeekendResolver.weekendComponents(
                context: context, weekOffset: weekOffset, localeIdentifier: "zh") else {
                return nil
            }
            components.addTag("ZHRelativeWeekParser")
            return context.createParsingResult(index: matchIndex, text: matchedText, start: components)
        }

        guard let targetDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: referenceDate) else {
            return nil
        }

        let targetWeek = calendar.component(.weekOfYear, from: targetDate)
        let targetWeekYear = calendar.component(.yearForWeekOfYear, from: targetDate)
        let components = ParsingComponents(reference: context.reference)
        components.assign(.isoWeek, value: targetWeek)
        components.assign(.isoWeekYear, value: targetWeekYear)
        components.assignNull(.hour)

        // A relative week is anchored to its Monday, matching every other locale's week parser.
        var dateComponents = DateComponents()
        dateComponents.weekOfYear = targetWeek
        dateComponents.yearForWeekOfYear = targetWeekYear
        dateComponents.weekday = context.weekCalendar.firstWeekday
        dateComponents.hour = 12
        dateComponents.minute = 0
        dateComponents.second = 0

        if let weekStart = calendar.date(from: dateComponents) {
            let dayComponents = calendar.dateComponents([.year, .month, .day], from: weekStart)
            if let year = dayComponents.year, let month = dayComponents.month, let day = dayComponents.day {
                components.assign(.year, value: year)
                components.assign(.month, value: month)
                components.assign(.day, value: day)
            }
        }

        let result = context.createParsingResult(index: matchIndex, text: matchedText, start: components)
        result.addTag("ZHRelativeWeekParser")
        return result
    }

    /// The text of a capture group, or nil when that alternative took no part in the match.
    private func capturedText(match: TextMatch, at index: Int) -> String? {
        guard index < match.captureCount, let text = match.string(at: index), !text.isEmpty else {
            return nil
        }
        return text
    }

    /// The value of a capture group written in ASCII, full-width, or Chinese numerals.
    private func capturedNumber(match: TextMatch, at index: Int) -> Int? {
        guard let text = capturedText(match: match, at: index) else { return nil }
        return ZHConstants.parseNumber(text)
    }
}
