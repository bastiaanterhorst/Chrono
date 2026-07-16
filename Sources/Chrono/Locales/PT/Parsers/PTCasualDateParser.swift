// PTCasualDateParser.swift - Parser for casual date expressions in Portuguese
import Foundation

/// Parser for Portuguese casual date references like "hoje" (today), "amanhã" (tomorrow), etc.
public final class PTCasualDateParser: Parser {
    /// Returns the pattern for matching Portuguese casual date references
    public func pattern(context: ParsingContext) -> String {
        return "(?<!\\w)(hoje|amanha|amanhã|ontem)(?=\\W|$)"
    }
    
    /// Extracts date components from a matched casual date reference
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let matchText = match.string(at: 1)?.foldedForMatching() else { return nil }
        
        let component = context.createParsingComponents()
        let calendar = Calendar.current
        let refDate = context.refDate
        
        // A stated day ("hoje", "amanhã", "ontem") is a KNOWN date, not an implied one — every
        // other locale assigns here, and consumers rely on known date components to schedule.
        switch matchText {
        case "hoje": // today
            component.assign(.day, value: calendar.component(.day, from: refDate))
            component.assign(.month, value: calendar.component(.month, from: refDate))
            component.assign(.year, value: calendar.component(.year, from: refDate))

        case "amanha": // tomorrow
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: refDate) {
                component.assign(.day, value: calendar.component(.day, from: tomorrow))
                component.assign(.month, value: calendar.component(.month, from: tomorrow))
                component.assign(.year, value: calendar.component(.year, from: tomorrow))
            }

        case "ontem": // yesterday
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: refDate) {
                component.assign(.day, value: calendar.component(.day, from: yesterday))
                component.assign(.month, value: calendar.component(.month, from: yesterday))
                component.assign(.year, value: calendar.component(.year, from: yesterday))
            }

        default:
            return nil
        }
        
        component.addTag("PTCasualDateParser")
        return component
    }
}