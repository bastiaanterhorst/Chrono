// KOSlashDateFormatParser.swift - 2026.4.22 / 4/22 / 2026-04-22.
import Foundation

/// Korean numeric dates. Korean writes largest unit first (2026.4.22), so a two-number form is
/// read month-first by default — though the order still comes from the reader's region, since
/// someone reading Korean on a day-first system writes dates that way.
public struct KOSlashDateFormatParser: Parser {
    public init() {}

    public func pattern(context: ParsingContext) -> String {
        // The lookbehind stops the match starting midway through a longer number.
        return "(?<![0-9./-])(?:(\\d{4})[./-])?(\\d{1,2})[./-](\\d{1,2})(?=\\W|$)"
    }

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let firstStr = match.string(at: 2), let first = Int(firstStr),
              let secondStr = match.string(at: 3), let second = Int(secondStr) else { return nil }

        // With a year stated the form is unambiguously 년.월.일, so the remaining two are in that
        // order; otherwise the reader's regional convention decides.
        let order: NumericDateOrder = match.string(at: 1) != nil
            ? .monthFirst
            : (context.options.numericDateOrder ?? .monthFirst)
        guard let (day, month) = NumericDateInterpreter.dayAndMonth(first: first, second: second,
                                                                    order: order) else { return nil }

        let components = context.createParsingComponents()
        components.assign(.day, value: day)
        components.assign(.month, value: month)
        if let yearStr = match.string(at: 1), let year = Int(yearStr) {
            components.assign(.year, value: year)
        } else {
            components.imply(.year, value: Calendar.current.component(.year, from: context.refDate))
        }
        components.addTag("KOSlashDateFormatParser")
        return components
    }
}
