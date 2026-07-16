// ENTimeExpressionParser.swift - Parser for time expressions
import Foundation

/// Parser for time expressions like "at 3", "6:30pm", "from 4:00", etc.
///
/// Two forms are accepted (see openspec spec `numeric-time-validation`):
/// - Connector form: an explicit time-connector word (`at`, `from`, `before`, `after`, `until`,
///   `till`) followed by a time, which may be a bare hour ("at 3"). The connector must start on a
///   word boundary and be separated from the time by whitespace, so "at50" and "versi[on 2].0"
///   don't match.
/// - Bare form: a time qualified by minutes and/or a meridiem ("7pm", "15:00", "3.30pm") preceded
///   by whitespace or string start. Unqualified bare numbers ("buy 2 apples") never match.
public final class ENTimeExpressionParser: Parser {
    /// The pattern to match time expressions
    public func pattern(context: ParsingContext) -> String {
        // Group 1: connector-form time (bare hour allowed)
        // Group 2: bare-form time (minutes and/or meridiem required)
        return "(?:(?<!\\w)(?:at|from|before|after|until|till)\\s+" +
               "(noon|midnight|\\d{1,2}(?:[:.]\\d{2})?(?:\\s*[ap]\\.?m\\.?|[ap])?)" +
               "|(?<!\\S)" +
               "(\\d{1,2}(?:[:.]\\d{2})?(?:\\s*[ap]\\.?m\\.?|[ap])|\\d{1,2}:\\d{2}))" +
               "(?=\\W|$)"
    }

    /// Extracts time components from a time expression
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let component = context.createParsingComponents()

        guard let text = (match.string(at: 1) ?? match.string(at: 2))?.lowercased() else { return nil }

        // Special cases: noon and midnight (connector form only)
        if text == "noon" {
            component.assign(.hour, value: 12)
            component.assign(.minute, value: 0)
            component.assign(.second, value: 0)
            component.assign(.meridiem, value: Meridiem.pm.rawValue)
            return component
        }

        if text == "midnight" {
            component.assign(.hour, value: 0)
            component.assign(.minute, value: 0)
            component.assign(.second, value: 0)
            component.assign(.meridiem, value: Meridiem.am.rawValue)
            return component
        }

        // Numeric time: hour, optional two-digit minutes, optional meridiem letter.
        guard let innerRegex = try? NSRegularExpression(pattern: "^(\\d{1,2})(?:[:.](\\d{2}))?\\s*([ap])?"),
              let inner = innerRegex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) else {
            return nil
        }

        let nsText = text as NSString
        func group(_ i: Int) -> String? {
            let r = inner.range(at: i)
            return r.location == NSNotFound ? nil : nsText.substring(with: r)
        }

        guard let hourStr = group(1), let hour = Int(hourStr) else { return nil }

        var minute: Int? = nil
        if let minuteStr = group(2), let m = Int(minuteStr) {
            guard m <= 59 else { return nil }
            minute = m
        }

        if let meridiemStr = group(3) {
            // Meridiem present: 12-hour clock, hour must be 1-12.
            guard (1...12).contains(hour) else { return nil }
            if meridiemStr == "a" {
                component.assign(.meridiem, value: Meridiem.am.rawValue)
                component.assign(.hour, value: hour == 12 ? 0 : hour)
            } else {
                component.assign(.meridiem, value: Meridiem.pm.rawValue)
                component.assign(.hour, value: hour == 12 ? 12 : hour + 12)
            }
        } else {
            // No meridiem: 24-hour clock, reject out-of-range instead of overflowing.
            guard (0...23).contains(hour) else { return nil }
            component.assign(.hour, value: hour)
            component.imply(.meridiem, value: hour < 12 ? Meridiem.am.rawValue : Meridiem.pm.rawValue)
        }

        if let minute {
            component.assign(.minute, value: minute)
        } else {
            component.imply(.minute, value: 0)
        }

        component.imply(.second, value: 0)
        component.addTag("ENTimeExpressionParser")
        return component
    }
}
