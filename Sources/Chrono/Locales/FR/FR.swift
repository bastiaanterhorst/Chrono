// FR.swift - French locale parsers and refiners
import Foundation

/// French language date parsing
public enum FR {
    /// Creates a casual configuration for French parsing
    /// - Returns: A Chrono instance with casual configuration
    static func createCasualConfiguration() -> Chrono {
        let baseParsers: [Parser] = [
            FRISOWeekNumberParser(),
            FRRelativeWeekParser(),
            FRRelativeUnitKeywordParser(),
            FRRelativeTimeUnitParser(),
            FRCasualDateParser(),
            FRCasualTimeParser(),
            FRMonthNameParser(),
            FRTimeExpressionParser(),
            FRWeekdayParser(),
            FRSpecificTimeExpressionParser()
        ]
        
        let baseRefiners: [Refiner] = [
            FRMergeDateTimeRefiner(),
            FRMergeDateRangeRefiner(),
            FRPrioritizeWeekNumberRefiner()
        ]

        let (parsers, refiners) = CommonConfiguration.includeCommonConfiguration(
            parsers: baseParsers,
            refiners: baseRefiners,
            strictMode: false
        )
        
        return Chrono(parsers: parsers, refiners: refiners)
    }
    
    /// Creates a strict configuration for French parsing
    /// - Returns: A Chrono instance with strict configuration
    static func createStrictConfiguration() -> Chrono {
        let baseParsers: [Parser] = [
            FRISOWeekNumberParser(),
            FRRelativeWeekParser(),
            FRRelativeUnitKeywordParser(),
            FRRelativeTimeUnitParser(),
            FRMonthNameParser(),
            FRTimeExpressionParser(),
            FRSpecificTimeExpressionParser()
        ]
        
        let baseRefiners: [Refiner] = [
            FRMergeDateTimeRefiner(),
            FRMergeDateRangeRefiner(),
            FRPrioritizeWeekNumberRefiner()
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
