// ESTimeExpressionParser.swift - Parser for time expressions in Spanish
import Foundation

/// Parser for time expressions in Spanish (e.g., "a las 3:30 PM")
///
/// Two forms are accepted (see openspec spec `numeric-time-validation`):
/// - Connector form: an explicit time-connector (`a las`, `a la`, `al`, `las`) followed by a
///   time, which may be a bare hour ("a las 3"). The connector must start on a word boundary and
///   be separated from the time by whitespace, so "a las50" and word tails don't match.
/// - Bare form: a time qualified by minutes and/or a meridiem ("7pm", "15:30") preceded by
///   whitespace or string start. Unqualified bare numbers ("comprar 2 manzanas") never match.
///
/// Either form may carry a day period — "a las 9 de la mañana", "a las 9 de la noche" — which is
/// how Spanish says what English says with am/pm, and is the natural way to write a time here. It
/// must be part of *this* match: left to itself "mañana" is also the word for tomorrow, so
/// "a las 9 de la mañana" scheduled the next day instead of setting the morning.
public final class ESTimeExpressionParser: Parser {
    /// The pattern to match time expressions in Spanish
    public func pattern(context: ParsingContext) -> String {
        // Group 1: connector-form time (bare hour allowed)
        // Group 2: bare-form time (minutes and/or meridiem required)
        // Group 3: an optional day period ("de la mañana", "por la tarde") that fixes the meridiem
        return "(?:(?<!\\w)(?:a\\s+las?|al|las)\\s+" +
               "(mediod[ií]a|medianoche|\\d{1,2}(?:[:.]\\d{2})?(?:\\s*[ap]\\.?m\\.?|[ap])?)" +
               "|(?<!\\S)" +
               "(\\d{1,2}(?:[:.]\\d{2})?(?:\\s*[ap]\\.?m\\.?|[ap])|\\d{1,2}:\\d{2}))" +
               ESTimeExpressionParser.dayPeriodPattern +
               "(?=\\W|$)"
    }

    /// "de/por/en la mañana|tarde|noche|madrugada", accent-optional. Kept optional so a plain
    /// "a las 9" is unaffected.
    private static let dayPeriodPattern =
        "(?:\\s*(?:de|por|en)\\s+la\\s+(ma[ñn]ana|tarde|noche|madrugada))?"

    /// Extracts time components from a time expression
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let component = context.createParsingComponents()

        guard let text = (match.string(at: 1) ?? match.string(at: 2))?.lowercased() else { return nil }

        // Special cases: mediodía and medianoche (connector form only)
        if text == "mediodia" || text == "mediodía" {
            component.assign(.hour, value: 12)
            component.assign(.minute, value: 0)
            component.assign(.second, value: 0)
            component.assign(.meridiem, value: Meridiem.pm.rawValue)
            return component
        }

        if text == "medianoche" {
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

        // A stated day period wins over the 24-hour reading and, crucially, makes the meridiem
        // *certain* — which is what marks this as a time the user really specified.
        if let period = match.string(at: 3)?.lowercased() {
            let morning = period.hasPrefix("ma")   // mañana / manana / madrugada
            guard (1...12).contains(hour) else { return nil }
            if morning {
                component.assign(.meridiem, value: Meridiem.am.rawValue)
                component.assign(.hour, value: hour == 12 ? 0 : hour)
            } else {
                component.assign(.meridiem, value: Meridiem.pm.rawValue)
                component.assign(.hour, value: hour == 12 ? 12 : hour + 12)
            }
        }

        if let minute {
            component.assign(.minute, value: minute)
        } else {
            component.imply(.minute, value: 0)
        }

        component.imply(.second, value: 0)
        component.addTag("ESTimeExpressionParser")
        return component
    }
}
