// PTRelativeWeekParser.swift - Parser for relative week expressions in Portuguese
import Foundation

/// Parser for relative week expressions in Portuguese text
final class PTRelativeWeekParser: AbstractParserWithWordBoundaryChecking, @unchecked Sendable {
    override func innerPattern(context: ParsingContext) -> String {
        let patternThis = "(?i)(?:esta\\s+semana)"
        let patternLast = "(?i)(?:semana\\s+passada)"
        let patternNext = "(?i)(?:pr[oó]xima\\s+semana)"
        let patternWeeksAgo = "(?:(?<!\\w)(?:h[aá]|faz)\\s+(\\d+)\\s+semanas?)"
        let patternInWeeks = "(?:(?<!\\w)(?:em|daqui\\s+a)\\s+(\\d+)\\s+semanas?)"
        let patternBeforeLast = "(?i)(?:semana\\s+retrasada)"
        let patternAfterNext = "(?i)(?:semana\\s+seguinte)"

        // Weekend variants must come BEFORE the bare-week patterns.
        let patternThisWeekend = "(?i)(?:(?:este|neste)\\s+fim\\s+de\\s+semana)"
        let patternNextWeekend = "(?i)(?:(?:o\\s+|no\\s+)?pr[oó]ximo\\s+fim\\s+de\\s+semana)"
        let patternLastWeekend = "(?i)(?:(?:o\\s+)?fim\\s+de\\s+semana\\s+passado)"

        return [
            patternThisWeekend,
            patternNextWeekend,
            patternLastWeekend,
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
        let text = matched.foldedForMatching()
        let referenceDate = context.reference.instant
        let calendar = context.weekCalendar
        let allNumbers = extractAllNumbers(from: text)
        var weekOffset = 0

        // Weekend → first weekend day (locale-aware) as a concrete DAY, not an ISO week. Runs before
        // the week checks. `text` is diacritic-folded, so "próximo" reads as "proximo".
        if text.contains("fim de semana") {
            let weekendOffset = text.contains("proximo") ? 1 : (text.contains("passado") ? -1 : 0)
            if let components = WeekendResolver.weekendComponents(
                context: context, weekOffset: weekendOffset, localeIdentifier: "pt") {
                components.addTag("PTRelativeWeekParser")
                return context.createParsingResult(
                    index: match.startIndex(at: 0) ?? match.index,
                    text: matched.trimmingCharacters(in: .whitespacesAndNewlines),
                    start: components)
            }
        }

        if text.contains("esta semana") {
            weekOffset = 0
        } else if text.contains("semana retrasada") {
            weekOffset = -2
        } else if text.contains("semana seguinte") {
            weekOffset = 2
        } else if text.contains("semana passada") {
            weekOffset = -1
        } else if text.contains("proxima semana") {
            weekOffset = 1
        } else if text.contains("ha ") || text.contains("faz ") {
            if let weeksAgo = extractCapturedNumber(match: match) ?? allNumbers.first {
                weekOffset = -weeksAgo
            }
        } else if text.contains("em ") || text.contains("daqui a ") {
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
        dateComponents.weekday = context.weekCalendar.firstWeekday
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
        result.addTag("PTRelativeWeekParser")
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
