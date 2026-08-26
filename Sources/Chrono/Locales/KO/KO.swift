// KO.swift - Korean locale parsers and refiners.
import Foundation

/// Korean (ko) date parsing.
///
/// Korean writes spaces where Chinese and Japanese do not, but its compounds are written both with
/// and without them — 다음 주 and 다음주 are equally correct — so every phrase here treats the space
/// as optional. Hangul is `\w` to ICU, so `\b` cannot separate two syllables; the lexicon avoids
/// single-syllable tokens and uses explicit lookarounds where a token could be cut out of a longer
/// word.
public enum KO {
    /// The parsers shared by the casual and strict configurations.
    ///
    /// Order is load-bearing. The week-number parser leads so 35주차 is claimed before anything can
    /// take the 주. The weekday parser follows, because 다음 주 금요일 is one phrase naming a day, and
    /// the relative-unit parser would otherwise claim 다음 주 and leave the weekday stranded.
    private static func baseParsers(casual: Bool) -> [Parser] {
        var parsers: [Parser] = [
            KOISOWeekNumberParser(),
            KOWeekdayParser(),
            KORelativeUnitParser(),
        ]
        if casual {
            parsers.append(KOCasualDateParser())
        }
        parsers.append(contentsOf: [
            KOStandardParser(),
            KOSlashDateFormatParser(),
            KOTimeExpressionParser(),
        ] as [Parser])
        return parsers
    }

    private static var baseRefiners: [Refiner] {
        // An end-of-period phrase Chrono cannot read must come back unrecognised, not
        // reversed: without this "다음 달 말" claimed 다음 달 alone and resolved to the *first*
        // of next month, leaving the 말 stranded in the task name.
        [PeriodEndGuardRefiner(followingWords: ["말"])]
    }

    static func createCasualConfiguration() -> Chrono {
        let (parsers, refiners) = CommonConfiguration.includeCommonConfiguration(
            parsers: baseParsers(casual: true), refiners: baseRefiners, strictMode: false)
        return Chrono(parsers: parsers, refiners: refiners)
    }

    static func createStrictConfiguration() -> Chrono {
        let (parsers, refiners) = CommonConfiguration.includeCommonConfiguration(
            parsers: baseParsers(casual: false), refiners: baseRefiners, strictMode: true)
        return Chrono(parsers: parsers, refiners: refiners)
    }

    /// A Chrono instance with casual configuration
    public static let casual = createCasualConfiguration()

    /// A Chrono instance with strict configuration
    public static let strict = createStrictConfiguration()
}
