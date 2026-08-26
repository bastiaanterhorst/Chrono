// ENSlashDateFormatParser.swift - Parser for date in slash format (MM/DD/YYYY)
import Foundation

/// Parser for slash date formats (e.g., 12/31/2021, 12/31, 12-31-2021)
public final class ENSlashDateFormatParser: Parser {
    // The leading lookbehind stops the match starting midway through a longer number: without
    // it "22-4" matched from the second digit as "2-4" and became 4 February.
    private static let PATTERN = "(?<![0-9./-])(?:on\\s*)?(0?[1-9]|1[0-2])[\\/-](0?[1-9]|[12][0-9]|3[01])(?:[\\/-]([0-9]{2,4}))?(?=\\W|$)"
    
    /// Returns the regex pattern for this parser
    public func pattern(context: ParsingContext) -> String {
        return ENSlashDateFormatParser.PATTERN
    }
    
    /// Extracts date from slash format expressions
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        // This pattern hard-codes the American order in its capture groups. When the reader's region
        // writes dates day-first, stand aside and let `ENSlashMonthFormatParser` — whose groups are
        // unconstrained — read them the right way round.
        if (context.options.numericDateOrder ?? .monthFirst) == .dayFirst { return nil }

        let component = context.createParsingComponents()
        let calendar = Calendar.current
        
        // In the US, the date format is usually MM/DD/YYYY
        let monthStr = match.string(at: 1)
        let dayStr = match.string(at: 2)
        
        guard let monthStr = monthStr, let month = Int(monthStr),
              let dayStr = dayStr, let day = Int(dayStr) else {
            return nil
        }
        
        // Validate month and day values
        if month < 1 || month > 12 {
            // Maybe it's actually day/month format
            if day >= 1 && day <= 12 && month >= 1 && month <= 31 {
                // If the "month" value is out of range, but the "day" value is in month range,
                // we can assume the format is DD/MM/YYYY
                component.assign(.day, value: month)
                component.assign(.month, value: day)
            } else {
                return nil
            }
        } else if day < 1 || day > 31 {
            return nil
        } else {
            // Standard MM/DD/YYYY format
            component.assign(.day, value: day)
            component.assign(.month, value: month)
        }
        
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
        
        component.addTag("ENSlashDateFormatParser")
        return component
    }
}