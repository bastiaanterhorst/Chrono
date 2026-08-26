// NL.swift - Dutch locale configuration
import Foundation

/// Dutch locale configuration
public struct NL {
    /// Casual configuration for Dutch parsing
    static public let casual: Chrono = {
        let option = createConfiguration()
        return option
    }()
    
    /// Strict configuration for Dutch parsing
    static public let strict: Chrono = {
        var option = createConfiguration()
        
        // Set to strict mode by removing casual parsers
        option = option.clone()
        // TODO: Modify parsers/refiners for strict mode when needed
        
        return option
    }()
    
    /// Creates the configuration for the Dutch locale
    static private func createConfiguration() -> Chrono {
        // Start with common parsers
        let parsers: [Parser] = [
            // ISO Week parsers should run first to avoid time parser conflicts
            NLISOWeekNumberParser(),
            NLRelativeWeekParser(),
            NLRelativeUnitKeywordParser(),

            // Make NLCasualDateParser the first parser to ensure it has highest priority
            NLCasualDateParser(),
            
            // Add the special time-of-day parser to handle vanavond and vannacht
            NLSpecialTimeOfDayParser(),
            
            // Standard ISO parser
            ISOFormatParser(),
            
            // Other Dutch-specific parsers
            NLCasualTimeParser(),
            NLMonthNameParser(),
            NLTimeExpressionParser(),
            MonthNameDayParser(months: NLConstants.MONTH_DICTIONARY, tag: "NLMonthNameDayParser"),
            NLWeekdayParser(),
            NLSlashDateFormatParser(),
            NLTimeUnitRelativeFormatParser(),
            NLTimeUnitWithinFormatParser()
        ]
        
        // Refiners
        let refiners: [Refiner] = [
            // Must precede OverlapRemovalRefiner so the weekday survives "volgende week donderdag".
            CombineRelativeWeekAndWeekdayRefiner(),

            // Standard refiners
            OverlapRemovalRefiner(),
            ForwardDateRefiner(),
            
            // Dutch-specific refiners
            NLMergeDateTimeRefiner(),
            NLMergeDateRangeRefiner(),
            NLPrioritizeWeekNumberRefiner(),

            // Bare month → 1st of month (NL builds its own config, so add it explicitly).
            MonthOnlyDayRefiner(),

            // An end-of-period phrase Chrono cannot read must come back unrecognised, not
            // reversed: without this the month inside it was claimed alone and resolved to
            // the *first*, a month away from what was written.
            AdjacentWordGuardRefiner(precedingWords: ["eind", "einde", "eind van", "eind van de", "eind van het"]),
            // Words around a match can rule it out as a date: a number introduced by
            // "version" or "chapter" is an identifier, one followed by a unit is a
            // measurement, and neither is ever a date in any language.
            AdjacentWordGuardRefiner(
                precedingWords: ["laan", "straat", "dr", "mw", "dhr", "mevr", "meneer", "mevrouw", "versie", "hoofdstuk", "pagina", "model", "vlucht", "kamer", "nr", "nummer", "verhouding", "aflevering", "seizoen", "stap", "deel", "niveau", "uitslag"],
                followingWords: ["weg", "laan", "straat", "cm", "mm", "km", "kg", "gram", "ml", "liter", "meter", "procent", "euro"])
        ]
        
        return Chrono(parsers: parsers, refiners: refiners)
    }
}
