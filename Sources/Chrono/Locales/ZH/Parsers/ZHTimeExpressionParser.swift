// ZHTimeExpressionParser.swift - Parser for 点-based Chinese clock times like "下午3点半"
import Foundation

/// How a Chinese time-of-day prefix maps onto the clock.
///
/// Shared with `ZHClockTimeParser`, which applies exactly the same rules to colon times — the two
/// parsers differ only in how the hour and minute are spelled, never in what a prefix means.
enum ZHTimeOfDayPrefix {
    /// 上午 早上 早晨 清晨 凌晨 / AM — the morning half of the 12-hour clock.
    case morning
    /// 下午 傍晚 晚上 夜里 夜裡 / PM — the afternoon/evening half.
    case afternoon
    /// 中午 正午 — around noon; the hour is taken as written.
    case noon
    /// 半夜 午夜 — the small hours; the hour is taken as written.
    case midnight

    /// Classifies a matched prefix, deriving the categories from `ZHConstants` rather than
    /// restating the lexicon: the afternoon set is `isAfternoon(_:)`, and noon/midnight are the two
    /// words whose stand-alone hour is 12 and 0. Everything else in the table is a morning word.
    /// Returns nil for text that is not a prefix this locale knows.
    init?(_ text: String) {
        switch text.uppercased() {
        case "AM": self = .morning; return
        case "PM": self = .afternoon; return
        default: break
        }

        guard let standaloneHour = ZHConstants.TIME_OF_DAY_HOURS[text] else { return nil }

        if ZHConstants.isAfternoon(text) {
            self = .afternoon
        } else if standaloneHour == 12 {
            self = .noon
        } else if standaloneHour == 0 {
            self = .midnight
        } else {
            self = .morning
        }
    }

    /// Converts an hour as written into a 24-hour hour.
    func hour(fromWritten written: Int) -> Int {
        switch self {
        case .morning:
            return written == 12 ? 0 : written        // 上午12点 = midnight
        case .afternoon:
            return written < 12 ? written + 12 : written // 下午3点 = 15:00
        case .noon:
            return written                             // 中午12点 = 12:00
        case .midnight:
            return written == 12 ? 0 : written         // 半夜2点 = 02:00, 半夜12点 = 00:00
        }
    }

    /// The meridiem this prefix pins down for an hour as written, or nil when it does not pin one
    /// down (a 中午 hour below 12 is left to the caller's 24-hour reading).
    func meridiem(forWrittenHour written: Int) -> Meridiem? {
        switch self {
        case .morning, .midnight:
            return .am
        case .afternoon:
            return .pm
        case .noon:
            return written >= 12 ? .pm : nil
        }
    }
}

/// Parser for 点-based Chinese clock times: `3点`, `3点30分`, `下午3点`, `一点半`, `晚上八点一刻`,
/// `３点`, `九点钟`.
///
/// **A bare Chinese-numeral hour is deliberately not accepted.** `一点` overwhelmingly means "a
/// little bit" rather than "one o'clock" — `改一点文案` is "edit the copy a little", `有点累` is
/// "a bit tired", `差一点` is "very nearly". A Chinese-numeral hour is therefore only read as a time
/// when something disambiguates it: either a preceding time-of-day word (`下午一点`) or a following
/// minute/half/quarter tail (`一点半`, `一点十五分`, `一点钟`). Hours written in ASCII or full-width
/// digits (`3点`, `３点`) carry no such ambiguity and need no gate.
///
/// The remaining 点 collisions are blocked by a single lookahead, `(?![心子头頭点點])`, which stops
/// 点心 (dim sum), 点子, 点头 and — crucially — the doubled 一点点.
///
/// Chinese has **no** late-night hour convention: unlike Japanese `27時`, there is no `27点`, so the
/// no-prefix hour range is capped at 23 rather than 29.
public struct ZHTimeExpressionParser: Parser {
    public init() {}

    /// Chinese numerals that can spell an hour or a minute. `百` is excluded: no clock value needs it.
    private static let CLOCK_NUMERAL = "[〇零一二两兩三四五六七八九十]"

    /// The 点 characters that must not be followed by 心/子/头/頭 (词 collisions) or another 点
    /// (`一点点`).
    private static let NOT_A_WORD_AFTER_DIAN = "(?![心子头頭点點])"

    /// A quarter/half tail. Longest-first is irrelevant here (no token is a prefix of another),
    /// but the order matches the surrounding files' convention.
    private static let FRACTION_TAIL = "(半|一刻|三刻)"

