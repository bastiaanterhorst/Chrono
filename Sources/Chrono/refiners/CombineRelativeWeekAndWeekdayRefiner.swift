// CombineRelativeWeekAndWeekdayRefiner.swift
import Foundation

/// Merges a relative-week expression and an adjacent weekday into that weekday WITHIN the week,
/// in EITHER order: "next week thursday" / "thursday next week" — and every localized form
/// (e.g. "volgende week donderdag", "nächste woche donnerstag", "la próxima semana el jueves") →
/// the named weekday of that relative week.
///
/// Why this is needed: a standalone weekday result resolves to the weekday of the CURRENT week
/// (forward-adjusted), so on its own "next week thursday" would keep the week (Monday anchor) or
/// pick this week's Thursday. We instead recompute the day from the relative week's anchor (its
/// Monday) plus the named weekday.
///
/// Cross-locale notes:
/// - The named weekday is read from the weekday result's RESOLVED DATE, not from its `.weekday`
///   component, so it is independent of each locale's internal weekday numbering (EN/ES/DE/NL/PT
///   use Sun=0…Sat=6 while FR uses Sun=1…Sat=7).
/// - It must run BEFORE OverlapRemovalRefiner: in the "<week> <weekday>" order several locales'
///   week parsers report the whole input as their `text`, whose span contains the weekday — overlap
///   removal would otherwise drop the weekday result before it could be merged.
public struct CombineRelativeWeekAndWeekdayRefiner: Refiner {
    public init() {}

    public func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        if results.count < 2 { return results }

        let nsText = context.text as NSString
        let nsLen = nsText.length
        func endOf(_ r: ParsingResult) -> Int { min(r.index + (r.text as NSString).length, nsLen) }

        // A relative week (this/last/next week, week N, …): a certain ISO week, not itself a weekday.
        func isWeek(_ r: ParsingResult) -> Bool {
            r.start.isCertain(.isoWeek) && r.start.get(.weekday) == nil
        }
        // A weekday (monday…sunday) that is not itself a week.
        func isWeekday(_ r: ParsingResult) -> Bool {
            r.start.get(.weekday) != nil && !r.start.isCertain(.isoWeek)
        }
        // The two parts form one phrase when separated only by whitespace, a short connector word
        // (e.g. PT "na", ES "la", NL "op", EN "the"/"on"/"at"), or when the week's text span
        // overlaps the weekday (which happens for the full-input-text week parsers).
        func adjacent(_ a: ParsingResult, _ b: ParsingResult) -> Bool {
            let earlier = a.index <= b.index ? a : b
            let later = a.index <= b.index ? b : a
            let gapStart = endOf(earlier)
            if gapStart >= later.index { return true } // overlap
            let between = nsText.substring(with: NSRange(location: gapStart, length: later.index - gapStart))
            let trimmed = between.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return true }
            return trimmed.count <= 5 && trimmed.allSatisfy { $0.isLetter }
        }

        var consumed = Set<Int>()
        var output: [ParsingResult] = []

        for i in 0..<results.count {
            if consumed.contains(i) { continue }
            let current = results[i]

            var partnerIndex: Int?
            if isWeek(current) {
                for j in 0..<results.count where j != i && !consumed.contains(j) {
                    if isWeekday(results[j]) && adjacent(current, results[j]) { partnerIndex = j; break }
                }
            } else if isWeekday(current) {
                for j in 0..<results.count where j != i && !consumed.contains(j) {
                    if isWeek(results[j]) && adjacent(current, results[j]) { partnerIndex = j; break }
                }
            }

            guard let j = partnerIndex else {
                output.append(current)
                continue
            }

            let week = isWeek(current) ? current : results[j]
            let weekday = isWeek(current) ? results[j] : current

            if let merged = merge(week: week, weekday: weekday, context: context, nsText: nsText, nsLen: nsLen) {
                consumed.insert(i)
                consumed.insert(j)
                output.append(merged)
            } else {
                output.append(current)
            }
        }

        return output
    }

    private func merge(week: ParsingResult, weekday: ParsingResult, context: ParsingContext,
                       nsText: NSString, nsLen: Int) -> ParsingResult? {
        guard let weekAnchor = week.start.date(),    // Monday of the relative ISO week
              let weekdayDate = weekday.start.date()  // the weekday, in whatever week it resolved to
        else { return nil }

        let iso = Calendar(identifier: .iso8601)
        let comp = iso.component(.weekday, from: weekdayDate) // 1=Sun … 7=Sat
        let daysFromMonday = (comp == 1) ? 6 : (comp - 2)     // Mon=0 … Sat=5, Sun=6
        guard let target = iso.date(byAdding: .day, value: daysFromMonday, to: weekAnchor) else { return nil }

        let merged = week.start.clone()
        let dc = iso.dateComponents([.year, .month, .day], from: target)
        if let y = dc.year { merged.assign(.year, value: y) }
        if let m = dc.month { merged.assign(.month, value: m) }
        if let d = dc.day { merged.assign(.day, value: d) }
        merged.assign(.weekday, value: comp - 1) // store Sun=0 … Sat=6
        // It is now a specific day, not a whole week.
        merged.assignNull(.isoWeek)
        merged.assignNull(.isoWeekYear)

        // Span both contributing matches, clamped to the input bounds.
        let startLoc = max(0, min(min(week.index, weekday.index), nsLen))
        let weekEnd = min(week.index + (week.text as NSString).length, nsLen)
        let weekdayEnd = min(weekday.index + (weekday.text as NSString).length, nsLen)
        let endLoc = max(startLoc, min(max(weekEnd, weekdayEnd), nsLen))
        let combinedText = nsText.substring(with: NSRange(location: startLoc, length: endLoc - startLoc))

        return context.createParsingResult(index: startLoc, text: combinedText, start: merged, end: nil)
    }
}
