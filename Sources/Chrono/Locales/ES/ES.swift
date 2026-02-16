// ES.swift - Spanish locale parsers and refiners
import Foundation

/// Spanish language date parsing
public enum ES {
    /// Creates a casual configuration for Spanish parsing
    /// - Returns: A Chrono instance with casual Spanish configuration
    static func createCasualConfiguration() -> Chrono {
        let baseParsers: [Parser] = [
            ESISOWeekNumberParser(),
            ESRelativeWeekParser(),
            ESRelativeUnitKeywordParser(),

            // Casual date/time parsers
            ESCasualDateParser(),
            ESCasualTimeParser(),
            
            // Time-related parsers
            ESTimeExpressionParser(),
            
            // Date-related parsers
            ESWeekdayParser(),
            ESMonthNameParser(),
            ESMonthNameLittleEndianParser(),
            
            // Time unit parsers
            ESTimeUnitWithinFormatParser()
        ]
        
        let baseRefiners: [Refiner] = [
            // Basic mergers
            ESMergeDateTimeRefiner(),
            ESMergeDateRangeRefiner(),
            ESPrioritizeWeekNumberRefiner()
        ]
        
        // Add common configuration (ISO parsers and refiners)
        let (parsers, refiners) = CommonConfiguration.includeCommonConfiguration(
            parsers: baseParsers,
            refiners: baseRefiners,
            strictMode: false
        )
        
        return Chrono(parsers: parsers, refiners: refiners)
    }
    
    /// Creates a strict configuration for Spanish parsing
    /// - Returns: A Chrono instance with strict Spanish configuration
    static func createStrictConfiguration() -> Chrono {
        let baseParsers: [Parser] = [
            ESISOWeekNumberParser(),
            ESRelativeWeekParser(),
            ESRelativeUnitKeywordParser(),

            // Only formal parsers, no casual expressions
            ESTimeExpressionParser(),
            ESMonthNameParser(),
            ESMonthNameLittleEndianParser(),
            ESTimeUnitWithinFormatParser()
        ]
        
        let baseRefiners: [Refiner] = [
            ESMergeDateTimeRefiner(),
            ESMergeDateRangeRefiner(),
            ESPrioritizeWeekNumberRefiner()
        ]
        
        // Add common configuration (ISO parsers and refiners)
        let (parsers, refiners) = CommonConfiguration.includeCommonConfiguration(
            parsers: baseParsers,
            refiners: baseRefiners,
            strictMode: true
        )
        
        return Chrono(parsers: parsers, refiners: refiners)
    }
    
    /// A Chrono instance with casual configuration for Spanish
    public static let casual = createCasualConfiguration()
    
    /// A Chrono instance with strict configuration for Spanish
    public static let strict = createStrictConfiguration()
}
