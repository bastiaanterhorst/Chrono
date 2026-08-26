// DESlashDateFormatParser.swift - Parser for date in European slash format (DD/MM/YYYY)
import Foundation

/// Parser for European slash date formats (e.g., 31/12/2021, 31/12, 31-12-2021)
public final class DESlashDateFormatParser: Parser {
    // Accept ".", "/" and "-" as separators so dotted "dd.mm" dates (common in DE) are recognized
    // as dates, not times. The leading "\\s*" makes this match's span align with the time parser's
    // (which consumes a leading boundary space) so OverlapRemovalRefiner prefers the date.
    private static let PATTERN = "(?:am\\s*)?\\s*(0?[1-9]|[12][0-9]|3[01])[\\/\\.\\-](0?[1-9]|1[0-2])(?:[\\/\\.\\-]([0-9]{2,4}))?(?=\\W|$)"
    
    /// Returns the regex pattern for this parser
    public func pattern(context: ParsingContext) -> String {
        return DESlashDateFormatParser.PATTERN
    }
    
    /// Extracts date from slash format expressions (European format: DD/MM/YYYY)
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let component = context.createParsingComponents()
        let calendar = Calendar.current
        
        // In Europe, the date format is DD/MM/YYYY
        let dayStr = match.string(at: 1)
        let monthStr = match.string(at: 2)
        
        guard let dayStr = dayStr, let day = Int(dayStr),
              let monthStr = monthStr, let month = Int(monthStr) else {
            return nil
        }
        
        // Validate day and month values
        if day < 1 || day > 31 {
            return nil
        }
        
        if month < 1 || month > 12 {
            return nil
        }
        
        component.assign(.day, value: day)
        component.assign(.month, value: month)
        
        // Year handling
        if let yearStr = match.string(at: 3), let year = Int(yearStr) {
            if year < 100 {
                component.assign(.year, value: year + 2000)
            } else {
                component.assign(.year, value: year)
            }
        } else {
            // No year stated, so only *infer* the reference year. Forward-dating a date that has
            // already gone by is `ForwardDateRefiner`'s job — one rule, shared by every locale.
            // Five copies of that comparison used to live in these parsers, and the NL copy had
            // drifted into comparing months alone (so "20/8" on 26 August stayed in the past).
            component.imply(.year, value: calendar.component(.year, from: context.refDate))
        }
        
        component.addTag("DESlashDateFormatParser")
        return component
    }
}