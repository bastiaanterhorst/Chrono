// JARelativeWeekParser.swift - Parser for relative week expressions in Japanese
import Foundation

/// Parser for relative week expressions in Japanese text
final class JARelativeWeekParser: AbstractParserWithWordBoundaryChecking, @unchecked Sendable {
    override func innerPattern(context: ParsingContext) -> String {
        let patternThis = "(?:今週)"
        let patternLast = "(?:先週)"
        let patternNext = "(?:来週)"
        let patternWeeksAgo = "(?:(\\d+)週間前)"
        let patternInWeeks = "(?:(\\d+)週間後|あと(\\d+)週間)"
        let patternBeforeLast = "(?:先々週)"
        let patternAfterNext = "(?:再来週)"

        // Weekend variants must come BEFORE the bare-week patterns so "今週末" matches as a unit
        // rather than "今週" + stray "末". Bare "週末" alone means this weekend.
        let patternThisWeekend = "(?:今週末)"
        let patternNextWeekend = "(?:来週末)"
        let patternLastWeekend = "(?:先週末)"
        let patternBareWeekend = "(?:週末)"

        return [
            patternThisWeekend,
            patternNextWeekend,
            patternLastWeekend,
            patternBareWeekend,
            patternThis,
            patternLast,
            patternNext,
            patternWeeksAgo,
            patternInWeeks,
            patternBeforeLast,
            patternAfterNext
        ].joined(separator: "|")
    }

    override func innerExtract(context: ParsingContext, match: TextMatch) -> Any? {
        // Inspect only the matched substring so trailing text and other phrases don't leak in.
        let matched = match.string(at: 0) ?? match.text
        let text = matched
        let referenceDate = context.reference.instant
        let calendar = Calendar(identifier: .iso8601)
        let allNumbers = extractAllNumbers(from: text)
        var weekOffset = 0

        // Weekend → first weekend day (locale-aware) as a concrete DAY, not an ISO week. Runs before
        // the week checks because "今週末" contains "今週".
        if text.contains("週末") {
            let weekendOffset = text.contains("来") ? 1 : (text.contains("先") ? -1 : 0)
            if let components = WeekendResolver.weekendComponents(
                context: context, weekOffset: weekendOffset, localeIdentifier: "ja") {
                components.addTag("JARelativeWeekParser")
                return context.createParsingResult(
                    index: match.startIndex(at: 0) ?? match.index,
                    text: matched.trimmingCharacters(in: .whitespacesAndNewlines),
                    start: components)
            }
        }

        if text.contains("今週") {
            weekOffset = 0
        } else if text.contains("先々週") {
            weekOffset = -2
        } else if text.contains("再来週") {
            weekOffset = 2
        } else if text.contains("先週") {
            weekOffset = -1
        } else if text.contains("来週") {
            weekOffset = 1
        } else if text.contains("週間前") {
            if let weeksAgo = extractCapturedNumber(match: match) ?? allNumbers.first {
                weekOffset = -weeksAgo
            }
        } else if text.contains("週間後") || text.contains("あと") {
            if let weeksLater = extractCapturedNumber(match: match) ?? allNumbers.first {
                weekOffset = weeksLater
            }
        }

        guard let targetDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: referenceDate) else {
            return nil
        }

        let targetWeek = calendar.component(.weekOfYear, from: targetDate)
        let targetWeekYear = calendar.component(.yearForWeekOfYear, from: targetDate)
        let components = ParsingComponents(reference: context.reference)
        components.assign(.isoWeek, value: targetWeek)
        components.assign(.isoWeekYear, value: targetWeekYear)
        components.assignNull(.hour)

        var dateComponents = DateComponents()
        dateComponents.weekOfYear = targetWeek
        dateComponents.yearForWeekOfYear = targetWeekYear
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

        let result = context.createParsingResult(
            index: match.startIndex(at: 0) ?? match.index,
            text: matched.trimmingCharacters(in: .whitespacesAndNewlines),
            start: components)
        result.addTag("JARelativeWeekParser")
        return result
    }

    private func extractCapturedNumber(match: TextMatch) -> Int? {
        guard match.captureCount > 1 else { return nil }
        for index in 1..<match.captureCount {
            if let captureText = match.string(at: index), let value = Int(captureText) {
                return value
            }
        }
        return nil
    }

    private func extractAllNumbers(from text: String) -> [Int] {
        guard let regex = try? NSRegularExpression(pattern: "\\d+") else { return [] }
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        return regex.matches(in: text, options: [], range: range).compactMap { Int(nsText.substring(with: $0.range)) }
    }
}
