// PTTimeExpressionParser.swift - Parser for time expressions in Portuguese
import Foundation

/// Parser for Portuguese time expressions like "às 3", "15h30", "3h da tarde", etc.
///
/// Two forms are accepted (see openspec spec `numeric-time-validation`):
/// - Connector form: `às`/`as` (whole word) followed by a time, which may be a bare hour
///   ("às 3") or an h-marker form ("às 15h").
/// - Bare form: the time needs the h-marker with minutes ("15h30"), colon minutes ("15:30"),
///   or an h-marker plus a day period ("3h da tarde") — a bare "3h" alone is as likely a
///   duration, and unqualified bare numbers ("comprar 2 maçãs", "reunião 2024") never match.
public final class PTTimeExpressionParser: Parser {
    /// Returns the pattern for matching Portuguese time expressions
    public func pattern(context: ParsingContext) -> String {
        let period = "(?:\\s*(da|pela|de|do|na|no)\\s+(manh[ãa]|tarde|noite))?"
        // Group 1: connector-form time; group 2: bare-form time; groups 3-4: day period.
        return "(?:(?<!\\w)[àa]s\\s+" +
               "(\\d{1,2}(?:(?:h|:)\\d{2}(?:min)?|h)?)" +
               "|(?<!\\S)" +
               "(\\d{1,2}(?:h|:)\\d{2}(?:min)?|\\d{1,2}h(?=\\s*(?:da|pela|de|do|na|no)\\s+(?:manh[ãa]|tarde|noite)))" +
               ")" + period + "(?=\\W|$)"
    }

    /// Extracts time components from a matched time expression
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let timeText = match.string(at: 1) ?? match.string(at: 2) else { return nil }

        let component = context.createParsingComponents()

        // Hour, optional separator (h/:), optional two-digit minutes.
        guard let innerRegex = try? NSRegularExpression(pattern: "^(\\d{1,2})(?:(h|:)(\\d{2}))?"),
              let inner = innerRegex.firstMatch(in: timeText, options: [], range: NSRange(location: 0, length: timeText.utf16.count)) else {
            return nil
        }

        let nsText = timeText as NSString
        func group(_ i: Int) -> String? {
            let r = inner.range(at: i)
            return r.location == NSNotFound ? nil : nsText.substring(with: r)
        }

        guard let hourStr = group(1), let hour = Int(hourStr) else { return nil }

        // Reject out-of-range values instead of letting the calendar overflow into later days.
        guard hour <= 23 else { return nil }

        var minute: Int? = nil
        if let minuteStr = group(3), let m = Int(minuteStr) {
            guard m <= 59 else { return nil }
            minute = m
        }

        // Apply AM/PM meridiem from period mentions
        var meridiem: Int? = nil
        if let periodText = match.string(at: 4)?.foldedForMatching() {
            if periodText.contains("manha") {
                meridiem = Meridiem.am.rawValue
            } else if periodText.contains("tarde") || periodText.contains("noite") {
                meridiem = Meridiem.pm.rawValue
            }
        }

        // Handle the 12-hour clock
        if meridiem == Meridiem.am.rawValue && hour == 12 {
            component.assign(.hour, value: 0)
        } else if meridiem == Meridiem.pm.rawValue && hour < 12 {
            component.assign(.hour, value: hour + 12)
        } else {
            component.assign(.hour, value: hour)
        }

        // Minutes are known when written or when the h-marker states a whole hour ("às 15h");
        // a connected bare hour ("às 3") stays an ambiguous fragment with implied minutes.
        let hasHourMarker = timeText.lowercased().contains("h")
        if let minute {
            component.assign(.minute, value: minute)
        } else if hasHourMarker {
            component.assign(.minute, value: 0)
        } else {
            component.imply(.minute, value: 0)
        }

        // If meridiem was assigned explicitly
        if let meridiem = meridiem {
            component.assign(.meridiem, value: meridiem)
        }
        // Otherwise infer based on hour
        else if hour < 12 {
            component.imply(.meridiem, value: Meridiem.am.rawValue)
        } else {
            component.imply(.meridiem, value: Meridiem.pm.rawValue)
        }

        component.addTag("PTTimeExpressionParser")
        return component
    }
}
