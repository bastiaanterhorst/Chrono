// DETimeExpressionParser.swift - Parser for time expressions in German
import Foundation

/// Parser for time expressions in German like "um 5 Uhr", "8 Uhr", "um 15.30", etc.
///
/// Two forms are accepted (see openspec spec `numeric-time-validation`):
/// - Connector form: `um`/`von`/`nach`/`vor` (whole word) followed by a time, which may be a bare
///   hour ("um 3"). Dot minutes are allowed ("um 15.30" — the German time separator).
/// - Bare form: the hour needs the explicit `Uhr`/`h` marker ("8 Uhr", "15.30 Uhr") and must
///   follow whitespace or string start. Unqualified bare numbers ("kaufe 2 Äpfel") and comma
///   decimals ("2,50 Euro") never match.
public struct DETimeExpressionParser: Parser {
    public init() {}

    public func pattern(context: ParsingContext) -> String {
        // Group 1: connector; 2: hour, 3: dot-minutes, 4: suffix-minutes (connector form);
        // 5: hour, 6: dot-minutes, 7: suffix-minutes (bare form); 8: day-period words.
        return "(?:(?<!\\w)(um|von|nach|vor)\\s+" +
               "([0-9]{1,2})(?:\\.([0-5][0-9]))?(?:\\s*(?:[Uu]hr|h)(?!\\w))?" +
               "(?:\\s+([0-9]{1,2})\\s*(?:m(?:in(?:uten)?)?|Min)(?!\\w))?" +
               "|(?<!\\S)" +
               // Bare form needs two-digit dot minutes ("14.30" — kept as a time when it can't be
               // a date) or the Uhr/h marker; "2.0" / "2,50" have no two-digit minutes and fail.
               "([0-9]{1,2})(?:\\.([0-5][0-9])(?:\\s*(?:[Uu]hr|h)(?!\\w))?|\\s*(?:[Uu]hr|h)(?!\\w))" +
               "(?:\\s+([0-9]{1,2})\\s*(?:m(?:in(?:uten)?)?|Min)(?!\\w))?)" +
               "(?:\\s*(morgens?|vormittags?|mittags?|nachmittags?|abends?|nachts?))?" +
               "(?=\\W|$)"
    }

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let result = ParsingComponents(reference: context.reference)

        // Hour (connector form or bare form)
        guard let hourStr = match.string(at: 2) ?? match.string(at: 5), let hour = Int(hourStr) else {
            return nil
        }

        // 0-24 with 24 = midnight ("um 24 Uhr"); anything above rejects instead of overflowing.
        guard hour <= 24 else { return nil }

        // Process hour with meridiem
        var meridiem: Meridiem?
        if let meridiemStr = match.string(at: 8)?.lowercased() {
            if meridiemStr.contains("nachmittag") || meridiemStr.contains("abend") || meridiemStr.contains("nacht") {
                meridiem = .pm
            } else if meridiemStr.contains("morgen") || meridiemStr.contains("vormittag") {
                meridiem = .am
            }
        }

        let adjustedHour: Int
        if meridiem == .pm && hour < 12 {
            adjustedHour = hour + 12
        } else if meridiem == .am && hour == 12 {
            adjustedHour = 0
        } else {
            adjustedHour = hour
        }

        result.assign(.hour, value: adjustedHour)

        // Minutes (dot or explicit "min" suffix, either form)
        if let minuteStr = match.string(at: 3) ?? match.string(at: 4) ?? match.string(at: 6) ?? match.string(at: 7),
           let minute = Int(minuteStr) {
            guard minute <= 59 else { return nil }
            result.assign(.minute, value: minute)
        } else {
            result.assign(.minute, value: 0)
        }

        result.assign(.second, value: 0)

        return result
    }
}
