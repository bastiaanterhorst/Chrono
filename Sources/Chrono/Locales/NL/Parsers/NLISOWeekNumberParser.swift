// NLISOWeekNumberParser.swift - Parser for ISO week numbers in Dutch text
import Foundation

/// Parser for ISO 8601 week numbers in Dutch text
final class NLISOWeekNumberParser: AbstractParserWithWordBoundaryChecking, @unchecked Sendable {
    override func innerPattern(context: ParsingContext) -> String {
        let weekPattern = "(?i)(?:\\b(?:week(?:nummer)?|wk)\\b\\s*(?:nr\\.?\\s*)?(?:#\\s*)?\\d{1,2}(?:e|ste|de)?(?:\\s*(?:van|,|in)?\\s*(?:'\\d{2}|\\d{2}|\\d{4}))?)"
        let ordinalWeekPattern = "(?i)(?:\\bde\\s+\\d{1,2}(?:e|ste)\\s+week(?:\\s+van\\s+(?:'\\d{2}|\\d{2}|\\d{4}))?)"
        let isoYearWeekPattern = "(?i)(?:\\b\\d{4}-?w\\d{1,2}\\b)"
        let isoWeekYearPattern = "(?i)(?:\\bw\\d{1,2}(?:[-/](?:'\\d{2}|\\d{2}|\\d{4}))?\\b)"

        return [weekPattern, ordinalWeekPattern, isoYearWeekPattern, isoWeekYearPattern].joined(separator: "|")
    }

    override func innerExtract(context: ParsingContext, match: TextMatch) -> Any? {
        let matchedText = match.text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let weekNumber = extractWeekNumber(from: matchedText) else {
            return nil
        }

        guard weekNumber >= 1 && weekNumber <= 53 else {
            return nil
        }

        var weekYear = extractWeekYear(from: matchedText)
        let calendar = Calendar(identifier: .iso8601)

        if weekYear == nil {
            weekYear = calendar.component(.yearForWeekOfYear, from: context.reference.instant)
        }

        guard let resolvedWeekYear = weekYear else {
            return nil
        }

        let components = ParsingComponents(reference: context.reference)
        components.assign(.isoWeek, value: weekNumber)

        if extractWeekYear(from: matchedText) != nil {
            components.assign(.isoWeekYear, value: resolvedWeekYear)
        } else {
            components.imply(.isoWeekYear, value: resolvedWeekYear)
        }

        components.assignNull(.hour)

        var dateComponents = DateComponents()
        dateComponents.weekOfYear = weekNumber
        dateComponents.yearForWeekOfYear = resolvedWeekYear
        dateComponents.weekday = 2
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

        let result = context.createParsingResult(index: match.index, text: match.text, start: components)
        result.addTag("NLISOWeekParser")
        return result
    }

    private func extractWeekNumber(from text: String) -> Int? {
        if let groups = captureGroups(pattern: "(?i)^(\\d{4})-?w(\\d{1,2})$", text: text),
           groups.count >= 3,
           let week = Int(groups[2]) {
            return week
        }

        if let groups = captureGroups(pattern: "(?i)^w(\\d{1,2})(?:[-/](?:'\\d{2}|\\d{2}|\\d{4}))?$", text: text),
           groups.count >= 2,
           let week = Int(groups[1]) {
            return week
        }

        if let groups = captureGroups(
            pattern: "(?i)^(?:week(?:nummer)?|wk)\\s*(?:nr\\.?\\s*)?(?:#\\s*)?(\\d{1,2})(?:e|ste|de)?(?:\\s*(?:van|,|in)?\\s*(?:'\\d{2}|\\d{2}|\\d{4}))?$",
            text: text
        ), groups.count >= 2, let week = Int(groups[1]) {
            return week
        }

        if let groups = captureGroups(
            pattern: "(?i)^de\\s+(\\d{1,2})(?:e|ste)\\s+week(?:\\s+van\\s+(?:'\\d{2}|\\d{2}|\\d{4}))?$",
            text: text
        ), groups.count >= 2, let week = Int(groups[1]) {
            return week
        }

        let allNumbers = extractAllNumbers(from: text)
        if text.lowercased().contains("week") || text.lowercased().contains("wk") || text.lowercased().contains("w") {
            return allNumbers.first(where: { $0 >= 1 && $0 <= 53 })
        }

        return nil
    }

    private func extractWeekYear(from text: String) -> Int? {
        if let groups = captureGroups(pattern: "(?i)^(\\d{4})-?w(\\d{1,2})$", text: text),
           groups.count >= 2,
           let year = Int(groups[1]) {
            return year
        }

        if let groups = captureGroups(pattern: "(?i)^w\\d{1,2}[-/](\\d{4}|'\\d{2}|\\d{2})$", text: text),
           groups.count >= 2 {
            return expandYear(groups[1])
        }

        if let groups = captureGroups(
            pattern: "(?i)^(?:week(?:nummer)?|wk)\\s*(?:nr\\.?\\s*)?(?:#\\s*)?\\d{1,2}(?:e|ste|de)?(?:\\s*(?:van|,|in)?\\s*('(?:\\d{2})|\\d{2}|\\d{4}))$",
            text: text
        ), groups.count >= 2 {
            return expandYear(groups[1])
        }

        if let groups = captureGroups(
            pattern: "(?i)^de\\s+\\d{1,2}(?:e|ste)\\s+week(?:\\s+van\\s+('(?:\\d{2})|\\d{2}|\\d{4}))$",
            text: text
        ), groups.count >= 2 {
            return expandYear(groups[1])
        }

        let allNumbers = extractAllNumbers(from: text)
        for number in allNumbers where number > 53 {
            if number >= 1000 {
                return number
            }

            if number <= 99 {
                return expandYear(String(number))
            }
        }

        return nil
    }

    private func expandYear(_ rawYear: String) -> Int? {
        let cleaned = rawYear.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.hasPrefix("'"), let value = Int(cleaned.dropFirst()) {
            return 2000 + value
        }

        guard let value = Int(cleaned) else {
            return nil
        }

        if cleaned.count == 4 {
            return value
        }

        if value < 50 {
            return 2000 + value
        }

        return 1900 + value
    }

    private func captureGroups(pattern: String, text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)

        guard let match = regex.firstMatch(in: text, options: [], range: range),
              match.range.location == 0,
              match.range.length == nsText.length else {
            return nil
        }

        var groups: [String] = []
        for index in 0..<match.numberOfRanges {
            let captureRange = match.range(at: index)
            if captureRange.location == NSNotFound {
                groups.append("")
            } else {
                groups.append(nsText.substring(with: captureRange))
            }
        }

        return groups
    }

    private func extractAllNumbers(from text: String) -> [Int] {
        guard let regex = try? NSRegularExpression(pattern: "\\d+", options: []) else {
            return []
        }

        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        return regex.matches(in: text, options: [], range: range).compactMap { match in
            let numberText = nsText.substring(with: match.range)
            return Int(numberText)
        }
    }
}
