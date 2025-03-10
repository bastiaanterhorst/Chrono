// PTCasualTimeParser.swift - Parser for casual time expressions in Portuguese
import Foundation

/// Parser for Portuguese casual time references like "meio-dia" (noon), "meia-noite" (midnight), etc.
public final class PTCasualTimeParser: Parser {
    /// Returns the pattern for matching Portuguese casual time references
    public func pattern(context: ParsingContext) -> String {
        return "(meio[\\s\\-]dia|meia[\\s\\-]noite)(?=\\W|$)"
    }
    
    /// Extracts time components from a matched casual time reference
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let matchText = match.string(at: 1)?.lowercased() else { return nil }
        
        let component = context.createParsingComponents()
        let refDate = context.refDate
        let calendar = Calendar.current
        
        // Implicitly set date to reference date
        component.imply(.day, value: calendar.component(.day, from: refDate))
        component.imply(.month, value: calendar.component(.month, from: refDate))
        component.imply(.year, value: calendar.component(.year, from: refDate))
        
        if matchText.contains("meio") {
            // Noon (12:00)
            component.assign(.hour, value: 12)
            component.assign(.minute, value: 0)
            component.assign(.second, value: 0)
            component.assign(.meridiem, value: Meridiem.pm.rawValue)
        }
        
        if matchText.contains("meia") {
            // Midnight (0:00)
            component.assign(.hour, value: 0)
            component.assign(.minute, value: 0)
            component.assign(.second, value: 0)
            component.assign(.meridiem, value: Meridiem.am.rawValue)
        }
        
        component.addTag("PTCasualTimeParser")
        return component
    }
}