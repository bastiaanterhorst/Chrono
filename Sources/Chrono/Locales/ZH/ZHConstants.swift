// ZHConstants.swift - Shared lexicons, numeral handling and regex fragments for the Chinese locale.
import Foundation

/// Shared constants for the Chinese (zh) locale.
///
/// Two properties of Chinese drive every decision in this file:
///
/// 1. **There are no word boundaries.** ICU classifies Han ideographs as `\w`, so `\b` never fires
///    between two Chinese characters — the boundary discipline every Latin locale relies on is
///    simply unavailable. Like the Japanese locale, ZH therefore matches *compounds only* and never
///    a bare single character: `今天` is safe, a bare `天` fires inside 天气/聊天/白天. Where a token
///    is unavoidably short, it is guarded with an explicit negative lookahead instead.
///
/// 2. **Numbers appear in three scripts.** ASCII (`3`), full-width (`３`, what a Chinese IME emits
///    by default) and Chinese numerals (`三`). `三天后` is as ordinary as `3天后`, so all three are
///    accepted — see `parseNumber(_:)`. Note that Chinese numerals also carry the locale's sharpest
///    collisions (`十分` = "very", `一点` = "a little"), so callers gate them where needed.
enum ZHConstants {

    // MARK: - Number fragments

    /// A run of ASCII or full-width digits.
    static let ARABIC_NUMBER = "[0-9０-９]{1,4}"

    /// The characters a Chinese cardinal number can be built from.
    static let CHINESE_NUMERAL_CHARS = "〇零一二两兩三四五六七八九十百"

    /// A number written in ASCII digits, full-width digits, or Chinese numerals.
    /// Longest-first alternation so `二十` is not truncated to `二`.
    static let NUMBER = "(?:[0-9０-９]{1,4}|[〇零一二两兩三四五六七八九十百]{1,6})"

    // MARK: - Numeral parsing

    /// Parses a number written in ASCII digits, full-width digits, or Chinese numerals (0…999).
    /// Returns nil when the text is not a well-formed number in any of those scripts.
    static func parseNumber(_ text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        if let arabic = parseArabic(trimmed) { return arabic }
        return parseChineseCardinal(trimmed)
    }

    /// Parses a year, which in Chinese is usually written as a *digit sequence* rather than a
    /// cardinal: `二〇二六年` is "two-zero-two-six" = 2026, not 2 + 0 + 2 + 6. Falls back to the
    /// cardinal reading (`一九九九` style input is handled by the sequence path; `二十` by cardinal).
    static func parseYear(_ text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        if let arabic = parseArabic(trimmed) { return arabic }
        if let sequence = parseChineseDigitSequence(trimmed), trimmed.count >= 2 { return sequence }
        return parseChineseCardinal(trimmed)
    }

    /// Normalizes a 2-digit year to a 4-digit one (`26` → 2026, `85` → 1985). 4-digit years pass through.
    static func normalizeYear(_ year: Int) -> Int {
        guard year < 100 else { return year }
        return year < 50 ? 2000 + year : 1900 + year
    }

    /// ASCII / full-width digits only.
    private static func parseArabic(_ text: String) -> Int? {
        var digits = ""
        for character in text {
            guard let value = digitValue(character) else { return nil }
            digits.append(Character(String(value)))
        }
        return digits.isEmpty ? nil : Int(digits)
    }

    /// Every character read as an independent digit: `二〇二六` → 2026.
    private static func parseChineseDigitSequence(_ text: String) -> Int? {
        var digits = ""
        for character in text {
            guard let value = chineseDigitValue(character) else { return nil }
            digits.append(Character(String(value)))
        }
        return digits.isEmpty ? nil : Int(digits)
    }

    /// Chinese cardinal numbers up to 999: 十 = 10, 十五 = 15, 二十三 = 23, 一百零五 = 105.
    private static func parseChineseCardinal(_ text: String) -> Int? {
        var total = 0        // completed hundreds/tens sections
        var current = 0      // the digit awaiting its multiplier
        var sawAnything = false

        for character in text {
            if let digit = chineseDigitValue(character) {
                current = digit
                sawAnything = true
            } else if character == "十" {
                // A leading 十 means one ten (十五 = 15, not 5).
                total += (current == 0 ? 1 : current) * 10
                current = 0
                sawAnything = true
            } else if character == "百" {
                total += (current == 0 ? 1 : current) * 100
                current = 0
                sawAnything = true
            } else {
                return nil
            }
        }

        return sawAnything ? total + current : nil
    }

    /// The numeric value of a single ASCII, full-width, or Chinese digit character.
    private static func chineseDigitValue(_ character: Character) -> Int? {
        if let value = digitValue(character) { return value }
        switch character {
        case "〇", "零": return 0
        case "一": return 1
        case "二", "两", "兩": return 2
        case "三": return 3
        case "四": return 4
        case "五": return 5
        case "六": return 6
        case "七": return 7
        case "八": return 8
        case "九": return 9
        default: return nil
        }
    }

