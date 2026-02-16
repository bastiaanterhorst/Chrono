// JAISOWeekNumberParser.swift - Parser for ISO week numbers in Japanese text
import Foundation

/// Parser for ISO 8601 week numbers in Japanese text
final class JAISOWeekNumberParser: AbstractParserWithWordBoundaryChecking, @unchecked Sendable {
    override func innerPattern(context: ParsingContext) -> String {
        let japaneseWeekPattern = "(?:\\b\\d{4}年\\s*第?\\d{1,2}週\\b|\\b第?\\d{1,2}週(?:\\s*の?\\s*\\d{4}年?)?\\b)"
        let isoYearWeekPattern = "(?i)(?:\\b\\d{4}-?w\\d{1,2}\\b)"
        let isoWeekYearPattern = "(?i)(?:\\bw\\d{1,2}(?:[-/](?:'\\d{2}|\\d{2}|\\d{4}))?\\b)"
        return [japaneseWeekPattern, isoYearWeekPattern, isoWeekYearPattern].joined(separator: "|")
    }

    override func innerExtract(context: ParsingContext, match: TextMatch) -> Any? {
        let matchedText = match.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let weekNumber = extractWeekNumber(from: matchedText), weekNumber >= 1 && weekNumber <= 53 else {
            return nil
        }

        let explicitWeekYear = extractWeekYear(from: matchedText)
        let calendar = Calendar(identifier: .iso8601)
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
        result.addTag("JAISOWeekParser")
        return result
    }

    private func extractWeekNumber(from text: String) -> Int? {
        if let groups = captureGroups(pattern: "(?i)^(\\d{4})-?w(\\d{1,2})$", text: text),
           groups.count >= 3, let week = Int(groups[2]) {
            return week
        }

        if let groups = captureGroups(pattern: "(?i)^w(\\d{1,2})(?:[-/](?:'\\d{2}|\\d{2}|\\d{4}))?$", text: text),
           groups.count >= 2, let week = Int(groups[1]) {
            return week
        }

        if let groups = captureGroups(pattern: "^(\\d{4})年\\s*第?(\\d{1,2})週$", text: text),
           groups.count >= 3, let week = Int(groups[2]) {
            return week
        }

        if let groups = captureGroups(pattern: "^第?(\\d{1,2})週(?:\\s*の?\\s*(\\d{4})年?)?$", text: text),
           groups.count >= 2, let week = Int(groups[1]) {
            return week
        }

        let allNumbers = extractAllNumbers(from: text)
        if text.contains("週") || text.lowercased().contains("w") {
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

        if let groups = captureGroups(pattern: "^(\\d{4})年\\s*第?\\d{1,2}週$", text: text),
           groups.count >= 2, let year = Int(groups[1]) {
            return year
        }

        if let groups = captureGroups(pattern: "^第?\\d{1,2}週(?:\\s*の?\\s*(\\d{4})年?)$", text: text),
           groups.count >= 2, let year = Int(groups[1]) {
            return year
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
