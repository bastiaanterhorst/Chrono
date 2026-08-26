// PTCasualDateParser.swift - Parser for casual date expressions in Portuguese
import Foundation

/// Parser for Portuguese casual date references like "hoje" (today), "amanhã" (tomorrow), etc.
public final class PTCasualDateParser: Parser {
    /// Returns the pattern for matching Portuguese casual date references
    public func pattern(context: ParsingContext) -> String {
        // "depois de amanhã" leads "amanhã", and "anteontem" leads "ontem": an alternation is tried
        // left to right, so the shorter word would otherwise be matched inside the longer phrase and
        // report the wrong day.
        return "(?<!\\w)(depois\\s+de\\s+amanh[ãa]|anteontem|hoje|amanha|amanhã|ontem)(?=\\W|$)"
    }
    
    /// Extracts date components from a matched casual date reference
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let matchText = match.string(at: 1)?.foldedForMatching() else { return nil }
        
        let component = context.createParsingComponents()
        let calendar = Calendar.current
        let refDate = context.refDate
        
        // A stated day ("hoje", "amanhã", "ontem") is a KNOWN date, not an implied one — every
        // other locale assigns here, and consumers rely on known date components to schedule.
        // Collapsed so "depois  de  amanhã" matches its key whatever the spacing.
        let key = matchText.split(separator: " ", omittingEmptySubsequences: true).joined(separator: " ")
        let offsets: [String: Int] = [
            "hoje": 0, "amanha": 1, "ontem": -1,
            "depois de amanha": 2, "anteontem": -2,
        ]
        guard let offset = offsets[key],
              let target = calendar.date(byAdding: .day, value: offset, to: refDate) else {
            return nil
        }
        component.assign(.day, value: calendar.component(.day, from: target))
        component.assign(.month, value: calendar.component(.month, from: target))
        component.assign(.year, value: calendar.component(.year, from: target))

        component.addTag("PTCasualDateParser")
        return component
    }
}