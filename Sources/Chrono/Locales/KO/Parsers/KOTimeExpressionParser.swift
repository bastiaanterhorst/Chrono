// KOTimeExpressionParser.swift - 오전 9시 / 오후 3시 30분 / 9시 / 15:30.
import Foundation

/// Korean clock times: 9시, 9시 30분, and the same qualified by a day period — 오전 (am), 오후 (pm),
/// 아침, 점심, 저녁, 밤, 새벽 — plus the colon form 15:30.
///
/// 시 is what marks an hour, so a bare number is never a time here and "3장" or "2개" cannot become
/// one. A stated day period fixes the meridiem, which is how Korean says what English says with
/// am/pm and what makes the time one the user really specified.
public struct KOTimeExpressionParser: Parser {
    public init() {}

    public func pattern(context: ParsingContext) -> String {
        let s = KOConstants.optionalSpace
        let periods = KOConstants.timeOfDayHours.keys.sorted { $0.count > $1.count }
            .joined(separator: "|")
        // 1: period, 2: hour, 3: minute  |  4: hour, 5: minute (colon form)
        let sino = "(?:(" + periods + ")" + s + ")?(\\d{1,2})시(?:" + s + "(\\d{1,2})분)?"
        let colon = "(?<![0-9:])(\\d{1,2}):(\\d{2})(?![0-9:])"
        return "(?:" + sino + "|" + colon + ")"
    }

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let components = context.createParsingComponents()

        if let hourStr = match.string(at: 2), var hour = Int(hourStr) {
            guard (0...24).contains(hour) else { return nil }
            var meridiem: Meridiem?

            if let period = match.string(at: 1), let entry = KOConstants.timeOfDayHours[period] {
                meridiem = entry.meridiem
                guard (1...12).contains(hour) else { return nil }
                if entry.meridiem == .pm { hour = hour == 12 ? 12 : hour + 12 }
                else { hour = hour == 12 ? 0 : hour }
            }

            components.assign(.hour, value: hour == 24 ? 0 : hour)
            if let minuteStr = match.string(at: 3), let minute = Int(minuteStr) {
                guard (0...59).contains(minute) else { return nil }
                components.assign(.minute, value: minute)
            } else {
                // 시 marks an hour outright, the way "Uhr" does in German, so 9시 is a time the user
                // stated — not a stray number that happens to sit next to a word. Assigning the
                // minute is what says so; leaving it merely implied would let 9시 be discarded as
                // an ambiguous bare hour, which is the whole reason "at 9" is ignored in English.
                components.assign(.minute, value: 0)
            }
            if let meridiem {
                components.assign(.meridiem, value: meridiem.rawValue)
            } else {
                components.imply(.meridiem, value: hour < 12 ? Meridiem.am.rawValue : Meridiem.pm.rawValue)
            }
            components.imply(.second, value: 0)
            components.addTag("KOTimeExpressionParser")
            return components
        }

        if let hourStr = match.string(at: 4), let hour = Int(hourStr),
           let minuteStr = match.string(at: 5), let minute = Int(minuteStr) {
            guard (0...23).contains(hour), (0...59).contains(minute) else { return nil }
            components.assign(.hour, value: hour)
            components.assign(.minute, value: minute)
            components.imply(.meridiem, value: hour < 12 ? Meridiem.am.rawValue : Meridiem.pm.rawValue)
            components.imply(.second, value: 0)
            components.addTag("KOTimeExpressionParser")
            return components
        }

        return nil
    }
}
