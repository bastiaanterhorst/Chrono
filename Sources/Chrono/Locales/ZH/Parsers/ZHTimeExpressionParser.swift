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

        // A contracted day+time compound settles the half of the clock exactly as its time-of-day
        // half would on its own: 今晚8点 is 20:00, 明早9点 is 09:00. The *day* it also names is
        // applied by the caller, which is the only part a bare time-of-day word does not carry.
        if let compound = ZHConstants.DAY_TIME_COMPOUNDS[text] {
            self = compound.meridiem == .pm ? .afternoon : .morning
            return
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
/// ## Telling the clock 点 from the measure-word 点
///
/// 点 is also the measure word for enumerated items, so `三点建议` is "three suggestions" and
/// `记录3点意见` is "note three opinions" — neither is a time. Three guards separate the readings,
/// and all of them apply to **every** spelling of the hour, digits included: an enumeration is
/// written with ASCII numerals as readily as with Chinese ones.
///
/// 1. `ZHConstants.NOT_AFTER_ENUMERATION_VERB` — an enumeration is introduced by a verb that
///    governs it (记录/总结/提出/列出/有…), and that verb sits immediately before the numeral.
/// 2. `ZHConstants.NOT_BEFORE_ENUMERABLE_NOUN` — the noun being counted, for the rarer case where
///    no verb introduces it.
/// 3. `(?![心子头頭点點])` — the fixed compounds 点心 (dim sum), 点子, 点头, and the doubled 一点点.
///
/// **`一点` and `二点` additionally require a tail.** `一点` overwhelmingly means "a little bit"
/// (`改一点文案`, `有点累`, `差一点`), and `二点` is simply not how Chinese states two o'clock — that
/// is `两点`. Both are read as times only once something disambiguates them: a time-of-day word
/// (`下午一点`) or a minute/half/quarter/钟 tail (`一点半`, `一点十五分`, `一点钟`). Every other
/// Chinese numeral is accepted bare, exactly as a digit is, so `十点开会` and `两点开会` resolve.
///
/// Note that a bare hour is read literally in any script: `两点` is 02:00, not 14:00. Chinese is
/// genuinely ambiguous there and so is the digit form (`3点` has always meant 03:00), so the two
/// spellings agree; a user who means the afternoon writes `下午两点`, which is the ordinary phrasing
/// precisely because the bare form is ambiguous.
///
/// Chinese has **no** late-night hour convention: unlike Japanese `27時`, there is no `27点`, so the
/// no-prefix hour range is capped at 23 rather than 29.
public struct ZHTimeExpressionParser: Parser {
    public init() {}

    /// Chinese numerals that can spell an hour or a minute. `百` is excluded: no clock value needs it.
    private static let CLOCK_NUMERAL = "[〇零一二两兩三四五六七八九十]"

    /// The numerals that may spell a **bare** hour — every one except 一 and 二, which are gated by
    /// the tail requirement (see the type comment). 十 leads so that 十一/十二 are matched whole.
    private static let BARE_CLOCK_NUMERAL = "(?:十[一二]|[三四五六七八九十]|两|兩)"

    /// The 点 characters that must not be followed by 心/子/头/頭 (词 collisions) or another 点
    /// (`一点点`).
    private static let NOT_A_WORD_AFTER_DIAN = "(?![心子头頭点點])"

    /// A quarter/half tail. Longest-first is irrelevant here (no token is a prefix of another),
    /// but the order matches the surrounding files' convention.
    private static let FRACTION_TAIL = "(半|一刻|三刻)"

    /// The words that may close an hour without changing it: 钟 ("o'clock") and 整 ("on the hour").
    ///
    /// 整 needs a guard that 钟 does not, because it opens a great many ordinary words — 整理 (to
    /// tidy), 整个 (whole), 整天 (all day), 整体, 整齐. Without it `3点整理文件` ("tidy the files at
    /// three") would be read as `3点整` and name the task 「理文件」.
    private static let HOUR_TAIL = "(?:[钟鐘]|整(?![理個个齐齊体體天数數容修顿頓形容洁潔]))"

    /// One pattern, four alternatives, in this order:
    ///
    /// | Alternative | Shape | Groups |
    /// |---|---|---|
    /// | (a) prefix + hour, any script | `下午3点30分` | 1 = prefix, 2 = hour, 3 = minute, 4 = fraction |
    /// | (b) bare ASCII/full-width hour | `3点半` | 5 = hour, 6 = minute, 7 = fraction |
    /// | (c) Chinese-numeral hour, tail REQUIRED | `一点半` | 8 = hour, 9 = minute, 10 = fraction |
    /// | (d) Chinese-numeral hour, no tail | `十点` | 11 = hour |
    ///
    /// (c) precedes (d) so that a numeral which *has* a tail is read with it — `三点半` is 03:30 by
    /// way of (c), and (d) never sees it. (d) then accepts only the numerals that need no tail.
    ///
    /// Getting those indices wrong is the easiest mistake to make here, so `extract` reads them
    /// through the same table.
    public func pattern(context: ParsingContext) -> String {
        let numeral = ZHTimeExpressionParser.CLOCK_NUMERAL
        let bareNumeral = ZHTimeExpressionParser.BARE_CLOCK_NUMERAL
        let fraction = ZHTimeExpressionParser.FRACTION_TAIL
        let noEnumVerb = ZHConstants.NOT_AFTER_ENUMERATION_VERB
        // Everything that may not follow the 点 of a clock time: the fixed compounds, and the noun
        // of an enumeration written without a governing verb.
        let afterDian = ZHTimeExpressionParser.NOT_A_WORD_AFTER_DIAN + ZHConstants.NOT_BEFORE_ENUMERABLE_NOUN

        // (a) A time-of-day word (or AM/PM) settles the meridiem, so the hour may be written in any
        // script and needs no tail. 时/時 is accepted as a formal hour marker alongside 点/點.
        //
        // A contracted day+time compound (今晚, 明早) is accepted in the same position and listed
        // first, because it settles the meridiem *and* names the day: 今晚8点 is one expression
        // meaning 20:00 tonight. It must precede the plain word list — 今晚 and the bare 晚上 have
        // no common prefix, but keeping the more specific token first matches the file's convention.
        //
        // No enumeration guard on the left here: the prefix occupies that position, and a counted
        // 点 is never introduced by 下午 or 今晚.
        let withPrefix =
            "(\(ZHConstants.DAY_TIME_COMPOUND_WORDS)|\(ZHConstants.TIME_OF_DAY_WORDS)|[AaPp][Mm])" +
            "\\s*(\(ZHConstants.NUMBER))\\s*[点點时時]\(afterDian)" +
            "(?:\\s*(\(ZHConstants.NUMBER))\\s*分(?![钟鐘])|\\s*\(fraction))?(?:\\s*\(ZHTimeExpressionParser.HOUR_TAIL))?"

        // (b) A digit hour needs no tail, but it needs the enumeration guards just as much as a
        // Chinese numeral does: 记录3点建议 is "note three suggestions", not 03:00.
        let bareDigits =
            "(?<![0-9０-９])\(noEnumVerb)([0-9０-９]{1,2})\\s*[点點]\(afterDian)" +
            "(?:\\s*([0-9０-９]{1,2})\\s*分(?![钟鐘])|\\s*\(fraction))?(?:\\s*\(ZHTimeExpressionParser.HOUR_TAIL))?"

        // (c) Any Chinese numeral, with a tail — minutes, a half/quarter, or 钟 — which is what
        // lets 一点半 and 二点十分 be read despite 一/二 being gated bare.
        let chineseWithTail =
            "\(noEnumVerb)(\(numeral){1,3})\\s*[点點]\(afterDian)" +
            "(?:\\s*(\(numeral){1,3}|[0-9０-９]{1,2})\\s*分(?![钟鐘])|\\s*\(fraction)"
            + "|\\s*\(ZHTimeExpressionParser.HOUR_TAIL))"

        // (d) A Chinese numeral that stands on its own — everything except 一 ("a little") and 二
        // (not how two o'clock is said).
        let chineseBare = "\(noEnumVerb)(\(bareNumeral))\\s*[点點]\(afterDian)"

        return withPrefix + "|" + bareDigits + "|" + chineseWithTail + "|" + chineseBare
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
        } else if let hour = match.string(at: 11) {
            prefixText = nil
            hourText = hour
            minuteText = nil
            fractionText = nil
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

        // A contracted compound states the day as well as the hour — 明早9点 is tomorrow, not the
        // reference day at 09:00 — so the date is assigned here rather than left to the merge
        // refiner, which has no neighbouring date word to work from.
        if let prefixText, let compound = ZHConstants.DAY_TIME_COMPOUNDS[prefixText] {
            guard components.assignZHDay(offsetBy: compound.offset, from: context.refDate) else {
                return nil
            }
        }

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
