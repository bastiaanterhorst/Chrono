// PTCasualDateParser.swift - Parser for casual date expressions in Portuguese
import Foundation

/// Parser for Portuguese casual date references like "hoje" (today), "amanhã" (tomorrow), etc.
public final class PTCasualDateParser: Parser {
    /// Returns the pattern for matching Portuguese casual date references
    public func pattern(context: ParsingContext) -> String {
        return "(agora|hoje|amanha|amanhã|ontem)(?=\\W|$)"
    }
    
    /// Extracts date components from a matched casual date reference
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let matchText = match.string(at: 1)?.lowercased() else { return nil }
        
        let component = context.createParsingComponents()
        let calendar = Calendar.current
        let refDate = context.refDate
        
        switch matchText {
        case "agora": // now
            let now = refDate
            let hour = calendar.component(.hour, from: now)
            let minute = calendar.component(.minute, from: now)
            let second = calendar.component(.second, from: now)
            
            component.assign(.hour, value: hour)
            component.assign(.minute, value: minute)
            component.assign(.second, value: second)
            component.imply(.day, value: calendar.component(.day, from: now))
            component.imply(.month, value: calendar.component(.month, from: now))
            component.imply(.year, value: calendar.component(.year, from: now))
            
        case "hoje": // today
            component.imply(.day, value: calendar.component(.day, from: refDate))
            component.imply(.month, value: calendar.component(.month, from: refDate))
            component.imply(.year, value: calendar.component(.year, from: refDate))
            
        case "amanha", "amanhã": // tomorrow
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: refDate) {
                component.imply(.day, value: calendar.component(.day, from: tomorrow))
                component.imply(.month, value: calendar.component(.month, from: tomorrow))
                component.imply(.year, value: calendar.component(.year, from: tomorrow))
            }
            
        case "ontem": // yesterday
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: refDate) {
                component.imply(.day, value: calendar.component(.day, from: yesterday))
                component.imply(.month, value: calendar.component(.month, from: yesterday))
                component.imply(.year, value: calendar.component(.year, from: yesterday))
            }
            
        default:
            return nil
        }
        
        component.addTag("PTCasualDateParser")
        return component
    }
}