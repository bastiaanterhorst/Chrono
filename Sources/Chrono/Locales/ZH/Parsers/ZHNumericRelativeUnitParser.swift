// ZHNumericRelativeUnitParser.swift - Parser for numeric relative offsets like "3天后" and "过两天"
import Foundation

/// Parser for Chinese numeric relative-unit expressions — `3天后`, `两个月前`, `30分钟后`, `5年后`,
/// `过3天`, `再过两天`, `半小时后`.
///
/// Chinese expresses "N units from now" in two shapes:
///
/// * a **suffix** carries the direction — `后`/`後` ("after") or `前` ("before") — after the
///   number-plus-unit: `3天后`, `两个月前`;
/// * the **prefix** `过`/`過` ("let … pass") introduces the amount instead: `过3天`, `再过两天`.
///   That form is inherently forward-looking; it has no past reading.
///
/// On top of those, `半小时后` ("in half an hour") is idiomatic enough to deserve its own branch:
/// it carries no numeral at all, so neither of the two general shapes can reach it.
///
/// ## Units deliberately excluded
///
/// - **A bare `分`.** `十分` overwhelmingly reads as "very" (`十分重要` = "very important"), not
///   "ten minutes". Only the unambiguous `分钟`/`分鐘` counts as a minute unit.
/// - **A bare `月`.** `3月` is *March*, not "three months" — the relative reading requires the
///   measure word, i.e. `个月`/`個月`. Bare `3月` belongs to the month-name parser.
/// - **Weeks** (`周`/`週`/`星期`/`礼拜`). A Chinese week expression resolves to an ISO week rather
///   than a plain day offset, so `ZHRelativeWeekParser` owns every week form; matching them here
///   would produce a second, weaker result for the same text.
///
/// The first two exclusions are baked into `ZHConstants.TIME_UNIT_DICTIONARY` /
/// `ZHConstants.TIME_UNIT_WORDS`; the third is why this file uses `TIME_UNIT_WORDS` and never
/// `ZHConstants.WEEK_UNIT_WORDS`.
public struct ZHNumericRelativeUnitParser: Parser {
    public init() {}

    // MARK: - Guards

    /// Characters that must not directly precede the numeral:
    ///
    /// * **digits** — so a long run such as `12345天后` cannot be silently truncated to its last
    ///   four digits;
    /// * **`月` / `年` / `号` / `號`** — a numeral right after one of these belongs to a written
    ///   date, so `2月3日后` ("after February 3rd") must not be read as "three days later";
    /// * **`第`** — `第三天` is the *third* day of a sequence, an ordinal rather than an offset;
    /// * **`每`** — `每3天` is a recurrence ("every three days"), not a date.
    private static let numberLookbehind = "(?<![0-9０-９月年号號第每])"

    /// Characters that form a fixed compound ending in `过`/`過`, where that `过` is part of another
    /// word and cannot introduce a time offset: 超过 ("exceed"), 不过 ("but / only"), 通过, 经过,
    /// 路过, 错过, 度过, 渡过, 难过, 胜过, 越过, 透过, 好过. Without this guard `超过3天` ("more
    /// than three days") would be mis-read as `过3天` ("in three days").
    private static let passLookbehind = "(?<![超不通经經路错錯度渡难難胜勝越透好])"

    /// `半` must not be preceded by a numeral or a measure word: `一个半小时后` is *one and a half*
    /// hours from now, and answering "30 minutes" there would be worse than not matching at all.
    private static let halfLookbehind = "(?<![0-9０-９〇零一二两兩三四五六七八九十百个個])"

    // MARK: - Pattern

