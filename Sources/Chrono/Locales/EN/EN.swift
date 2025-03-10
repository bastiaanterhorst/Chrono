// EN.swift - English locale parsers and refiners
import Foundation

/// English language date parsing
public enum EN {
    /// Creates a casual configuration for English parsing
    /// - Returns: A Chrono instance with casual configuration
    static func createCasualConfiguration() -> Chrono {
        // IMPORTANT: Order of parsers determines priority - first parser to match wins
        let baseParsers: [Parser] = [
            // ISO Week parsers MUST come first for highest priority
            ENISOWeekNumberParser(),
            ENRelativeWeekParser(),
            
            // Casual date/time parsers
            ENCasualDateParser(),
            ENCasualTimeParser(),
            
            // Date-related parsers
            ENWeekdayParser(),
            ENRelativeDateFormatParser(),
            ENMonthNameParser(),
            ENMonthNameLittleEndianParser(),
            ENMonthNameMiddleEndianParser(),
            
            // Format-specific parsers
            ENSlashDateFormatParser(),
            ENSlashMonthFormatParser(),
            ENYearMonthDayParser(),
            
            // Time-related parsers come last to avoid conflicts with week numbers
            ENSimpleTimeParser(),
            ENTimeExpressionParser(),
            
            // Time unit parsers
            ENTimeUnitAgoFormatParser(),
            ENTimeUnitLaterFormatParser(),
            ENTimeUnitCasualRelativeFormatParser(),
            ENTimeUnitWithinFormatParser()
        ]
        
        let baseRefiners: [Refiner] = [
            // Basic mergers
            ENMergeDateTimeRefiner(),
            ENMergeDateRangeRefiner(),
            
            // Special mergers for casual language
            ENMergeRelativeFollowByDateRefiner(),
            ENMergeRelativeAfterDateRefiner(),
            
            // Filters and extraction
            ENExtractYearSuffixRefiner(),
            ENUnlikelyFormatFilter(),
            
            // Week number prioritization
            ENPrioritizeWeekNumberRefiner(),
            
            // Prioritization should be last
            ENPrioritizeSpecificDateRefiner()
        ]
        
        // Add common configuration (ISO parsers and refiners)
        let (parsers, refiners) = CommonConfiguration.includeCommonConfiguration(
            parsers: baseParsers,
            refiners: baseRefiners,
            strictMode: false
        )
        
        return Chrono(parsers: parsers, refiners: refiners)
    }
    
    /// Creates a strict configuration for English parsing
    /// - Returns: A Chrono instance with strict configuration
    static func createStrictConfiguration() -> Chrono {
        // IMPORTANT: Order matters for parser priority
        let baseParsers: [Parser] = [
            // ISO Week parsers MUST come first for highest priority
            ENISOWeekNumberParser(),
            ENRelativeWeekParser(),
            
            // Date parsers come before time parsers
            ENMonthNameParser(),
            ENMonthNameLittleEndianParser(),
            ENMonthNameMiddleEndianParser(),
            
            ENSlashDateFormatParser(),
            ENSlashMonthFormatParser(),
            ENYearMonthDayParser(),
            
            // Time parsers last to avoid conflicts with week numbers
            ENSimpleTimeParser(),
            ENTimeExpressionParser()
        ]
        
        let baseRefiners: [Refiner] = [
            ENMergeDateTimeRefiner(),
            ENMergeDateRangeRefiner(),
            ENExtractYearSuffixRefiner(),
            ENUnlikelyFormatFilter(),
            ENPrioritizeWeekNumberRefiner(), // Add week number prioritization
            ENPrioritizeSpecificDateRefiner()
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