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
            MonthOnlyDayRefiner()
        ]
        
        return Chrono(parsers: parsers, refiners: refiners)
    }
}
