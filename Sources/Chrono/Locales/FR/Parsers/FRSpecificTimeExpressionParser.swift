// FRSpecificTimeExpressionParser.swift - Parser for specific French time expressions
import Foundation

/// Parser for specific French time expressions like "à 8h du matin", "7h du soir", "15h30", etc.
///
/// The time needs the French hour marker `h` or a colon with two-digit minutes, preceded either
/// by a whole-word connector (`à`, `a`, `vers`, `de`) or by whitespace/string start — so scores
/// like "3:2" and word tails like "comman[de] 3h" don't match (see spec `numeric-time-validation`).
public final class FRSpecificTimeExpressionParser: Parser {
    /// The pattern to match specific French time expressions
    public func pattern(context: ParsingContext) -> String {
        // Group 1: hour; group 2: minutes after "h"; group 3: minutes after ":"; group 4: period.
        return "(?:(?<!\\w)(?:à|a|vers|de)\\s+|(?<!\\S))" +
               "(\\d{1,2})(?:h(?:(\\d{1,2})(?:min|\\'|m)?)?|:(\\d{2}))(?!\\w)" +
               "(?:\\s*(?:du|dans|le|la|l'|au|en|à|a)\\s*(matin|matinée|matinee|après-midi|apres-midi|soir|soirée|soiree|nuit))?"
    }

    /// Extracts time components from a specific French time expression
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let component = context.createParsingComponents()

        // Get hour, minute, and period from match
        guard let hourText = match.string(at: 1), !hourText.isEmpty,
              let hour = Int(hourText) else {
            return nil
        }

        // A bare "Nh" (no connector, no minutes, no day period) is as likely a duration
        // ("3h de travail") as a clock time — leave it to the consumer's duration handling.
        // "à 3h", "15h30" and "8h du matin" all stay.
        let isBare = match.matchedText.first?.isNumber == true
        if isBare, match.string(at: 2) == nil, match.string(at: 3) == nil, match.string(at: 4) == nil {
            return nil
        }

        // Reject out-of-range values instead of letting the calendar overflow into later days.
        guard hour <= 23 else { return nil }

        // Parse minute (after "h" or after ":")
        let minute: Int
        if let minuteText = match.string(at: 2) ?? match.string(at: 3), !minuteText.isEmpty,
           let parsedMinute = Int(minuteText) {
            guard parsedMinute <= 59 else { return nil }
            minute = parsedMinute
        } else {
            minute = 0
        }

        // Determine meridiem based on time period
        let period = match.string(at: 4)?.foldedForMatching()

        var meridiem = hour >= 12 ? Meridiem.pm : Meridiem.am
        var adjustedHour = hour

        if let period = period {
            switch period {
            case "matin", "matinee":
                // Morning
                meridiem = .am
                if hour == 12 {
                    adjustedHour = 0
                }
            case "apres-midi":
                // Afternoon
                meridiem = .pm
                if hour < 12 {
                    adjustedHour = hour + 12
                }
            case "soir", "soiree", "nuit":
                // Evening/night
                meridiem = .pm
                if hour < 12 {
                    adjustedHour = hour + 12
                }
            default:
                break
            }
        }

        component.assign(.hour, value: adjustedHour)
        component.assign(.minute, value: minute)
        component.assign(.second, value: 0)
        component.assign(.meridiem, value: meridiem.rawValue)

        component.addTag("FRSpecificTimeExpressionParser")
        return component
    }
}
