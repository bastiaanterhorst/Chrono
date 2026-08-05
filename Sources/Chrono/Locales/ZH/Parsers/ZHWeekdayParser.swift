// ZHWeekdayParser.swift - Parser for Chinese weekday mentions (星期四, 周三, 下个星期一 …)
import Foundation

/// Parser for Chinese weekday expressions: 星期四 / 周三 / 礼拜日, optionally carrying a week-offset
/// prefix (这周五, 本周五, 上周五, 下周三, 下下周三) and the optional measure word 个/個 (下个星期一).
///
/// **The weekday character is required, and that is what makes this parser safe.** Chinese has no
/// word boundaries and ICU classifies Han ideographs as `\w`, so `\b` never fires between two Han
/// characters — exactly the problem `JAWeekdayParser` solves by requiring the disambiguating 曜.
/// Here the disambiguator is the trailing day character: a bare 周/週/星期 is never a weekday, since
/// 周围, 周到 and the surname 周先生 all begin that way and none of them continues with one of
/// 一二三四五六日天. A bare 上周/下周 — a whole week rather than a day — is likewise left alone; it
/// belongs to `ZHRelativeWeekParser`.
///
/// The two readings Chinese actually has are kept apart:
/// - **No prefix** (周三) → the next occurrence of that weekday, with the reference day itself
///   counting as that occurrence — identical to `JAWeekdayParser`.
/// - **With a prefix** (下周三) → that weekday *within* the week at the given offset, anchored on the
///   Monday of the reference date's ISO week. Because ISO weeks run Monday…Sunday, 下周日 is the
///   Sunday that *ends* next week, not merely the next Sunday to come.
///
/// Either way the result is one specific day, so `.isoWeek` is deliberately never assigned.
public struct ZHWeekdayParser: Parser {
    public init() {}

    public func pattern(context: ParsingContext) -> String {
        // The leading `每` lookbehinds keep a recurrence out: 每周三 is "every Wednesday", a repeat
        // rule rather than a date, exactly like 每天 ("daily") and 每周末 ("every weekend"). A
        // lookbehind is the only option — Han is `\w` to ICU, so `\b` never fires between two Han
        // characters — and it takes three of them because the measure word may sit in between
        // (每个星期三) and a lookbehind is fixed-width.
        // Group 1: the week-offset prefix. `OFFSET_PREFIX` already lists 上上/下下 before 上/下, which
        // it must — otherwise 下下周三 would match the inner 下周三 one index later.
        // Group 2: the required weekday character (日 and 天 both mean Sunday).
        return "(?<!每)(?<!每个)(?<!每個)"
            + "(" + ZHConstants.OFFSET_PREFIX + ")?"
            + "(?:个|個)?"
            + ZHConstants.WEEK_WORD
            + "(" + ZHConstants.WEEKDAY_CHARS + ")"
    }

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let weekdayCharacter = match.string(at: 2),
              let weekday = ZHConstants.WEEKDAY_DICTIONARY[weekdayCharacter] else {
            return nil
        }

        let refDate = context.refDate
        let resolvedDate: Date?

        if let prefix = match.string(at: 1), let weekOffset = ZHConstants.offset(forPrefix: prefix) {
            resolvedDate = date(of: weekday, inWeekOffsetBy: weekOffset, from: refDate)
        } else {
            resolvedDate = nextOccurrence(of: weekday, from: refDate)
        }

        guard let targetDate = resolvedDate else { return nil }

        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)
        guard let year = dateComponents.year,
              let month = dateComponents.month,
              let day = dateComponents.day else {
            return nil
        }

        let components = context.createParsingComponents()
        components.assign(.year, value: year)
        components.assign(.month, value: month)
        components.assign(.day, value: day)
        // Sun=0 … Sat=6, the numbering used across this library; cross-locale refiners read it.
        components.assign(.weekday, value: weekday)
        // No clock time was named, so midday is only implied.
        components.imply(.hour, value: 12)
        components.addTag("ZHWeekdayParser")
        return components
    }

    // MARK: - Helpers

    /// The next occurrence of `weekday`, with the reference day itself counting as that occurrence
    /// (周三 said on a Wednesday means today).
    private func nextOccurrence(of weekday: Int, from refDate: Date) -> Date? {
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: refDate) - 1 // Sun=0 … Sat=6
        var daysToAdd = weekday - currentWeekday
        if daysToAdd < 0 { daysToAdd += 7 }
        return calendar.date(byAdding: .day, value: daysToAdd, to: refDate)
    }

    /// `weekday` inside the ISO week that sits `weekOffset` weeks from the reference date's own week.
    ///
    /// The anchor is the Monday of the reference's ISO week; from there the shift is
    /// `weekOffset * 7 + daysFromMonday`. ISO weeks run Monday…Sunday, so Sunday is day 6 of its
    /// week rather than day 0 — that is what makes 下周日 land at the *end* of next week.
    private func date(of weekday: Int, inWeekOffsetBy weekOffset: Int, from refDate: Date) -> Date? {
        var calendar = Calendar(identifier: .iso8601)
        calendar.firstWeekday = 2 // Monday

        let referenceWeekday = calendar.component(.weekday, from: refDate) // 1=Sun … 7=Sat
        let referenceDaysFromMonday = referenceWeekday == 1 ? 6 : referenceWeekday - 2
        let daysFromMonday = weekday == 0 ? 6 : weekday - 1 // Mon=0 … Sat=5, Sun=6

        let shift = -referenceDaysFromMonday + weekOffset * 7 + daysFromMonday
        return calendar.date(byAdding: .day, value: shift, to: refDate)
    }
}