    /// One pattern, three alternatives, in this order:
    ///
    /// | Alternative | Shape | Groups |
    /// |---|---|---|
    /// | (a) prefix + hour, any script | `下午3点30分` | 1 = prefix, 2 = hour, 3 = minute, 4 = fraction |
    /// | (b) bare ASCII/full-width hour | `3点半` | 5 = hour, 6 = minute, 7 = fraction |
    /// | (c) Chinese-numeral hour, tail REQUIRED | `一点半` | 8 = hour, 9 = minute, 10 = fraction |
    ///
    /// Getting those indices wrong is the easiest mistake to make here, so `extract` reads them
    /// through the same table.
    public func pattern(context: ParsingContext) -> String {
        let numeral = ZHTimeExpressionParser.CLOCK_NUMERAL
        let notWord = ZHTimeExpressionParser.NOT_A_WORD_AFTER_DIAN
        let fraction = ZHTimeExpressionParser.FRACTION_TAIL

        // (a) A time-of-day word (or AM/PM) settles the meridiem, so the hour may be written in any
        // script and needs no tail. 时/時 is accepted as a formal hour marker alongside 点/點.
        let withPrefix =
            "(\(ZHConstants.TIME_OF_DAY_WORDS)|[AaPp][Mm])\\s*(\(ZHConstants.NUMBER))\\s*[点點时時]" +
            "(?:\\s*(\(ZHConstants.NUMBER))\\s*分(?![钟鐘])|\\s*\(fraction))?(?:\\s*[钟鐘])?"

        // (b) A digit hour is unambiguous on its own. The digit lookbehind keeps the hour from
        // starting inside a longer number.
        let bareDigits =
            "(?<![0-9０-９])([0-9０-９]{1,2})\\s*[点點]\(notWord)" +
            "(?:\\s*([0-9０-９]{1,2})\\s*分(?![钟鐘])|\\s*\(fraction))?(?:\\s*[钟鐘])?"

        // (c) A Chinese-numeral hour needs a tail — minutes, a half/quarter, or 钟 — to prove it is
        // a clock time and not 一点 "a little".
        let bareChinese =
            "(\(numeral){1,3})\\s*[点點]\(notWord)" +
            "(?:\\s*(\(numeral){1,3}|[0-9０-９]{1,2})\\s*分(?![钟鐘])|\\s*\(fraction)|\\s*[钟鐘])"

        return withPrefix + "|" + bareDigits + "|" + bareChinese
    }

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        // Group layout per alternative — see `pattern(context:)`.
        let hourText: String
        let minuteText: String?
        let fractionText: String?
        let prefixText: String?

        if let prefix = match.string(at: 1), let hour = match.string(at: 2) {
            prefixText = prefix
            hourText = hour
            minuteText = match.string(at: 3)
            fractionText = match.string(at: 4)
        } else if let hour = match.string(at: 5) {
            prefixText = nil
            hourText = hour
            minuteText = match.string(at: 6)
            fractionText = match.string(at: 7)
        } else if let hour = match.string(at: 8) {
            prefixText = nil
            hourText = hour
            minuteText = match.string(at: 9)
            fractionText = match.string(at: 10)
        } else {
            return nil
        }

        guard let writtenHour = ZHConstants.parseNumber(hourText) else { return nil }

        let minute: Int
        if let fractionText {
            minute = ZHTimeExpressionParser.minutes(forFraction: fractionText) ?? 0
        } else if let minuteText {
            guard let parsed = ZHConstants.parseNumber(minuteText) else { return nil }
            minute = parsed
        } else {
            minute = 0
        }

        // Validation (openspec spec `numeric-time-validation`): minutes are always 0-59; a prefix
        // puts the hour on the 12-hour clock; without one it is a 24-hour reading. Chinese has no
        // late-night 24-29 convention, so out-of-range values reject the match rather than
        // overflowing through the calendar into a later day.
        guard minute <= 59 else { return nil }

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
        components.imply(.second, value: 0)

        if let meridiem = prefix?.meridiem(forWrittenHour: writtenHour) {
            components.assign(.meridiem, value: meridiem.rawValue)
        } else {
            components.imply(.meridiem, value: hour < 12 ? Meridiem.am.rawValue : Meridiem.pm.rawValue)
        }

        components.addTag("ZHTimeExpressionParser")
        return components
    }

    /// 半 = half past, 一刻 = quarter past, 三刻 = three quarters past.
    private static func minutes(forFraction text: String) -> Int? {
        switch text {
        case "半": return 30
        case "一刻": return 15
        case "三刻": return 45
        default: return nil
        }
    }
}
