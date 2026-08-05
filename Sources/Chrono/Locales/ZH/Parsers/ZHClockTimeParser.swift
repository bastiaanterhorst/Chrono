// ZHClockTimeParser.swift - Parser for colon clock times like "15:30" and "下午3:30"
import Foundation

/// Parser for colon-separated Chinese clock times: `15:30`, `下午3:30`, `15：30` (full-width colon),
/// `9:05:30`, `晚上8：15`.
///
/// The Japanese locale has a documented gap here — `15:00` does not parse in JA, because
/// `JATimeExpressionParser` only recognises the 時 form and nothing else picks up a bare colon time.
/// **ZH deliberately closes that gap**: digital clock times are as common in Chinese task input as
/// 点 times, so they get a parser of their own rather than being left to the shared ISO formats.
///
/// Meridiem handling is shared verbatim with `ZHTimeExpressionParser` through `ZHTimeOfDayPrefix`,
/// so `下午3:30` and `下午3点30分` can never drift apart.
public struct ZHClockTimeParser: Parser {
    public init() {}

    /// Capture groups: 1 = time-of-day prefix (optional), 2 = hour, 3 = minute, 4 = second (optional).
    ///
    /// The digit/colon lookbehind and lookahead keep the match from starting or ending inside a
    /// longer run, so version strings and ratios like `1:2:3:4` are not sliced into a time. Minutes
    /// and seconds require exactly two digits, per the shared `numeric-time-validation` rule that
    /// keeps `3:2` (a score) from parsing.
    public func pattern(context: ParsingContext) -> String {
        let prefix = "(?:(\(ZHConstants.TIME_OF_DAY_WORDS)|[AaPp][Mm])\\s*)?"
        let time = "(?<![0-9０-９:：])([0-9０-９]{1,2})[:：]([0-9０-９]{2})(?:[:：]([0-9０-９]{2}))?(?![0-9０-９:：])"
        return prefix + time
    }

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let hourText = match.string(at: 2),
              let writtenHour = ZHConstants.parseNumber(hourText),
              let minuteText = match.string(at: 3),
              let minute = ZHConstants.parseNumber(minuteText) else {
            return nil
        }

        let second: Int?
        if let secondText = match.string(at: 4) {
            guard let parsed = ZHConstants.parseNumber(secondText) else { return nil }
            second = parsed
        } else {
            second = nil
        }

        // Validation (openspec spec `numeric-time-validation`): a prefix puts the hour on the
        // 12-hour clock, otherwise it is a 24-hour reading; minutes and seconds are always 0-59.
        // Out-of-range values reject the match instead of overflowing into a later day.
        guard minute <= 59, (second ?? 0) <= 59 else { return nil }

        let prefixText = match.string(at: 1)
        let prefix = prefixText.flatMap(ZHTimeOfDayPrefix.init)
        if prefixText != nil {
            guard prefix != nil else { return nil }
            guard writtenHour <= 12 else { return nil }
        } else {
            guard writtenHour <= 23 else { return nil }
        }

        let components = context.createParsingComponents()
        let hour = prefix?.hour(fromWritten: writtenHour) ?? writtenHour

        components.assign(.hour, value: hour)
        components.assign(.minute, value: minute)

        if let second {
            components.assign(.second, value: second)
        } else {
            components.imply(.second, value: 0)
        }

        if let meridiem = prefix?.meridiem(forWrittenHour: writtenHour) {
            components.assign(.meridiem, value: meridiem.rawValue)
        } else {
            components.imply(.meridiem, value: hour < 12 ? Meridiem.am.rawValue : Meridiem.pm.rawValue)
        }

        components.addTag("ZHClockTimeParser")
        return components
    }
}
