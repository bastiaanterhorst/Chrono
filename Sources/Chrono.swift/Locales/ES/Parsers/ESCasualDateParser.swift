// ESCasualDateParser.swift - Parser for casual date expressions in Spanish
import Foundation

/// Parser for casual date expressions in Spanish (e.g., "hoy", "mañana", "ayer")
public final class ESCasualDateParser: Parser {
    public func pattern(context: ParsingContext) -> String {
        return "(ahora|hoy|mañana|ayer)(?=\\W|$)"
    }
    
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let matchText = match.string(at: 1)?.lowercased() else { return nil }
        
        let component = context.createParsingComponents()
        
        let calendar = Calendar.current
        let refDate = context.refDate
        
        switch matchText {
        case "ahora":
            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: refDate
            )
            
            component.assign(.year, value: components.year ?? 0)
            component.assign(.month, value: components.month ?? 0)
            component.assign(.day, value: components.day ?? 0)
            component.assign(.hour, value: components.hour ?? 0)
            component.assign(.minute, value: components.minute ?? 0)
            component.assign(.second, value: components.second ?? 0)
            
        case "hoy":
            let components = calendar.dateComponents([.year, .month, .day], from: refDate)
            component.assign(.year, value: components.year ?? 0)
            component.assign(.month, value: components.month ?? 0)
            component.assign(.day, value: components.day ?? 0)
            
        case "ayer":
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: refDate) {
                let components = calendar.dateComponents([.year, .month, .day], from: yesterday)
                component.assign(.year, value: components.year ?? 0)
                component.assign(.month, value: components.month ?? 0)
                component.assign(.day, value: components.day ?? 0)
            }
            
        case "mañana":
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: refDate) {
                let components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
                component.assign(.year, value: components.year ?? 0)
                component.assign(.month, value: components.month ?? 0)
                component.assign(.day, value: components.day ?? 0)
            }
            
        default:
            break
        }
        
        component.addTag("ESCasualDateParser")
        return component
    }
}