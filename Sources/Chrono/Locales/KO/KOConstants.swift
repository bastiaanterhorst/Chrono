// KOConstants.swift - Shared lexicon and helpers for the Korean locale.
import Foundation

/// Lexicon shared by the Korean parsers.
///
/// Korean writes spaces, unlike Chinese and Japanese, but ICU classifies Hangul syllables as `\w`,
/// so `\b` never fires between two of them — the boundary discipline the Latin locales rely on is
/// only half available. The tokens below are therefore all two syllables or more, or carry an
/// explicit lookaround, so that none of them can be cut out of a longer word.
///
/// The spacing itself is not dependable either: 다음 주 and 다음주 are both correct and both common,
/// so every multi-word phrase here allows the space to be absent.
enum KOConstants {
    /// Day words and the offset they name. Longer tokens come first within a shared prefix, because
    /// a regex alternation is tried left to right: with 그제 before 그저께 the engine would match 그제
    /// out of 그저께 and report −2 for a word meaning −2 … but 어제 before 어저께 would genuinely
    /// mis-report, so the rule is applied throughout rather than case by case.
    static let dayWords: [(token: String, offset: Int)] = [
        ("그저께", -2),
        ("그제", -2),
        ("어저께", -1),
        ("어제", -1),
        ("오늘", 0),
        ("내일모레", 2),   // before 내일, which is its prefix
        ("모레", 2),
        ("글피", 3),
        ("내일", 1),
    ]

    /// Rough times of day and the hour each names. Every token is two syllables: a bare 밤 ("night")
    /// is also the word for chestnut, and a bare 낮 appears inside 낮잠, so neither stands alone.
    static let timeOfDayHours: [String: (hour: Int, meridiem: Meridiem)] = [
        "새벽": (5, .am),
        "아침": (8, .am),
        "점심": (12, .pm),
        "낮": (14, .pm),
        "저녁": (18, .pm),
        "밤": (20, .pm),
        "오전": (9, .am),
        "오후": (15, .pm),
    ]

    /// Weekday syllable → `Calendar` weekday number (1 = Sunday).
    static let weekdays: [String: Int] = [
        "일": 1, "월": 2, "화": 3, "수": 4, "목": 5, "금": 6, "토": 7,
    ]

    /// "this / next / last" as they attach to 주 (week), 달 (month) and 해 (year).
    static let relativeModifiers: [String: Int] = [
        "이번": 0, "금": 0,
        "다음": 1, "담": 1, "오는": 1, "내": 1,
        "지난": -1, "저번": -1, "전": -1,
    ]

    /// Optional space: Korean compounds are written both ways ("다음 주" and "다음주").
    static let optionalSpace = "\\s*"

    /// A clock time following a word would make that word part of a larger expression, so the
    /// casual parser yields rather than splitting it: 저녁 7시 is one phrase owned by the time parser.
    static let notFollowedByClockTime = "(?!\\s*\\d{1,2}\\s*(?:시|:))"
}

extension ParsingComponents {
    /// Assigns the calendar day `days` from the reference date as *known* values.
    @discardableResult
    func assignKODay(offsetBy days: Int, from refDate: Date) -> Bool {
        let calendar = Calendar.current
        guard let target = calendar.date(byAdding: .day, value: days, to: refDate) else { return false }
        let values = calendar.dateComponents([.year, .month, .day], from: target)
        guard let year = values.year, let month = values.month, let day = values.day else { return false }
        assign(.year, value: year)
        assign(.month, value: month)
        assign(.day, value: day)
        return true
    }
}
