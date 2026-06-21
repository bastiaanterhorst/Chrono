import Foundation

/// Little-endian day–month(-year) date parser, shared across locales. Range-free and consistent:
///
///     <day>[ordinal]   [connector]   <month>   [ 4-digit year ]
///
/// e.g. "2 July", "2nd of July", "2 juli", "2. Juli", "2 de julio", "2 juillet", "15 July 2027".
/// The day comes first; an optional connector ("of"/"de") may precede the month; an optional
/// 4-digit year may follow. Parameterized by the locale's month dictionary so every language parses
/// the form identically (the previous per-locale parsers were variously broken: dropping the day,
/// concatenating range digits, or grabbing two digits of the year as the day).
struct MonthNameDayParser: Parser {
    let months: [String: Int]
    /// Optional words allowed between the day and the month, e.g. ["of"] (EN) or ["de"] (ES/PT).
    let connectors: [String]
    let tag: String

    init(months: [String: Int], connectors: [String] = [], tag: String) {
        self.months = months
        self.connectors = connectors
        self.tag = tag
    }

    func pattern(context: ParsingContext) -> String {
        let monthAlt = PatternUtils.matchAnyPattern(months) // returns a non-capturing (?:…) group
        let connectorAlt = connectors.isEmpty ? "" :
            "(?:" + connectors.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|") + ")\\s+"
        // (boundary) day (ordinal)? \s+ (connector)? (month) ( \s+ 4-digit-year )? (boundary)
        return "(?:\\W|^)([0-9]{1,2})(?:\\.|º|°|er|ère|ste|de|e|st|nd|rd|th)?\\s+(?:\(connectorAlt))?(\(monthAlt))(?:\\s+([0-9]{4}))?(?=\\W|$)"
    }

    func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let dayStr = match.string(at: 1), let day = Int(dayStr), (1...31).contains(day) else { return nil }
        guard let monthStr = match.string(at: 2)?.lowercased(), let month = months.matchValue(for: monthStr) else { return nil }

        let c = context.createParsingComponents()
        c.assign(.day, value: day)
        c.assign(.month, value: month)
        if let yearStr = match.string(at: 3), let year = Int(yearStr) {
            c.assign(.year, value: year)
        } else {
            c.imply(.year, value: Calendar.current.component(.year, from: context.reference.instant))
        }
        c.addTag(tag)
        return c
    }
}