    /// The numeric value of a single ASCII or full-width digit character.
    private static func digitValue(_ character: Character) -> Int? {
        if let ascii = character.wholeNumberValue, character.isASCII, character.isNumber {
            return ascii
        }
        if let index = "０１２３４５６７８９".firstIndex(of: character) {
            return "０１２３４５６７８９".distance(from: "０１２３４５６７８９".startIndex, to: index)
        }
        return nil
    }

    // MARK: - Weekdays

    /// The characters that name a weekday after 星期/周/礼拜. Sun = 0 … Sat = 6, matching every
    /// other locale's numbering. Both 日 and 天 mean Sunday.
    static let WEEKDAY_DICTIONARY: [String: Int] = [
        "日": 0, "天": 0,
        "一": 1, "二": 2, "三": 3, "四": 4, "五": 5, "六": 6
    ]

    /// The words that introduce a weekday. 星期 and 礼拜 are the full forms; 周 is the clipped one.
    /// A bare 周/週 without one of the weekday characters is never a weekday (周围, 周到, and the
    /// surname 周 all begin that way), so every pattern using this requires a weekday character.
    static let WEEK_WORD = "(?:星期|礼拜|禮拜|周|週)"

    /// The characters that may follow `WEEK_WORD` to name a day.
    static let WEEKDAY_CHARS = "[一二三四五六日天]"

    // MARK: - Relative prefixes

    /// Week/month offset prefixes, longest-first so 下下 wins over 下.
    /// 这/這/本 = this, 下 = next, 上 = last, doubled = ±2.
    static let OFFSET_PREFIX = "(?:上上|下下|这|這|本|上|下)"

    /// Maps an offset prefix to a number of units. Returns nil for an unknown prefix.
    static func offset(forPrefix prefix: String) -> Int? {
        switch prefix {
        case "这", "這", "本": return 0
        case "下": return 1
        case "下下": return 2
        case "上": return -1
        case "上上": return -2
        default: return nil
        }
    }

    // MARK: - Time-of-day

    /// Time-of-day words and the hour they imply on their own. Mirrors the Japanese locale's
    /// choices (午前 → 9, 午後 → 15, 夕方 → 17, 今夜 → 22) so the two CJK locales agree.
    static let TIME_OF_DAY_HOURS: [String: Int] = [
        "凌晨": 3,
        "清晨": 6,
        "早晨": 7,
        "早上": 8,
        "上午": 9,
        "中午": 12,
        "正午": 12,
        "下午": 15,
        "傍晚": 17,
        "晚上": 20,
        "夜里": 22,
        "夜裡": 22,
        "半夜": 0,
        "午夜": 0
    ]

    /// Time-of-day words as a longest-first regex alternation.
    static let TIME_OF_DAY_WORDS = "(?:凌晨|清晨|早晨|早上|上午|中午|正午|下午|傍晚|晚上|夜里|夜裡|半夜|午夜)"

    /// Whether a time-of-day word puts the clock in the afternoon/evening half.
    static func isAfternoon(_ word: String) -> Bool {
        switch word {
        case "下午", "傍晚", "晚上", "夜里", "夜裡": return true
        default: return false
        }
    }

    // MARK: - Direction suffixes

    /// "after / from now" suffixes, longest-first.
    static let FUTURE_SUFFIX = "(?:之后|之後|以后|以後|后|後)"

    /// "before / ago" suffixes, longest-first.
    static let PAST_SUFFIX = "(?:之前|以前|前)"

    /// "within" suffixes, longest-first.
    static let WITHIN_SUFFIX = "(?:之内|之內|以内|以內|内|內)"

    // MARK: - Time units

    /// Time-unit words → calendar component, for the numeric relative parsers.
    ///
    /// Deliberately absent: a bare 分 (十分 means "very", not ten minutes), a bare 月 (`3月` is
    /// March, not three months — the relative form requires the measure word 个/個) and 周/週/星期,
    /// which are owned by `ZHRelativeWeekParser` because a week resolves to an ISO week rather than
    /// a plain day offset.
    static let TIME_UNIT_DICTIONARY: [String: Calendar.Component] = [
        "分钟": .minute, "分鐘": .minute,
        "小时": .hour, "小時": .hour, "钟头": .hour, "鐘頭": .hour,
        "天": .day, "日": .day,
        "个月": .month, "個月": .month,
        "年": .year
    ]

    /// The time units as a longest-first regex alternation.
    static let TIME_UNIT_WORDS = "(?:分钟|分鐘|小时|小時|钟头|鐘頭|个月|個月|天|日|年)"

    /// The week units, which the relative-week parser owns.
    static let WEEK_UNIT_WORDS = "(?:个星期|個星期|个礼拜|個禮拜|星期|礼拜|禮拜|周|週)"
}
