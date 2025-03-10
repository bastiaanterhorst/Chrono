// DE.swift - German locale parsers and refiners
import Foundation

/// German language date parsing
public enum DE {
    /// Creates a casual configuration for German parsing
    /// - Returns: A Chrono instance with casual configuration
    static func createCasualConfiguration() -> Chrono {
        let baseParsers: [Parser] = [
            // Casual date/time parsers
            DECasualDateParser(),
            DECasualTimeParser(),
            
            // Time-related parsers
            DETimeExpressionParser(),
            DESpecificTimeExpressionParser(),
            
            // Date-related parsers
            DEWeekdayParser(),
            DEMonthNameLittleEndianParser(),
            DESlashDateFormatParser(),
            
            // Time unit parsers
            DETimeUnitRelativeFormatParser(),
            DETimeUnitWithinFormatParser()
        ]
        
        let baseRefiners: [Refiner] = [
            DEMergeDateTimeRefiner(),
            DEMergeDateRangeRefiner()
        ]
        
        // Add common configuration (ISO parsers and refiners)
        let (parsers, refiners) = CommonConfiguration.includeCommonConfiguration(
            parsers: baseParsers,
            refiners: baseRefiners,
            strictMode: false
        )
        
        return Chrono(parsers: parsers, refiners: refiners)
    }
    
    /// Creates a strict configuration for German parsing
    /// - Returns: A Chrono instance with strict configuration
    static func createStrictConfiguration() -> Chrono {
        let baseParsers: [Parser] = [
            // Only formal parsers, no casual expressions
            DETimeExpressionParser(),
            DESpecificTimeExpressionParser(),
            DEMonthNameLittleEndianParser(),
            DESlashDateFormatParser()
        ]
        
        let baseRefiners: [Refiner] = [
            DEMergeDateTimeRefiner(),
            DEMergeDateRangeRefiner()
        ]
        
        // Add common configuration (ISO parsers and refiners)
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