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
            ENRelativeUnitKeywordParser(),
            
            // Casual date/time parsers
            ENCasualDateParser(),
            ENCasualTimeParser(),
            
            // Date-related parsers
            ENWeekdayParser(),
            ENRelativeDateFormatParser(),
            ENMonthNameParser(),
            MonthNameDayParser(months: ENMonthNameMiddleEndianParser.monthDictionary, connectors: ["of"], tag: "ENMonthNameDayParser"),
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
            // These lead the list. They only ever REMOVE a reading, and they must do it
            // before the merge refiners run: a merge can glue a bogus reading to a real
            // neighbouring date ("versao 3.5 entregar em 12 de setembro" became one range),
            // and dropping the pair afterwards takes the real date down with it.
            // An end-of-period phrase Chrono cannot read must come back unrecognised, not
            // reversed: without this the month inside it was claimed alone and resolved to
            // the *first*, a month away from what was written.
            AdjacentWordGuardRefiner(precedingWords: ["end of", "end of the"]),
            // Words around a match can rule it out as a date: a number introduced by
            // "version" or "chapter" is an identifier, one followed by a unit is a
            // measurement, and neither is ever a date in any language.
            AdjacentWordGuardRefiner(
                precedingWords: ["flat", "final", "score", "drew", "beat", "won", "lost", "version", "chapter", "ch", "page", "p", "model", "flight", "room", "no", "nr", "ratio", "issue", "episode", "ep", "season", "apt", "suite", "step", "part", "level", "build"],
                followingWords: ["blvd", "ave", "rd", "lane", "avenue", "road", "street", "inch", "inches", "cup", "cups", "cm", "mm", "km", "kg", "lb", "lbs", "oz", "ml", "tsp", "tbsp", "miles", "mile", "percent", "ratio"]),

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
            ENRelativeUnitKeywordParser(),
            
            // Date parsers come before time parsers
            ENMonthNameParser(),
            MonthNameDayParser(months: ENMonthNameMiddleEndianParser.monthDictionary, connectors: ["of"], tag: "ENMonthNameDayParser"),
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
