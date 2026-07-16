// NLTimeExpressionParser.swift - Parser for time expressions in Dutch
import Foundation

/// Parser for standard time expressions in Dutch
///
/// Two forms are accepted (see openspec spec `numeric-time-validation`):
/// - Connector form: `om`/`tegen`/`rond`/`vanaf` (whole word) followed by a time, which may be a
///   bare hour ("om 3") or the `uur` form ("om 2 uur"). `voor` is deliberately NOT a connector —
///   it means both "before" and "for", and "voor 2 uur" is as likely a 2-hour duration.
/// - Bare form: a time qualified by colon minutes ("15:00"), dot minutes plus `uur`
///   ("15.30 uur"), or an am/pm meridiem ("3pm"), preceded by whitespace or string start.
///   A bare "2 uur" is a duration, not a clock time, and no longer matches; lone-letter
///   meridiems ("3 a 4 appels") no longer match either.
final class NLTimeExpressionParser: Parser {
    func pattern(context: ParsingContext) -> String {
        // Connector form: G1 hour, G2 minutes, G3 meridiem letter.
        // Bare form:      G4 hour, G5 minutes, G6 meridiem letter (colon time)
        //                 G7 hour, G8 minutes (dot minutes + uur)
        //                 G9 hour, G10 meridiem letter (meridiem time)
        return "(?:" +
            "(?<!\\w)(?:om|tegen|rond|vanaf)(?:\\s+ongeveer)?\\s+" +
            "(\\d{1,2})(?:[:.](\\d{2}))?(?:\\s*uur)?(?:\\s*([ap])\\.?m\\.?)?" +
        "|" +
            "(?<!\\S)" +
            "(?:" +
                "(\\d{1,2}):(\\d{2})(?:\\s*uur)?(?:\\s*([ap])\\.?m\\.?)?" +
            "|" +
                "(\\d{1,2})\\.(\\d{2})\\s*uur" +
            "|" +
                "(\\d{1,2})\\s*([ap])\\.?m\\.?" +
            ")" +
        ")" +
        "(?=\\W|$)"
    }

    func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let hourStr = match.string(at: 1) ?? match.string(at: 4) ?? match.string(at: 7) ?? match.string(at: 9),
              var hour = Int(hourStr) else {
            return nil
        }

        let minuteStr = match.string(at: 2) ?? match.string(at: 5) ?? match.string(at: 8)
        let meridiemStr = (match.string(at: 3) ?? match.string(at: 6) ?? match.string(at: 10))?.lowercased()

        var minute: Int? = nil
        if let minuteStr, let m = Int(minuteStr) {
            guard m <= 59 else { return nil }
            minute = m
        }

        let component = context.createParsingComponents()

        if let meridiemStr {
            // Meridiem present: 12-hour clock, hour must be 1-12.
            guard (1...12).contains(hour) else { return nil }
            if meridiemStr == "a" {
                component.assign(.meridiem, value: Meridiem.am.rawValue)
                if hour == 12 { hour = 0 }
            } else {
                component.assign(.meridiem, value: Meridiem.pm.rawValue)
                if hour != 12 { hour += 12 }
            }
            component.assign(.hour, value: hour)
        } else {
            // 0-24 with 24 = midnight ("om 24 uur"); anything above rejects instead of overflowing.
            guard hour <= 24 else { return nil }
            component.assign(.hour, value: hour)
            component.imply(.meridiem, value: hour < 12 ? Meridiem.am.rawValue : Meridiem.pm.rawValue)
        }

        // Minutes are known when written or when the "uur" marker states a whole hour
        // ("om 2 uur" = 2:00 exactly); a connected bare hour ("om 3") stays an ambiguous
        // fragment with implied minutes, like EN "at 3".
        let hasUurMarker = match.matchedText.lowercased().contains("uur")
        if let minute {
            component.assign(.minute, value: minute)
        } else if hasUurMarker {
            component.assign(.minute, value: 0)
        } else {
            component.imply(.minute, value: 0)
        }

        component.imply(.second, value: 0)
        component.addTag("NLTimeExpressionParser")
        return component
    }
}
