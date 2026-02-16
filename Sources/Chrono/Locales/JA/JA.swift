// JA.swift - Japanese locale parsers and refiners
import Foundation

/// Japanese language date parsing
public enum JA {
    /// Creates a casual configuration for Japanese parsing
    /// - Returns: A Chrono instance with casual configuration
    static func createCasualConfiguration() -> Chrono {
        let baseParsers: [Parser] = [
            JAISOWeekNumberParser(),
            JARelativeWeekParser(),
            JARelativeUnitKeywordParser(),
            JANumericRelativeUnitParser(),
            JACasualDateParser(),
            JAMonthNameParser(),
            JAStandardParser(),
            JATimeExpressionParser()
        ]
        
        let baseRefiners: [Refiner] = [
            JAMergeDateTimeRefiner(),
            JAMergeDateRangeRefiner(),
            JAPrioritizeWeekNumberRefiner()
        ]

        let (parsers, refiners) = CommonConfiguration.includeCommonConfiguration(
            parsers: baseParsers,
            refiners: baseRefiners,
            strictMode: false
        )
        
        return Chrono(parsers: parsers, refiners: refiners)
    }
    
    /// Creates a strict configuration for Japanese parsing
    /// - Returns: A Chrono instance with strict configuration
    static func createStrictConfiguration() -> Chrono {
        let baseParsers: [Parser] = [
            JAISOWeekNumberParser(),
            JARelativeWeekParser(),
            JARelativeUnitKeywordParser(),
            JANumericRelativeUnitParser(),
            JAMonthNameParser(),
            JAStandardParser(),
            JATimeExpressionParser()
        ]
        
        let baseRefiners: [Refiner] = [
            JAMergeDateTimeRefiner(),
            JAMergeDateRangeRefiner(),
            JAPrioritizeWeekNumberRefiner()
        ]

        let (parsers, refiners) = CommonConfiguration.includeCommonConfiguration(
            parsers: baseParsers,
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
