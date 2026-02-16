// DERelativeWeekParser.swift - Parser for relative week expressions in German
import Foundation

/// Parser for relative week expressions in German text
final class DERelativeWeekParser: AbstractParserWithWordBoundaryChecking, @unchecked Sendable {
    override func innerPattern(context: ParsingContext) -> String {
        let patternThis = "(?i)(?:diese\\s+woche)"
        let patternLast = "(?i)(?:letzte\\s+woche)"
        let patternNext = "(?i)(?:n[aä]chste\\s+woche)"
        let patternWeeksAgo = "(?:(?:vor\\s+)?(\\d+)\\s+wochen?\\s*(?:zuvor|her|zur[üu]ck)?)"
        let patternInWeeks = "(?:(?:in)\\s+(\\d+)\\s+wochen?)"
        let patternBeforeLast = "(?i)(?:vorletzte\\s+woche)"
        let patternAfterNext = "(?i)(?:[üu]bern[aä]chste\\s+woche)"

        return [
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
        let text = match.text.lowercased()
        let referenceDate = context.reference.instant
        let calendar = Calendar(identifier: .iso8601)
        let allNumbers = extractAllNumbers(from: text)
        var weekOffset = 0

        if text.contains("diese woche") {
            weekOffset = 0
        } else if text.contains("vorletzte woche") {
            weekOffset = -2
        } else if text.contains("übernächste woche") || text.contains("uebernaechste woche") || text.contains("ubernachste woche") {
            weekOffset = 2
        } else if text.contains("letzte woche") {
            weekOffset = -1
        } else if text.contains("nächste woche") || text.contains("naechste woche") || text.contains("nachste woche") {
            weekOffset = 1
        } else if text.contains("vor ") || text.contains("zuvor") || text.contains("her") || text.contains("zurück") || text.contains("zuruck") {
            if let weeksAgo = extractCapturedNumber(match: match) ?? allNumbers.first {
                weekOffset = -weeksAgo
            }
        } else if text.contains("in ") {
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

        let result = context.createParsingResult(index: match.index, text: match.text, start: components)
        result.addTag("DERelativeWeekParser")
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
