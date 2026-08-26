// ZHISOWeekNumberParser.swift - Parser for ISO week numbers in Chinese text
import Foundation

/// Parser for ISO 8601 week numbers in Chinese text — `第10周`, `第10個星期`, `2026年第10周` — plus
/// the script-neutral ASCII forms every locale accepts (`2026-W10`, `W10`, `W10/26`).
///
/// Linguistic notes:
///
/// - **The ordinal marker 第 (or an explicit year) is mandatory.** A bare `10周` means "ten weeks"
///   and is already claimed as a duration by `ZHRelativeWeekParser` (`10周后` / `10周前`); accepting
///   it here would turn every duration into a week number. `第10周` is unambiguous.
/// - **`周年` is an anniversary, not a week**, and `第三个星期一` is "the third Monday" rather than
///   week three, so the Chinese alternatives end in a negative lookahead over 年 and the weekday
///   characters. That lookahead does the work `\b` does in Latin locales: ICU classifies Han
///   ideographs as `\w`, so a word boundary never fires between two of them. The ASCII alternatives
///   keep their `\b`, which is well defined there.
/// - Week numbers may be written in ASCII, full-width, or Chinese numerals (`第十周`), and years in
///   ASCII, full-width, or as a Chinese digit sequence (`二〇二六年`); `ZHConstants.parseNumber` and
///   `ZHConstants.parseYear` read all of those scripts.
final class ZHISOWeekNumberParser: AbstractParserWithWordBoundaryChecking, @unchecked Sendable {

    /// The optional measure word in 第10个星期 / 第10個星期.
    private static let measureWord = "(?:个|個)?"

    /// A four-figure year in ASCII, full-width, or Chinese digits (二〇二六年).
    private static let yearNumber = "(?:[0-9０-９]{4}|[〇零一二三四五六七八九]{4})"

    /// 年 would make it an anniversary (第10周年); a weekday character would make it an nth-weekday
    /// (第三个星期一). Neither is a week number.
    private static let weekTailGuard = "(?![一二三四五六日天年])"

    override func innerPattern(context: ParsingContext) -> String {
        let week = ZHConstants.NUMBER
        let measure = Self.measureWord
        let weekWord = ZHConstants.WEEK_WORD

        // 2026年第10周 / 2026年 第10週 / 二〇二六年第十个星期. With an explicit year the 第 may be
        // dropped, since the year already rules out the "N weeks" reading.
        let chineseYearWeek = "(?:\(Self.yearNumber)年\\s*第?\(week)\(measure)\(weekWord)\(Self.weekTailGuard))"

        // 第10周 / 第10週 / 第10个星期 / 第10個星期 — 第 required, see the type doc.
        let chineseOrdinalWeek = "(?:第\(week)\(measure)\(weekWord)\(Self.weekTailGuard))"

        // The ASCII forms, identical to every other locale's.
        let isoYearWeekPattern = "(?i)(?:\\b\\d{4}-?w\\d{1,2}\\b)"
        let isoWeekYearPattern = "(?i)(?:\\bw\\d{1,2}(?:[-/](?:\\d{4}|'\\d{2}|\\d{2}))?\\b)"

        return [chineseYearWeek, chineseOrdinalWeek, isoYearWeekPattern, isoWeekYearPattern]
            .joined(separator: "|")
    }

    override func innerExtract(context: ParsingContext, match: TextMatch) -> Any? {
        // Use the matched substring (not the whole input) so the ^…$ extraction anchors correctly
        // and the result span doesn't swallow trailing text.
        let matchedText = (match.string(at: 0) ?? match.text).trimmingCharacters(in: .whitespacesAndNewlines)
        let matchIndex = match.startIndex(at: 0) ?? match.index
        guard let weekNumber = extractWeekNumber(from: matchedText), weekNumber >= 1 && weekNumber <= 53 else {
            return nil
        }

        let explicitWeekYear = extractWeekYear(from: matchedText)
        // Weeks are counted by this parse's convention, so the number the user typed is
        // the number that comes back out.
        let calendar = context.weekCalendar
        let resolvedWeekYear = explicitWeekYear ?? calendar.component(.yearForWeekOfYear, from: context.reference.instant)

        let components = ParsingComponents(reference: context.reference)
        components.assign(.isoWeek, value: weekNumber)
        if let explicitWeekYear {
            components.assign(.isoWeekYear, value: explicitWeekYear)
        } else {
            components.imply(.isoWeekYear, value: resolvedWeekYear)
        }
        components.assignNull(.hour)

        var dateComponents = DateComponents()
        dateComponents.weekOfYear = weekNumber
        dateComponents.yearForWeekOfYear = resolvedWeekYear
        dateComponents.weekday = calendar.firstWeekday
        dateComponents.hour = 12
        dateComponents.minute = 0
        dateComponents.second = 0

        if let weekStart = calendar.date(from: dateComponents) {
            let dayComponents = calendar.dateComponents([.year, .month, .day], from: weekStart)
            if let year = dayComponents.year, let month = dayComponents.month, let day = dayComponents.day {
                components.assign(.year, value: year)
                components.assign(.month, value: month)
                components.assign(.day, value: day)
            }
        }

        let result = context.createParsingResult(index: matchIndex, text: matchedText, start: components)
        result.addTag("ZHISOWeekParser")
        return result
    }

