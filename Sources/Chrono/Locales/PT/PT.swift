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
            PTSlashDateFormatParser(),
            PTTimeExpressionParser(),
            PTWeekdayParser(),
            MonthNameDayParser(months: PTConstants.MONTH_DICTIONARY, connectors: ["de"], tag: "PTMonthNameDayParser")
        ]
        
        let baseRefiners: [Refiner] = [
            PTMergeDateTimeRefiner(),
            PTMergeDateRangeRefiner(),
            PTPrioritizeWeekNumberRefiner(),

            // An end-of-period phrase Chrono cannot read must come back unrecognised, not
            // reversed: without this the month inside it was claimed alone and resolved to
            // the *first*, a month away from what was written.
            AdjacentWordGuardRefiner(precedingWords: ["fim", "fim do", "fim de", "final do", "final de"]),
            // Words around a match can rule it out as a date: a number introduced by
            // "version" or "chapter" is an identifier, one followed by a unit is a
            // measurement, and neither is ever a date in any language.
            AdjacentWordGuardRefiner(
                precedingWords: ["praça de", "praca de", "rua de", "teatro", "cinema", "bar", "hotel", "casa", "estadio", "restaurante", "versão", "versao", "capítulo", "capitulo", "página", "pagina", "modelo", "voo", "quarto", "nº", "no", "proporção", "proporcao", "episódio", "episodio", "temporada", "passo", "parte", "nível", "nivel", "rua", "avenida", "av", "sr", "sra", "dr"],
                followingWords: ["avenida", "praça", "praca", "rua", "cm", "mm", "km", "kg", "ml", "litros", "litro", "metros", "metro", "reais", "mil"])
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
            PTSlashDateFormatParser(),
            PTTimeExpressionParser(),
            PTWeekdayParser(),
            MonthNameDayParser(months: PTConstants.MONTH_DICTIONARY, connectors: ["de"], tag: "PTMonthNameDayParser")
        ]
        
        let baseRefiners: [Refiner] = [
            PTMergeDateTimeRefiner(),
            PTMergeDateRangeRefiner(),
            PTPrioritizeWeekNumberRefiner(),

            // An end-of-period phrase Chrono cannot read must come back unrecognised, not
            // reversed: without this the month inside it was claimed alone and resolved to
            // the *first*, a month away from what was written.
            AdjacentWordGuardRefiner(precedingWords: ["fim", "fim do", "fim de", "final do", "final de"]),
            // Words around a match can rule it out as a date: a number introduced by
            // "version" or "chapter" is an identifier, one followed by a unit is a
            // measurement, and neither is ever a date in any language.
            AdjacentWordGuardRefiner(
                precedingWords: ["praça de", "praca de", "rua de", "teatro", "cinema", "bar", "hotel", "casa", "estadio", "restaurante", "versão", "versao", "capítulo", "capitulo", "página", "pagina", "modelo", "voo", "quarto", "nº", "no", "proporção", "proporcao", "episódio", "episodio", "temporada", "passo", "parte", "nível", "nivel", "rua", "avenida", "av", "sr", "sra", "dr"],
                followingWords: ["avenida", "praça", "praca", "rua", "cm", "mm", "km", "kg", "ml", "litros", "litro", "metros", "metro", "reais", "mil"])
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
