// FR.swift - French locale parsers and refiners
import Foundation

/// French language date parsing
public enum FR {
    /// Creates a casual configuration for French parsing
    /// - Returns: A Chrono instance with casual configuration
    static func createCasualConfiguration() -> Chrono {
        let parsers: [Parser] = [
            FRCasualDateParser(),
            FRCasualTimeParser(),
            FRTimeExpressionParser(),
            FRWeekdayParser(),
            FRSpecificTimeExpressionParser()
        ]
        
        let refiners: [Refiner] = [
            FRMergeDateTimeRefiner(),
            FRMergeDateRangeRefiner()
        ]
        
        return Chrono(parsers: parsers, refiners: refiners)
    }
    
    /// Creates a strict configuration for French parsing
    /// - Returns: A Chrono instance with strict configuration
    static func createStrictConfiguration() -> Chrono {
        let parsers: [Parser] = [
            FRTimeExpressionParser(),
            FRSpecificTimeExpressionParser()
        ]
        
        let refiners: [Refiner] = [
            FRMergeDateTimeRefiner(),
            FRMergeDateRangeRefiner()
        ]
        
        return Chrono(parsers: parsers, refiners: refiners)
    }
    
    /// A Chrono instance with casual configuration
    public static let casual = createCasualConfiguration()
    
    /// A Chrono instance with strict configuration
    public static let strict = createStrictConfiguration()
}