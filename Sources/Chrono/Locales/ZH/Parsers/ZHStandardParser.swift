// ZHStandardParser.swift - Parser for full Chinese calendar dates like "2026年3月15日"
import Foundation

/// Parser for full Chinese dates: `2026年3月15日`, `3月15日`, `3月15号`, `二〇二六年三月十五日`,
/// `２０２６年３月１５日`.
///
/// Every number in a Chinese date may be written in ASCII digits, full-width digits (what a Chinese
/// IME emits by default) or Chinese numerals, so the pattern is built from `ZHConstants.NUMBER`
/// throughout and every reading is delegated to `ZHConstants`. The year is the one field that needs
/// its own reader: Chinese normally writes a year as a *digit sequence* (`二〇二六` = "two zero two
/// six" = 2026) rather than as a cardinal, which is what `ZHConstants.parseYear` handles.
///
/// No token in this pattern can fire inside an ordinary word, because none of them is ever matched
/// alone: 日 only counts when it closes a `…月…` pair, so 日本 and 生日 are untouched, and 号 only
/// counts in that same position, so `3号线` ("metro line 3") never becomes a date.
public struct ZHStandardParser: Parser {
    public init() {}

    /// Capture groups: 1 = year (optional), 2 = month, 3 = day.
    public func pattern(context: ParsingContext) -> String {
        let year = "(?:(\(ZHConstants.NUMBER))年\\s*)?"
        let month = "(\(ZHConstants.NUMBER))月\\s*"
        let day = "(\(ZHConstants.NUMBER))(?:日|号|號)"
        return year + month + day
    }

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let monthText = match.string(at: 2),
              let month = ZHConstants.parseNumber(monthText),
              (1...12).contains(month) else {
            return nil
        }

        guard let dayText = match.string(at: 3),
              let day = ZHConstants.parseNumber(dayText),
              (1...31).contains(day) else {
            return nil
        }

        let components = context.createParsingComponents()
        components.assign(.month, value: month)
        components.assign(.day, value: day)

        if let yearText = match.string(at: 1) {
            // The group participated, so its text is part of the matched range. A year we cannot
            // read is a reason to reject the whole match rather than to silently report a date
            // whose stated year was dropped.
            guard let statedYear = ZHConstants.parseYear(yearText) else { return nil }
            let year = ZHConstants.normalizeYear(statedYear)
            guard (1...9999).contains(year) else { return nil }
            components.assign(.year, value: year)
        } else {
            components.imply(.year, value: inferYear(context: context, month: month, day: day))
        }

        components.addTag("ZHStandardParser")
        return components
    }

    /// Picks the year for a date written without one: the reference year, rolled forward to the
    /// next one when the month/day has already passed and the caller asked for forward dates.
    private func inferYear(context: ParsingContext, month: Int, day: Int) -> Int {
        let calendar = Calendar.current
        let referenceYear = calendar.component(.year, from: context.refDate)
        let referenceMonth = calendar.component(.month, from: context.refDate)
        let referenceDay = calendar.component(.day, from: context.refDate)

        guard context.options.forwardDate else { return referenceYear }

        let hasPassed = month < referenceMonth || (month == referenceMonth && day < referenceDay)
        return hasPassed ? referenceYear + 1 : referenceYear
    }
}
