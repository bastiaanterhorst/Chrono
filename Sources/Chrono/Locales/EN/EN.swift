// EN.swift - English locale parsers and refiners
import Foundation

/// English language date parsing
public enum EN {
    /// Creates a casual configuration for English parsing
    /// - Returns: A Chrono instance with casual configuration
    static func createCasualConfiguration() -> Chrono {
        let baseParsers: [Parser] = [
            // Casual date/time parsers
            ENCasualDateParser(),
            ENCasualTimeParser(),
            
            // Time-related parsers
            ENSimpleTimeParser(),
            ENTimeExpressionParser(),
            
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
            ENISOWeekNumberParser(),
            
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
        let baseParsers: [Parser] = [
            // Only formal parsers, no casual expressions
            ENSimpleTimeParser(),
            ENTimeExpressionParser(),
            
            ENMonthNameParser(),
            ENMonthNameLittleEndianParser(),
            ENMonthNameMiddleEndianParser(),
            
            ENSlashDateFormatParser(),
            ENSlashMonthFormatParser(),
            ENYearMonthDayParser(),
            ENISOWeekNumberParser()
        ]
        
        let baseRefiners: [Refiner] = [
            ENMergeDateTimeRefiner(),
            ENMergeDateRangeRefiner(),
            ENExtractYearSuffixRefiner(),
            ENUnlikelyFormatFilter(),
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