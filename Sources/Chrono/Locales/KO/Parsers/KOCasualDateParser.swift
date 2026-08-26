// KOCasualDateParser.swift - 오늘 / 내일 / 모레 / 어제 and the rough times of day.
import Foundation

/// Korean casual day words (오늘, 내일, 모레, 글피, 어제, 그제) and rough times of day
/// (새벽, 아침, 점심, 저녁, 밤).
///
/// A day word names a calendar day and nothing else, so no hour is invented — 내일 says nothing
/// about when. A time-of-day word states an hour but not a day, so the day stays *implied* and the
/// merge refiner can attach it to a neighbouring date (내일 저녁 → tomorrow at 18:00).
///
/// Both yield to a following clock time: 저녁 7시 is one phrase meaning 19:00, and claiming 저녁 here
/// would leave a stray 7시 for another parser to pick up.
public struct KOCasualDateParser: Parser {
    public init() {}

    public func pattern(context: ParsingContext) -> String {
        let days = KOConstants.dayWords.map { $0.token }.joined(separator: "|")
        let periods = KOConstants.timeOfDayHours.keys.sorted { $0.count > $1.count }.joined(separator: "|")
        return "(?:(" + days + ")|(" + periods + ")" + KOConstants.notFollowedByClockTime + ")"
    }

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let components = context.createParsingComponents()

        if let word = match.string(at: 1),
           let entry = KOConstants.dayWords.first(where: { $0.token == word }) {
            guard components.assignKODay(offsetBy: entry.offset, from: context.refDate) else { return nil }
            components.addTag("KOCasualDateParser")
            return components
        }

        if let period = match.string(at: 2), let entry = KOConstants.timeOfDayHours[period] {
            // The day is only implied — this is a time, and 오후 alone means this afternoon.
            let calendar = Calendar.current
            let values = calendar.dateComponents([.year, .month, .day], from: context.refDate)
            if let year = values.year { components.imply(.year, value: year) }
            if let month = values.month { components.imply(.month, value: month) }
            if let day = values.day { components.imply(.day, value: day) }
            components.assign(.hour, value: entry.hour)
            components.assign(.minute, value: 0)
            components.assign(.meridiem, value: entry.meridiem.rawValue)
            components.addTag("KOCasualDateParser")
            return components
        }

        return nil
    }
}
