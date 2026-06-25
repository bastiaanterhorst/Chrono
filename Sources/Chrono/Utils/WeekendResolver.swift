// WeekendResolver.swift - Locale-aware "this/next/last weekend" resolution.
import Foundation

/// Resolves "this/next/last weekend" to the FIRST day of the weekend (locale-aware).
///
/// The weekend is anchored to the ISO week (Mon–Sun) containing the reference date and shifted by
/// `weekOffset` whole weeks (0 = this, +1 = next, -1 = last) — a *week* offset, not a weekday offset,
/// so "next weekend" is genuinely one week after "this weekend". The first weekend day is taken from
/// the calendar's CLDR weekend rules (Saturday for every locale Space supports), with a Saturday
/// fallback if a locale carries no weekend information.
enum WeekendResolver {
    /// The (year, month, day) of the first weekend day, or nil if the date math fails.
    static func firstWeekendDay(reference: Date, weekOffset: Int,
                                localeIdentifier: String) -> DateComponents? {
        var calendar = Calendar(identifier: .iso8601)            // firstWeekday = Monday
        calendar.locale = Locale(identifier: localeIdentifier)

        // Monday 00:00 of the reference's ISO week.
        guard let monday = calendar.date(from:
                calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: reference)) else {
            return nil
        }

        // First weekend day within Mon…Sun. Default to Saturday (Monday + 5) so a locale without
        // weekend data still resolves sensibly.
        var firstWeekend = calendar.date(byAdding: .day, value: 5, to: monday)
        for offset in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: offset, to: monday),
               calendar.isDateInWeekend(day) {
                firstWeekend = day
                break
            }
        }

        guard let weekendDay = firstWeekend,
              let target = calendar.date(byAdding: .day, value: weekOffset * 7, to: weekendDay) else {
            return nil
        }
        return calendar.dateComponents([.year, .month, .day], from: target)
    }

    /// Builds a `ParsingComponents` for the first weekend day as a concrete DAY (year/month/day
    /// assigned, time implied to noon). Deliberately does NOT assign `.isoWeek`, so downstream
    /// classification treats it as a specific day rather than a week.
    static func weekendComponents(context: ParsingContext, weekOffset: Int,
                                  localeIdentifier: String) -> ParsingComponents? {
        guard let wc = firstWeekendDay(reference: context.reference.instant,
                                       weekOffset: weekOffset, localeIdentifier: localeIdentifier),
              let year = wc.year, let month = wc.month, let day = wc.day else {
            return nil
        }
        let components = ParsingComponents(reference: context.reference)
        components.assign(.year, value: year)
        components.assign(.month, value: month)
        components.assign(.day, value: day)
        components.imply(.hour, value: 12)
        components.imply(.minute, value: 0)
        components.imply(.second, value: 0)
        components.imply(.millisecond, value: 0)
        return components
    }
}