    /// Capture groups, in order:
    ///
    /// | Group | Form   | Meaning                                      |
    /// |-------|--------|----------------------------------------------|
    /// | 1     | suffix | number (`3`, `两`, `３`)                       |
    /// | 2     | suffix | time unit (`天`, `个月`, `分钟`, …)             |
    /// | 3     | suffix | direction (`后`/`後`/`之后`… or `前`/`之前`…)    |
    /// | 4     | prefix | number                                       |
    /// | 5     | prefix | time unit                                    |
    /// | 6     | half   | direction (future only)                      |
    ///
    /// Every fragment borrowed from `ZHConstants` is a non-capturing group, so these indices are
    /// stable.
    public func pattern(context: ParsingContext) -> String {
        let number = ZHConstants.NUMBER
        let unit = ZHConstants.TIME_UNIT_WORDS

        // 3天后 · 两个月前 · 30分钟后 · 2小时后 · 5年后
        let suffixForm =
            Self.numberLookbehind
            + "(" + number + ")\\s*"
            + "(" + unit + ")\\s*"
            + "(" + ZHConstants.FUTURE_SUFFIX + "|" + ZHConstants.PAST_SUFFIX + ")"

        // 过3天 · 再过两天 · 過5年 — always future.
        let prefixForm =
            "(?:再\\s*)?" + Self.passLookbehind + "[过過]\\s*"
            + Self.numberLookbehind
            + "(" + number + ")\\s*"
            + "(" + unit + ")"

        // 半小时后 · 半个小时之后 · 半个月后 · 半年后 · 半天后 — half of a unit, always forward.
        // Group 6 is the unit, group 7 the direction.
        let halfForm =
            Self.halfLookbehind
            + "半\\s*(?:个|個)?\\s*(小时|小時|月|年|天)\\s*"
            + "(" + ZHConstants.FUTURE_SUFFIX + ")"

        return "(?:" + suffixForm + "|" + prefixForm + "|" + halfForm + ")"
    }

    // MARK: - Extraction

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        // Suffix form — the direction word decides the sign.
        if let numberText = match.string(at: 1),
           let unitText = match.string(at: 2),
           let directionText = match.string(at: 3) {
            guard let value = ZHConstants.parseNumber(numberText),
                  let unit = ZHConstants.TIME_UNIT_DICTIONARY[unitText] else {
                return nil
            }
            // Every past suffix (前 / 之前 / 以前) ends in 前; every future one ends in 后 / 後.
            let offset = directionText.hasSuffix("前") ? -value : value
            return relativeComponents(context: context, unit: unit, offset: offset)
        }

        // Prefix form — 过 means "let N units pass", so it is unconditionally future.
        if let numberText = match.string(at: 4),
           let unitText = match.string(at: 5) {
            guard let value = ZHConstants.parseNumber(numberText),
                  let unit = ZHConstants.TIME_UNIT_DICTIONARY[unitText] else {
                return nil
            }
            return relativeComponents(context: context, unit: unit, offset: value)
        }

        // Half form — no numeral to read, the amount is half of whatever unit was named. Each is
        // expressed in the largest unit that divides evenly, so the result stays exact: half a month
        // is fifteen days rather than a fractional month.
        if let unitText = match.string(at: 6), match.string(at: 7) != nil {
            switch unitText {
            case "小时", "小時": return relativeComponents(context: context, unit: .minute, offset: 30)
            case "天": return relativeComponents(context: context, unit: .hour, offset: 12)
            case "月": return relativeComponents(context: context, unit: .day, offset: 15)
            case "年": return relativeComponents(context: context, unit: .month, offset: 6)
            default: return nil
            }
        }

        return nil
    }

    /// Offsets the reference date and turns it into components.
    ///
    /// Minutes and hours move a point in *time*, so the resulting clock time is part of what the
    /// user actually said and must come out certain. Day/month/year offsets leave the time of day
    /// unspecified, so it stays merely implied — `assignRelativeDate(from:unitIsTime:)` encodes
    /// exactly that distinction.
    private func relativeComponents(
        context: ParsingContext,
        unit: Calendar.Component,
        offset: Int
    ) -> ParsingComponents? {
        let calendar = Calendar.current

        guard let targetDate = calendar.date(byAdding: unit, value: offset, to: context.refDate) else {
            return nil
        }

        let unitIsTime = (unit == .minute || unit == .hour)

        let result = context.createParsingComponents()
        result.assignRelativeDate(from: targetDate, unitIsTime: unitIsTime, calendar: calendar)
        result.addTag("ZHNumericRelativeUnitParser")
        return result
    }
}
