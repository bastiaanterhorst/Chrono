// ZHMonthNameParser.swift - Parser for Chinese month-only expressions like "3月" and "2026年3月"
import Foundation

/// Parser for Chinese month-only expressions: `3月`, `2026年3月`, `十月`, `２０２６年１０月`.
///
/// The month number may be written in any of the three scripts, so the pattern is built from
/// `ZHConstants.NUMBER` and read with `ZHConstants.parseNumber` / `parseYear`. Only the month (and
/// year) are set here — the shared `MonthOnlyDayRefiner` implies the 1st for a bare month.
///
/// Two negative lookaheads keep this parser from stealing text that belongs to someone else:
///
/// 1. **A following day marker** hands the phrase back to `ZHStandardParser`, so `3月15日` parses as
///    a full date instead of leaving a stray "March" plus an unclaimed `15日`.
/// 2. **A following direction suffix** (后/後/前/内/內 and their 之/以 forms) keeps a relative
///    phrase from being half-eaten.
///
/// Note that the *relative* month form cannot reach this pattern at all: Chinese requires the
/// measure word 个/個 between the number and 月 (`3个月后` = "in three months"), and that character
/// sits exactly where this pattern demands 月 immediately after the number. `3月` is therefore
/// unambiguously the calendar month March, which is why the relative parsers own 个月 and this one
/// owns 月.
public struct ZHMonthNameParser: Parser {
    public init() {}

    /// Capture groups: 1 = year (optional), 2 = month.
    public func pattern(context: ParsingContext) -> String {
        let year = "(?:(\(ZHConstants.NUMBER))年\\s*)?"
        let month = "(\(ZHConstants.NUMBER))月"
        // A day in any script, in the position a full date would put it.
        let notFollowedByDay = "(?!\\s*(?:\(ZHConstants.ARABIC_NUMBER)|[\(ZHConstants.CHINESE_NUMERAL_CHARS)]{1,6})\\s*(?:日|号|號))"
        let notFollowedByDirection = "(?!\\s*(?:\(ZHConstants.FUTURE_SUFFIX)|\(ZHConstants.PAST_SUFFIX)|\(ZHConstants.WITHIN_SUFFIX)))"
        // 3月底 is the end of March, owned by `ZHPeriodBoundaryParser` — matching 3月 here would
        // leave a stray 底 in the task's name and report the 1st.
        let notFollowedByBoundary = "(?![底初])"
        return year + month + notFollowedByDay + notFollowedByDirection + notFollowedByBoundary
    }

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let monthText = match.string(at: 2),
              let month = ZHConstants.parseNumber(monthText),
              (1...12).contains(month) else {
            return nil
        }

        let components = context.createParsingComponents()
        components.assign(.month, value: month)

        if let yearText = match.string(at: 1) {
            // The group participated, so its text is part of the matched range; an unreadable year
            // rejects the match rather than producing a month whose stated year was dropped.
            guard let statedYear = ZHConstants.parseYear(yearText) else { return nil }
            let year = ZHConstants.normalizeYear(statedYear)
            guard (1...9999).contains(year) else { return nil }
            components.assign(.year, value: year)
        } else {
            components.imply(.year, value: inferYear(context: context, month: month))
        }

        components.addTag("ZHMonthNameParser")
        return components
    }

    /// Picks the year for a month written without one: the reference year, rolled forward to the
    /// next one when the month has already passed and the caller asked for forward dates.
    private func inferYear(context: ParsingContext, month: Int) -> Int {
        let calendar = Calendar.current
        let referenceYear = calendar.component(.year, from: context.refDate)
        let referenceMonth = calendar.component(.month, from: context.refDate)

        guard context.options.forwardDate else { return referenceYear }

        return month < referenceMonth ? referenceYear + 1 : referenceYear
    }
}
