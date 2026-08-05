// ZHCasualDateParser.swift - Parser for Chinese casual date words (今天, 明天, 后天, 今晚, 下午 …)
import Foundation

/// Parser for Chinese casual date references. It covers three families of words:
///
/// 1. **Day words** — 今天/今日/本日, 明天/明日/明儿, 后天, 大后天, 昨天/昨日, 前天, 大前天. These name a
///    specific calendar day, so year/month/day are assigned as *known* values and no clock time is
///    invented: 明天 says nothing about the hour.
/// 2. **Day + time-of-day compounds** — 今晚, 今早, 明早, 明晚, 昨晚 … Each names a day *and* a rough
///    hour (evening = 22:00, morning = 06:00), mirroring the Japanese locale's 今夜/今朝 choices so
///    the two CJK locales agree.
/// 3. **Bare time-of-day words** — 上午, 中午, 下午, 傍晚, 晚上, 半夜 … They attach to the reference day
///    and take their hour from `ZHConstants.TIME_OF_DAY_HOURS`.
///
/// Chinese has no word boundaries, and ICU classifies Han ideographs as `\w`, so `\b` never fires
/// between two Han characters — the boundary discipline every Latin locale relies on is unavailable.
/// Like the Japanese locale, this parser therefore matches *compounds only*, never a bare single
/// character: 今天 is safe, whereas a bare 天 would fire inside 天气/聊天/白天/每天 and a bare 日 inside
/// 生日/日本. Where a compound is still ambiguous it carries an explicit lookaround instead:
///
/// - `本日` is guarded against a preceding 日 so it cannot be cut out of 日本日期 (日本 + 日期).
/// - `前天` is guarded against a preceding 以/之 so 以前天气 stays 以前 + 天气 rather than 以 + 前天 + 气.
/// - The bare time-of-day words are guarded against a following clock time, because 下午3点 is *one*
///   expression owned by `ZHTimeExpressionParser`; matching 下午 here would split it in two.
public struct ZHCasualDateParser: Parser {
    public init() {}

    // MARK: - Lexicon

    /// A day word and the day offset it names, in the order it enters the pattern.
    ///
    /// Order is load-bearing: a regex alternation is tried left to right at each index, so the
    /// longer token has to come first. With 后天 listed before 大后天 the engine would fail at the 大
    /// and then match 后天 one index later, reporting "+2 days" for 大后天.
    ///
    /// `guardPattern` is a zero-width lookaround emitted before the token; the matched text is
    /// still the bare token, so it stays the lookup key.
    private static let dayWords: [(token: String, guardPattern: String, offset: Int)] = [
        ("今天", "", 0),
        ("今日", "", 0),
        ("本日", "(?<!日)", 0),        // 日本日期 must not yield 本日
        ("明天", "", 1),
        ("明日", "", 1),
        ("明儿", "", 1),
        ("明兒", "", 1),
        ("大后天", "", 3),             // before 后天
        ("大後天", "", 3),
        ("后天", "", 2),
        ("後天", "", 2),
        ("昨天", "", -1),
        ("昨日", "", -1),
        ("大前天", "", -3),            // before 前天
        ("前天", "(?<![以之])", -2)     // 以前天气 must not yield 前天
    ]

    /// A word that names a day *and* a time of day, with the hour and half-of-day it implies.
    private static let dayTimeWords: [(token: String, offset: Int, hour: Int, meridiem: Meridiem)] = [
        ("今晚", 0, 22, .pm),
        ("今夜", 0, 22, .pm),
        ("今早", 0, 6, .am),
        ("今晨", 0, 6, .am),
        ("明早", 1, 6, .am),
        ("明晨", 1, 6, .am),
        ("明晚", 1, 22, .pm),
        ("明夜", 1, 22, .pm),
        ("昨晚", -1, 22, .pm),
        ("昨夜", -1, 22, .pm)
    ]

