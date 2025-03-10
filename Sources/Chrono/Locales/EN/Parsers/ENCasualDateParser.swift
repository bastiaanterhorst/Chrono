// ENCasualDateParser.swift - Parser for casual date expressions
import Foundation

/// Parser for casual date references like "today", "tomorrow", etc.
public final class ENCasualDateParser: Parser {
    /// The pattern to match casual date references
    public func pattern(context: ParsingContext) -> String {
        return "(now|today|tonight|tomorrow|tmr|tmrw|yesterday|last\\s*night)(?=\\W|$)"
    }
    
    /// Extracts date components from a casual date reference
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let matchText = match.string(at: 1)?.lowercased() else { return nil }
        
        let component = context.createParsingComponents()
        
        let calendar = Calendar.current
        let refDate = context.refDate
        
        switch matchText {
        case "now":
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
            
        case "today":
            let components = calendar.dateComponents([.year, .month, .day], from: refDate)
            component.assign(.year, value: components.year ?? 0)
            component.assign(.month, value: components.month ?? 0)
            component.assign(.day, value: components.day ?? 0)
            
        case "yesterday":
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: refDate) {
                let components = calendar.dateComponents([.year, .month, .day], from: yesterday)
                component.assign(.year, value: components.year ?? 0)
                component.assign(.month, value: components.month ?? 0)
                component.assign(.day, value: components.day ?? 0)
            }
            
        case "tomorrow", "tmr", "tmrw":
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: refDate) {
                let components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
                component.assign(.year, value: components.year ?? 0)
                component.assign(.month, value: components.month ?? 0)
                component.assign(.day, value: components.day ?? 0)
            }
            
        case "tonight":
            let components = calendar.dateComponents([.year, .month, .day], from: refDate)
            component.assign(.year, value: components.year ?? 0)
            component.assign(.month, value: components.month ?? 0)
            component.assign(.day, value: components.day ?? 0)
            component.assign(.hour, value: 22)
            
        default:
            if matchText.contains("last") && matchText.contains("night") {
                var targetDate = refDate
                
                // If it's morning, "last night" should refer to yesterday evening
                let hour = calendar.component(.hour, from: refDate)
                if hour > 6 {
                    targetDate = calendar.date(byAdding: .day, value: -1, to: refDate) ?? refDate
                }
                
                let components = calendar.dateComponents([.year, .month, .day], from: targetDate)
                component.assign(.year, value: components.year ?? 0)
                component.assign(.month, value: components.month ?? 0)
                component.assign(.day, value: components.day ?? 0)
                component.imply(.hour, value: 0)
            }
        }
        
        component.addTag("ENCasualDateParser")
        return component
    }
}