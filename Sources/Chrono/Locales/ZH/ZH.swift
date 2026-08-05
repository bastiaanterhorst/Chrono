// ZH.swift - Chinese locale parsers and refiners
import Foundation

/// Chinese (zh) date parsing.
///
/// One locale covers both scripts: the lexicons accept Simplified and Traditional tokens
/// (后/後, 周/週, 个/個, 点/點, 号/號, 两/兩), because `Locale.language.languageCode` collapses
/// `zh-Hans` and `zh-Hant` to `"zh"` and the two character sets barely overlap, so accepting both
/// costs nothing and never introduces an ambiguity.
public enum ZH {
    /// The parsers shared by the casual and strict configurations.
    /// Week parsers run first so they claim `下周三` before the bare-week patterns can.
    private static func baseParsers(casual: Bool) -> [Parser] {
        var parsers: [Parser] = [
            ZHISOWeekNumberParser(),
            ZHRelativeWeekParser(),
            ZHRelativeUnitKeywordParser(),
            ZHNumericRelativeUnitParser(),
            ZHTimeUnitWithinFormatParser()
        ]

        if casual {
            parsers.append(ZHCasualDateParser())
        }

        // Annotated explicitly: the ZH parsers are a mix of structs and final classes, so an
        // unannotated literal cannot infer the existential element type.
        let remaining: [Parser] = [
            ZHStandardParser(),
            ZHMonthNameParser(),
            ZHSlashDateFormatParser(),
            ZHWeekdayParser(),
            ZHClockTimeParser(),
            ZHTimeExpressionParser()
        ]
        parsers.append(contentsOf: remaining)

        return parsers
    }

    /// The refiners shared by the casual and strict configurations.
    private static var baseRefiners: [Refiner] {
        [
            ZHMergeDateTimeRefiner(),
            ZHMergeDateRangeRefiner(),
            ZHPrioritizeWeekNumberRefiner()
        ]
    }

    /// Creates a casual configuration for Chinese parsing
    /// - Returns: A Chrono instance with casual configuration
    static func createCasualConfiguration() -> Chrono {
        let (parsers, refiners) = CommonConfiguration.includeCommonConfiguration(
            parsers: baseParsers(casual: true),
            refiners: baseRefiners,
            strictMode: false
        )
        return Chrono(parsers: parsers, refiners: refiners)
    }

    /// Creates a strict configuration for Chinese parsing
    /// - Returns: A Chrono instance with strict configuration
    static func createStrictConfiguration() -> Chrono {
        let (parsers, refiners) = CommonConfiguration.includeCommonConfiguration(
            parsers: baseParsers(casual: false),
            refiners: baseRefiners,
            strictMode: true
        )
        return Chrono(parsers: parsers, refiners: refiners)
    }

    /// A Chrono instance with casual configuration
    public static let casual = createCasualConfiguration()

    /// A Chrono instance with strict configuration
    public static let strict = createStrictConfiguration()
}
