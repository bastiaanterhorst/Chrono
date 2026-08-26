// DE.swift - German locale parsers and refiners
import Foundation

/// German language date parsing
public enum DE {
    /// Creates a casual configuration for German parsing
    /// - Returns: A Chrono instance with casual configuration
    static func createCasualConfiguration() -> Chrono {
        let baseParsers: [Parser] = [
            DEISOWeekNumberParser(),
            DERelativeWeekParser(),
            DERelativeUnitKeywordParser(),

            // Casual date/time parsers
            DECasualDateParser(),
            DECasualTimeParser(),
            
            // Time-related parsers
            DETimeExpressionParser(),
            DESpecificTimeExpressionParser(),
            
            // Date-related parsers
            DEWeekdayParser(),
            DEMonthNameParser(),
            MonthNameDayParser(months: DEConstants.MONTH_DICTIONARY, tag: "DEMonthNameDayParser"),
            DESlashDateFormatParser(),
            
            // Time unit parsers
            DETimeUnitRelativeFormatParser(),
            DETimeUnitWithinFormatParser()
        ]
        
        let baseRefiners: [Refiner] = [
            DEMergeDateTimeRefiner(),
            DEMergeDateRangeRefiner(),
            DEPrioritizeWeekNumberRefiner(),

            // An end-of-period phrase Chrono cannot read must come back unrecognised, not
            // reversed: without this the month inside it was claimed alone and resolved to
            // the *first*, a month away from what was written.
            AdjacentWordGuardRefiner(precedingWords: ["ende", "ende des", "ende der", "zum ende"]),
            // Words around a match can rule it out as a date: a number introduced by
            // "version" or "chapter" is an identifier, one followed by a unit is a
            // measurement, and neither is ever a date in any language.
            AdjacentWordGuardRefiner(
                precedingWords: ["dr", "frau", "herr", "strasse des", "straße des", "weg", "allee", "platz", "str", "strasse", "straße", "version", "kapitel", "seite", "modell", "flug", "zimmer", "nr", "nummer", "verhältnis", "verhaltnis", "folge", "staffel", "schritt", "teil", "ergebnis", "stock", "etage"],
                followingWords: ["allee", "platz", "strasse", "straße", "cm", "mm", "km", "kg", "gramm", "ml", "liter", "meter", "prozent", "euro", "jahren", "jahre"])
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
            DEISOWeekNumberParser(),
            DERelativeWeekParser(),
            DERelativeUnitKeywordParser(),

            // Only formal parsers, no casual expressions
            DEMonthNameParser(),
            DETimeExpressionParser(),
            DESpecificTimeExpressionParser(),
            MonthNameDayParser(months: DEConstants.MONTH_DICTIONARY, tag: "DEMonthNameDayParser"),
            DESlashDateFormatParser()
        ]
        
        let baseRefiners: [Refiner] = [
            DEMergeDateTimeRefiner(),
            DEMergeDateRangeRefiner(),
            DEPrioritizeWeekNumberRefiner(),

            // An end-of-period phrase Chrono cannot read must come back unrecognised, not
            // reversed: without this the month inside it was claimed alone and resolved to
            // the *first*, a month away from what was written.
            AdjacentWordGuardRefiner(precedingWords: ["ende", "ende des", "ende der", "zum ende"]),
            // Words around a match can rule it out as a date: a number introduced by
            // "version" or "chapter" is an identifier, one followed by a unit is a
            // measurement, and neither is ever a date in any language.
            AdjacentWordGuardRefiner(
                precedingWords: ["dr", "frau", "herr", "strasse des", "straße des", "weg", "allee", "platz", "str", "strasse", "straße", "version", "kapitel", "seite", "modell", "flug", "zimmer", "nr", "nummer", "verhältnis", "verhaltnis", "folge", "staffel", "schritt", "teil", "ergebnis", "stock", "etage"],
                followingWords: ["allee", "platz", "strasse", "straße", "cm", "mm", "km", "kg", "gramm", "ml", "liter", "meter", "prozent", "euro", "jahren", "jahre"])
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
