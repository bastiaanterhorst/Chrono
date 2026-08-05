// ZHTimeUnitWithinFormatParser.swift - Parser for "within N units" deadlines like "3天内"
import Foundation

/// Parser for Chinese "within N units" expressions — `3天内`, `两小时之内`, `一周以内`, `一年以內`.
///
/// The `内`/`內` family of suffixes states a *deadline*: `三天内完成` is "finish within three days".
/// Semantically this is the same shape as Dutch `binnen 3 dagen`, and it is modelled identically —
/// the result is the date N units from the reference, with the date portion certain and the clock
/// time certain only when the unit is itself a time unit.
///
/// ## Weeks are allowed here (unlike `ZHNumericRelativeUnitParser`)
///
/// Elsewhere in this locale, week words belong to `ZHRelativeWeekParser` because `下周` names an
/// ISO week. `一周内` is different: it is a *span* ending seven days from now, not a calendar week,
/// and no other parser claims the `内` form — so the week lexicon is folded back in here.
public struct ZHTimeUnitWithinFormatParser: Parser {
    public init() {}

    // MARK: - Guards

    /// Characters that must not directly precede the numeral:
    ///
    /// * **digits** — so a longer run cannot be truncated to its tail;
    /// * **`第`** — `第一周` is "week one", an ordinal; `第一周内容` ("week one's content") is a
    ///   noun phrase, not a deadline;
    /// * **`每`** — `每三天` is a recurrence, not a date.
    ///
    /// No lookahead guards the `内` itself: `三天内容易出错` ("within three days it is easy to get
    /// wrong") is ordinary Chinese, so refusing every `内` followed by `容` would reject more real
    /// deadlines than it would save.
    private static let numberLookbehind = "(?<![0-9０-９第每])"

    // MARK: - Pattern

    /// Capture groups: 1 = number, 2 = unit, 3 = the `内` suffix.
    ///
    /// The unit alternation is the shared time-unit lexicon plus the shared week lexicon, both
    /// already ordered longest-first inside `ZHConstants` so that e.g. `个星期` is never truncated
    /// to `星期`.
    public func pattern(context: ParsingContext) -> String {
        let unit = "(?:" + ZHConstants.TIME_UNIT_WORDS + "|" + ZHConstants.WEEK_UNIT_WORDS + ")"

        return Self.numberLookbehind
            + "(" + ZHConstants.NUMBER + ")\\s*"
            + "(" + unit + ")\\s*"
            + "(" + ZHConstants.WITHIN_SUFFIX + ")"
    }

    // MARK: - Extraction

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let numberText = match.string(at: 1),
              let unitText = match.string(at: 2),
              match.string(at: 3) != nil,
              let value = ZHConstants.parseNumber(numberText) else {
            return nil
        }

        let calendar = Calendar.current
        let targetDate: Date?
        let unitIsTime: Bool

        if let unit = ZHConstants.TIME_UNIT_DICTIONARY[unitText] {
            targetDate = calendar.date(byAdding: unit, value: value, to: context.refDate)
            // Only minutes and hours move the clock; day/month/year leave the time unstated.
            unitIsTime = (unit == .minute || unit == .hour)
        } else {
            // A week word. `ZHConstants.TIME_UNIT_DICTIONARY` deliberately omits these, and a
            // deadline in weeks is simply N × 7 days — the same conversion NL makes for
            // "binnen 3 weken".
            targetDate = calendar.date(byAdding: .day, value: value * 7, to: context.refDate)
            unitIsTime = false
        }

        guard let date = targetDate else { return nil }

        let result = context.createParsingComponents()
        result.assignRelativeDate(from: date, unitIsTime: unitIsTime, calendar: calendar)
        result.addTag("ZHTimeUnitWithinFormatParser")
        return result
    }
}
