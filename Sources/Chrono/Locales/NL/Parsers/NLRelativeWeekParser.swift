// NLRelativeWeekParser.swift - Parser for relative week expressions in Dutch
import Foundation

/// Parser for relative week expressions in Dutch text
final class NLRelativeWeekParser: AbstractParserWithWordBoundaryChecking, @unchecked Sendable {
    override func innerPattern(context: ParsingContext) -> String {
        let patternThis = "(?i)(?:deze\\s+week)"
        let patternLast = "(?i)(?:vorige\\s+week|afgelopen\\s+week)"
        let patternNext = "(?i)(?:volgende\\s+week|komende\\s+week|komend\\s+week)"

        let patternWeeksAgo = "(?:(\\d+)\\s+weken?\\s+geleden)"
        let patternInWeeks = "(?:(?:in|over|binnen)\\s+(\\d+)\\s+weken?)"
        let patternWeeksFromNow = "(?:(\\d+)\\s+weken?\\s+(?:vanaf\\s+nu|van\\s+nu\\s+af))"

        let patternBeforeLast = "(?:de\\s+week\\s+voor\\s+vorige)"
        let patternAfterNext = "(?:de\\s+week\\s+na\\s+volgende)"

        return [
            patternThis,
            patternLast,
            patternNext,
            patternWeeksAgo,
            patternInWeeks,
            patternWeeksFromNow,
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

        if text.contains("deze week") {
            weekOffset = 0
        } else if text.contains("vorige week") || text.contains("afgelopen week") {
            weekOffset = -1
        } else if text.contains("volgende week") || text.contains("komende week") || text.contains("komend week") {
            weekOffset = 1
        } else if text.contains("week voor vorige") {
            weekOffset = -2
        } else if text.contains("week na volgende") {
            weekOffset = 2
        } else if text.contains("geleden") {
            if let weeksAgo = extractCapturedNumber(match: match) ?? allNumbers.first {
                weekOffset = -weeksAgo
            }
        } else if text.contains("vanaf nu") || text.contains("van nu af") {
            if let weeksLater = extractCapturedNumber(match: match) ?? allNumbers.first {
                weekOffset = weeksLater
            }
        } else if text.contains("in ") || text.contains("over ") || text.contains("binnen ") {
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
        result.addTag("NLRelativeWeekParser")
        return result
    }

    private func extractCapturedNumber(match: TextMatch) -> Int? {
        guard match.captureCount > 1 else {
            return nil
        }

        for index in 1..<match.captureCount {
            if let captureText = match.string(at: index), let number = Int(captureText) {
                return number
            }
        }

        return nil
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
