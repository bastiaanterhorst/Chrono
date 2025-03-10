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
            // Make NLCasualDateParser the first parser to ensure it has highest priority
            NLCasualDateParser(),
            
            // Add the special time-of-day parser to handle vanavond and vannacht
            NLSpecialTimeOfDayParser(),
            
            // Standard ISO parser
            ISOFormatParser(),
            
            // Other Dutch-specific parsers
            NLCasualTimeParser(),
            NLTimeExpressionParser(),
            NLMonthNameLittleEndianParser(),
            NLWeekdayParser(),
            NLSlashDateFormatParser(),
            NLTimeUnitRelativeFormatParser(),
            NLTimeUnitWithinFormatParser()
        ]
        
        // Refiners
        let refiners: [Refiner] = [
            // Standard refiners
            OverlapRemovalRefiner(),
            ForwardDateRefiner(),
            
            // Dutch-specific refiners
            NLMergeDateTimeRefiner(),
            NLMergeDateRangeRefiner()
        ]
        
        return Chrono(parsers: parsers, refiners: refiners)
    }
}