// ESCasualDateParser.swift - Parser for casual date expressions in Spanish
import Foundation

/// Parser for casual date expressions in Spanish (e.g., "hoy", "mañana", "ayer")
public final class ESCasualDateParser: Parser {
    public func pattern(context: ParsingContext) -> String {
        // "pasado mañana" leads "mañana", and "anteayer" leads "ayer": an alternation is tried left
        // to right, so the shorter word would otherwise be matched inside the longer phrase and
        // report the wrong day.
        return "(?<!\\w)(pasado\\s+ma[ñn]ana|antes?\\s*de\\s*ayer|anteayer|antier|hoy|ma[ñn]ana|ayer)(?=\\W|$)"
    }
    
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let matchText = match.string(at: 1)?.foldedForMatching() else { return nil }
        
        let component = context.createParsingComponents()
        
        let calendar = Calendar.current
        let refDate = context.refDate
        
        // Collapsed so "pasado  mañana" and "antes de ayer" match their key whatever the spacing.
        let key = matchText.split(separator: " ", omittingEmptySubsequences: true).joined(separator: " ")
        let offsets: [String: Int] = [
            "hoy": 0, "manana": 1, "ayer": -1,
            "pasado manana": 2,
            "anteayer": -2, "antier": -2, "antes de ayer": -2, "ante de ayer": -2,
        ]
        // An unrecognised match must yield nothing. Falling through to the reference date instead
        // meant any phrase the pattern grew but the switch did not know silently became *today* —
        // which is how "pasado mañana" resolved to today rather than the day after tomorrow.
        guard let offset = offsets[key],
              let target = calendar.date(byAdding: .day, value: offset, to: refDate) else {
            return nil
        }
        let components = calendar.dateComponents([.year, .month, .day], from: target)
        component.assign(.year, value: components.year ?? 0)
        component.assign(.month, value: components.month ?? 0)
        component.assign(.day, value: components.day ?? 0)

        component.addTag("ESCasualDateParser")
        return component
    }
}