    /// Rejects a time-of-day word that is immediately followed by a clock time. 下午3点 / 晚上八点 are
    /// single expressions claimed by `ZHTimeExpressionParser`; without this the bare word would take
    /// 下午 and leave a stray 3点 behind, producing two results for one phrase.
    private static var notFollowedByClockTime: String {
        "(?!\\s*" + ZHConstants.NUMBER + "\\s*[点點时時])"
    }

    // MARK: - Parser

    public func pattern(context: ParsingContext) -> String {
        // Day+time compounds first: they are the most specific reading of their opening character
        // (今夜 must win over the bare 夜里 in 今夜里).
        let dayTimePattern = ZHCasualDateParser.dayTimeWords.map(\.token).joined(separator: "|")
        let dayPattern = ZHCasualDateParser.dayWords
            .map { $0.guardPattern + $0.token }
            .joined(separator: "|")
        let timeOfDayPattern = ZHConstants.TIME_OF_DAY_WORDS + ZHCasualDateParser.notFollowedByClockTime

        return "(?:" + dayTimePattern + "|" + dayPattern + "|" + timeOfDayPattern + ")"
    }

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let text = match.matchedText
        let components = context.createParsingComponents()

        if let word = ZHCasualDateParser.dayTimeWords.first(where: { $0.token == text }) {
            guard assignDay(components, offsetBy: word.offset, context: context) else { return nil }
            components.assign(.hour, value: word.hour)
            components.assign(.minute, value: 0)
            components.assign(.meridiem, value: word.meridiem.rawValue)
        } else if let word = ZHCasualDateParser.dayWords.first(where: { $0.token == text }) {
            // A day word names a day and nothing else — deliberately no hour.
            guard assignDay(components, offsetBy: word.offset, context: context) else { return nil }
        } else if let hour = ZHConstants.TIME_OF_DAY_HOURS[text] {
            // 半夜/午夜 arrive here too: the lexicon already maps them to hour 0, and `isAfternoon`
            // reports false for them, so they resolve to midnight (am) on the reference day.
            //
            // Only the TIME is asserted here. A bare 下午 states an hour, not a day: the day comes
            // from the reference date and stays *implied*, which resolves 下午 to this afternoon
            // while leaving the result a pure time result that `ZHMergeDateTimeRefiner` can attach
            // to a neighbouring date word (明天下午 → tomorrow at 15:00).
            implyReferenceDay(components, context: context)
            components.assign(.hour, value: hour)
            components.assign(.minute, value: 0)
            components.assign(
                .meridiem,
                value: ZHConstants.isAfternoon(text) ? Meridiem.pm.rawValue : Meridiem.am.rawValue
            )
        } else {
            return nil
        }

        components.addTag("ZHCasualDateParser")
        return components
    }

    // MARK: - Helpers

    /// Assigns the year/month/day of the reference date shifted by `offsetBy` days.
    ///
    /// The date is *known*, not implied: 明天 names one specific calendar day.
    private func assignDay(_ components: ParsingComponents, offsetBy offset: Int, context: ParsingContext) -> Bool {
        let calendar = Calendar.current
        guard let targetDate = calendar.date(byAdding: .day, value: offset, to: context.refDate) else {
            return false
        }

        let dateComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)
        guard let year = dateComponents.year,
              let month = dateComponents.month,
              let day = dateComponents.day else {
            return false
        }

        components.assign(.year, value: year)
        components.assign(.month, value: month)
        components.assign(.day, value: day)
        return true
    }

    /// Anchors a time-only match to the reference day *without* claiming the day was stated.
    ///
    /// `ParsingComponents` already implies the reference date's year/month/day; restating it here
    /// keeps the intent explicit and independent of that default.
    private func implyReferenceDay(_ components: ParsingComponents, context: ParsingContext) {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: context.refDate)
        if let year = dateComponents.year { components.imply(.year, value: year) }
        if let month = dateComponents.month { components.imply(.month, value: month) }
        if let day = dateComponents.day { components.imply(.day, value: day) }
    }
}
