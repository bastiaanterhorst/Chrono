// FRCasualDateParser.swift - Parser for French casual date expressions
import Foundation

/// Parser for French casual date references like "aujourd'hui", "hier", "demain" etc.
public final class FRCasualDateParser: Parser {
    /// The pattern to match French casual date references
    public func pattern(context: ParsingContext) -> String {
        return "maintenant|aujourd'hui|auj|hier|avant[ -]hier|demain|apres[ -]demain|cette nuit|ce matin|cet après-midi|ce soir|soir"
    }
    
    /// Extracts date components from a French casual date reference
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let component = context.createParsingComponents()
        
        let matchText = match.matchedText.lowercased()
        let refDate = context.refDate
        let calendar = Calendar.current
        
        switch matchText {
        case "maintenant":
            // Now
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: refDate)
            component.assign(.year, value: components.year ?? 0)
            component.assign(.month, value: components.month ?? 0)
            component.assign(.day, value: components.day ?? 0)
            component.assign(.hour, value: components.hour ?? 0)
            component.assign(.minute, value: components.minute ?? 0)
            component.assign(.second, value: components.second ?? 0)
            
        case "aujourd'hui", "auj":
            // Today
            let components = calendar.dateComponents([.year, .month, .day], from: refDate)
            component.assign(.year, value: components.year ?? 0)
            component.assign(.month, value: components.month ?? 0)
            component.assign(.day, value: components.day ?? 0)
            
        case "hier":
            // Yesterday
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: refDate) {
                let components = calendar.dateComponents([.year, .month, .day], from: yesterday)
                component.assign(.year, value: components.year ?? 0)
                component.assign(.month, value: components.month ?? 0)
                component.assign(.day, value: components.day ?? 0)
            }
            
        case "avant-hier", "avant hier":
            // Day before yesterday
            if let dayBeforeYesterday = calendar.date(byAdding: .day, value: -2, to: refDate) {
                let components = calendar.dateComponents([.year, .month, .day], from: dayBeforeYesterday)
                component.assign(.year, value: components.year ?? 0)
                component.assign(.month, value: components.month ?? 0)
                component.assign(.day, value: components.day ?? 0)
            }
            
        case "demain":
            // Tomorrow
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: refDate) {
                let components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
                component.assign(.year, value: components.year ?? 0)
                component.assign(.month, value: components.month ?? 0)
                component.assign(.day, value: components.day ?? 0)
            }
            
        case "apres-demain", "apres demain":
            // Day after tomorrow
            if let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: refDate) {
                let components = calendar.dateComponents([.year, .month, .day], from: dayAfterTomorrow)
                component.assign(.year, value: components.year ?? 0)
                component.assign(.month, value: components.month ?? 0)
                component.assign(.day, value: components.day ?? 0)
            }
            
        case "ce soir", "soir":
            // This evening
            let components = calendar.dateComponents([.year, .month, .day], from: refDate)
            component.assign(.year, value: components.year ?? 0)
            component.assign(.month, value: components.month ?? 0)
            component.assign(.day, value: components.day ?? 0)
            component.assign(.hour, value: 20)
            component.assign(.minute, value: 0)
            component.assign(.second, value: 0)
            component.assign(.meridiem, value: Meridiem.pm.rawValue)
            
        case "cette nuit":
            // Tonight
            let components = calendar.dateComponents([.year, .month, .day], from: refDate)
            component.assign(.year, value: components.year ?? 0)
            component.assign(.month, value: components.month ?? 0)
            component.assign(.day, value: components.day ?? 0)
            component.assign(.hour, value: 22)
            component.assign(.minute, value: 0)
            component.assign(.second, value: 0)
            component.assign(.meridiem, value: Meridiem.pm.rawValue)
            
        case "ce matin":
            // This morning
            let components = calendar.dateComponents([.year, .month, .day], from: refDate)
            component.assign(.year, value: components.year ?? 0)
            component.assign(.month, value: components.month ?? 0)
            component.assign(.day, value: components.day ?? 0)
            component.assign(.hour, value: 8)
            component.assign(.minute, value: 0)
            component.assign(.second, value: 0)
            component.assign(.meridiem, value: Meridiem.am.rawValue)
            
        case "cet après-midi":
            // This afternoon
            let components = calendar.dateComponents([.year, .month, .day], from: refDate)
            component.assign(.year, value: components.year ?? 0)
            component.assign(.month, value: components.month ?? 0)
            component.assign(.day, value: components.day ?? 0)
            component.assign(.hour, value: 15)
            component.assign(.minute, value: 0)
            component.assign(.second, value: 0)
            component.assign(.meridiem, value: Meridiem.pm.rawValue)
            
        default:
            return nil
        }
        
        component.addTag("FRCasualDateParser")
        return component
    }
}