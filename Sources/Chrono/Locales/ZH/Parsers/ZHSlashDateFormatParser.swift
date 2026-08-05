// ZHSlashDateFormatParser.swift - Parser for big-endian slash dates like "2026/3/15" and "3/15"
import Foundation

/// Parser for slash-separated dates in Chinese — `2026/3/15`, `3/15`.
///
/// Chinese writes dates **big-endian**, largest unit first: year / month / day, mirroring the
/// spoken order `2026年3月15日`. A two-part `3/15` is therefore *month* / *day* — the exact
/// opposite of the Dutch (and most European) day-first convention, and it is why this parser
/// cannot share NLSlashDateFormatParser's group order.
///
/// Only the ASCII slash form is handled; `2026年3月15日` belongs to the standard parser.
public struct ZHSlashDateFormatParser: Parser {
    public init() {}

    /// Capture groups: 1 = optional 4-digit year, 2 = month, 3 = day.
    ///
    /// The lookbehind and lookahead keep the match from starting or ending in the middle of a
    /// longer run of digits and slashes: `12/3/15` is genuinely ambiguous (is `12` a year, a month,
    /// or a day?) and must yield nothing rather than a guess, and a path-like `3/15/2026/x` must
    /// not be half-consumed.
    public func pattern(context: ParsingContext) -> String {
        return "(?<![0-9０-９/])(?:([0-9]{4})/)?([0-9]{1,2})/([0-9]{1,2})(?![0-9/])"
    }

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let monthText = match.string(at: 2), let month = Int(monthText),
              let dayText = match.string(at: 3), let day = Int(dayText) else {
            return nil
        }

        // Reject out-of-range values outright rather than letting the calendar roll them over:
        // `13/45` and `3/99` are not dates, they are version numbers, scores or fractions.
        guard (1...12).contains(month), (1...31).contains(day) else {
            return nil
        }

        let component = context.createParsingComponents()
        component.assign(.month, value: month)
        component.assign(.day, value: day)

        if let yearText = match.string(at: 1), let year = Int(yearText) {
            // An explicit four-digit year is stated, so it is certain.
            component.assign(.year, value: year)
        } else {
            // No year given: infer the nearest sensible one, but keep it implied — the user never
            // said it. Same rule as `JAStandardParser`: a date already behind the reference rolls
            // into next year only when the caller asked for forward-only results.
            let calendar = Calendar.current
            let referenceYear = calendar.component(.year, from: context.refDate)
            let referenceMonth = calendar.component(.month, from: context.refDate)
            let referenceDay = calendar.component(.day, from: context.refDate)

            var year = referenceYear
            let isPast = month < referenceMonth || (month == referenceMonth && day < referenceDay)
            if isPast && context.options.forwardDate {
                year += 1
            }

            component.imply(.year, value: year)
        }

        component.addTag("ZHSlashDateFormatParser")
        return component
    }
}