    private func extractWeekNumber(from text: String) -> Int? {
        if let groups = captureGroups(pattern: "(?i)^(\\d{4})-?w(\\d{1,2})$", text: text),
           groups.count >= 3, let week = Int(groups[2]) {
            return week
        }

        if let groups = captureGroups(pattern: "(?i)^w(\\d{1,2})(?:[-/](?:\\d{4}|'\\d{2}|\\d{2}))?$", text: text),
           groups.count >= 2, let week = Int(groups[1]) {
            return week
        }

        if let groups = captureGroups(
            pattern: "^\(Self.yearNumber)年\\s*第?(\(ZHConstants.NUMBER))\(Self.measureWord)\(ZHConstants.WEEK_WORD)$",
            text: text
        ), groups.count >= 2, let week = ZHConstants.parseNumber(groups[1]) {
            return week
        }

        if let groups = captureGroups(
            pattern: "^第(\(ZHConstants.NUMBER))\(Self.measureWord)\(ZHConstants.WEEK_WORD)$",
            text: text
        ), groups.count >= 2, let week = ZHConstants.parseNumber(groups[1]) {
            return week
        }

        let allNumbers = extractAllNumbers(from: text)
        if text.contains("周") || text.contains("週") || text.contains("星期") || text.contains("礼拜")
            || text.contains("禮拜") || text.lowercased().contains("w") {
            return allNumbers.first(where: { $0 >= 1 && $0 <= 53 })
        }

        return nil
    }

    private func extractWeekYear(from text: String) -> Int? {
        if let groups = captureGroups(pattern: "(?i)^(\\d{4})-?w\\d{1,2}$", text: text),
           groups.count >= 2, let year = Int(groups[1]) {
            return year
        }

        if let groups = captureGroups(pattern: "(?i)^w\\d{1,2}[-/](\\d{4}|'\\d{2}|\\d{2})$", text: text),
           groups.count >= 2 {
            return expandYear(groups[1])
        }

        if let groups = captureGroups(
            pattern: "^(\(Self.yearNumber))年\\s*第?\(ZHConstants.NUMBER)\(Self.measureWord)\(ZHConstants.WEEK_WORD)$",
            text: text
        ), groups.count >= 2, let year = ZHConstants.parseYear(groups[1]) {
            return ZHConstants.normalizeYear(year)
        }

        let allNumbers = extractAllNumbers(from: text)
        for number in allNumbers where number > 53 {
            if number >= 1000 { return number }
            if number <= 99 { return expandYear(String(number)) }
        }
        return nil
    }

    private func expandYear(_ rawYear: String) -> Int? {
        let cleaned = rawYear.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("'"), let value = Int(cleaned.dropFirst()) {
            return 2000 + value
        }
        guard let value = Int(cleaned) else { return nil }
        if cleaned.count == 4 { return value }
        return value < 50 ? 2000 + value : 1900 + value
    }

    private func captureGroups(pattern: String, text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              match.range.location == 0, match.range.length == nsText.length else {
            return nil
        }
        var groups: [String] = []
        for index in 0..<match.numberOfRanges {
            let captureRange = match.range(at: index)
            groups.append(captureRange.location == NSNotFound ? "" : nsText.substring(with: captureRange))
        }
        return groups
    }

    private func extractAllNumbers(from text: String) -> [Int] {
        guard let regex = try? NSRegularExpression(pattern: "\\d+") else { return [] }
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        return regex.matches(in: text, options: [], range: range).compactMap { Int(nsText.substring(with: $0.range)) }
    }
}
