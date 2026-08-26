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
            
            // Date-related parsers
            ESSlashDateFormatParser(),

            // Time-related parsers
            ESTimeExpressionParser(),

            // Date-related parsers
            ESWeekdayParser(),
            ESMonthNameParser(),
            MonthNameDayParser(months: ESConstants.MONTH_DICTIONARY, connectors: ["de"], tag: "ESMonthNameDayParser"),
            
            // Time unit parsers
            ESTimeUnitWithinFormatParser()
        ]
        
        let baseRefiners: [Refiner] = [
            // These lead the list. They only ever REMOVE a reading, and they must do it
            // before the merge refiners run: a merge can glue a bogus reading to a real
            // neighbouring date ("versao 3.5 entregar em 12 de setembro" became one range),
            // and dropping the pair afterwards takes the real date down with it.
            // An end-of-period phrase Chrono cannot read must come back unrecognised, not
            // reversed: without this the month inside it was claimed alone and resolved to
            // the *first*, a month away from what was written.
            AdjacentWordGuardRefiner(precedingWords: ["fin", "fin de", "fin del", "finales de", "a fin de"]),
            // Words around a match can rule it out as a date: a number introduced by
            // "version" or "chapter" is an identifier, one followed by a unit is a
            // measurement, and neither is ever a date in any language.
            AdjacentWordGuardRefiner(
                precedingWords: ["avenida de", "plaza de", "calle de", "teatro", "cine", "bar", "hotel", "casa", "estadio", "restaurante", "versión", "version", "capítulo", "capitulo", "página", "pagina", "modelo", "vuelo", "habitación", "habitacion", "nº", "no", "ratio", "proporción", "proporcion", "episodio", "temporada", "paso", "parte", "nivel", "calle", "avenida", "plaza", "sr", "sra", "dr"],
                followingWords: ["avenida", "plaza", "calle", "cm", "mm", "km", "kg", "ml", "litros", "litro", "metros", "metro", "euros", "por ciento"]),

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
            ESSlashDateFormatParser(),
            ESTimeExpressionParser(),
            ESMonthNameParser(),
            MonthNameDayParser(months: ESConstants.MONTH_DICTIONARY, connectors: ["de"], tag: "ESMonthNameDayParser"),
            ESTimeUnitWithinFormatParser()
        ]
        
        let baseRefiners: [Refiner] = [
            // These lead the list. They only ever REMOVE a reading, and they must do it
            // before the merge refiners run: a merge can glue a bogus reading to a real
            // neighbouring date ("versao 3.5 entregar em 12 de setembro" became one range),
            // and dropping the pair afterwards takes the real date down with it.
            // An end-of-period phrase Chrono cannot read must come back unrecognised, not
            // reversed: without this the month inside it was claimed alone and resolved to
            // the *first*, a month away from what was written.
            AdjacentWordGuardRefiner(precedingWords: ["fin", "fin de", "fin del", "finales de", "a fin de"]),
            // Words around a match can rule it out as a date: a number introduced by
            // "version" or "chapter" is an identifier, one followed by a unit is a
            // measurement, and neither is ever a date in any language.
            AdjacentWordGuardRefiner(
                precedingWords: ["avenida de", "plaza de", "calle de", "teatro", "cine", "bar", "hotel", "casa", "estadio", "restaurante", "versión", "version", "capítulo", "capitulo", "página", "pagina", "modelo", "vuelo", "habitación", "habitacion", "nº", "no", "ratio", "proporción", "proporcion", "episodio", "temporada", "paso", "parte", "nivel", "calle", "avenida", "plaza", "sr", "sra", "dr"],
                followingWords: ["avenida", "plaza", "calle", "cm", "mm", "km", "kg", "ml", "litros", "litro", "metros", "metro", "euros", "por ciento"]),

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
