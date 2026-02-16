// PT.swift - Portuguese locale implementation for Chrono.swift
import Foundation

/// Portuguese date parsing functionality
public enum PT {
    /// Portuguese casual date parser (including informal expressions)
    public static var casual: Chrono {
        // Create base configuration
        let baseParsers: [Parser] = [
            PTISOWeekNumberParser(),
            PTRelativeWeekParser(),
            PTRelativeUnitKeywordParser(),
            PTRelativeTimeUnitParser(),

            // Casual parsers
            PTCasualDateParser(),
            PTCasualTimeParser(),
            
            // Standard parsers
            PTMonthNameParser(),
            PTTimeExpressionParser(),
            PTWeekdayParser(),
            PTMonthNameLittleEndianParser()
        ]
        
        let baseRefiners: [Refiner] = [
            PTMergeDateTimeRefiner(),
            PTMergeDateRangeRefiner(),
            PTPrioritizeWeekNumberRefiner()
        ]
        
        // Add common configuration (ISO parsers and refiners)
        let (parsers, refiners) = CommonConfiguration.includeCommonConfiguration(
            parsers: baseParsers,
            refiners: baseRefiners,
            strictMode: false
        )
        
        return Chrono(parsers: parsers, refiners: refiners)
    }
    
    /// Portuguese strict parser (formal expressions only)
    public static var strict: Chrono {
        // Create base configuration - no casual parsers
        let baseParsers: [Parser] = [
            PTISOWeekNumberParser(),
            PTRelativeWeekParser(),
            PTRelativeUnitKeywordParser(),
            PTRelativeTimeUnitParser(),

            PTMonthNameParser(),
            PTTimeExpressionParser(),
            PTWeekdayParser(),
            PTMonthNameLittleEndianParser()
        ]
        
        let baseRefiners: [Refiner] = [
            PTMergeDateTimeRefiner(),
            PTMergeDateRangeRefiner(),
            PTPrioritizeWeekNumberRefiner()
        ]
        
        // Add common configuration (ISO parsers and refiners)
        let (parsers, refiners) = CommonConfiguration.includeCommonConfiguration(
            parsers: baseParsers,
            refiners: baseRefiners,
            strictMode: true
        )
        
        return Chrono(parsers: parsers, refiners: refiners)
    }
}
