import Foundation

/// A bare month name (month is known but no day was given) means the **1st** of that month — not
/// the reference date's day-of-month, which is rarely what "october"/"juni"/"octobre" means when
/// scheduling. Applied across every locale via the common configuration.
///
/// It also forward-dates by a year when requested and the 1st of that month is already past
/// (`ForwardDateRefiner` only nudges dates 1–3 days into the past, which isn't enough for "june"
/// typed mid-month).
public final class MonthOnlyDayRefiner: Refiner {
    public init() {}

    public func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        let refDate = context.reference.instant
        let calendar = Calendar.current
        for result in results {
            apply(to: result.start, refDate: refDate, calendar: calendar, forward: context.options.forwardDate)
            if let end = result.end {
                apply(to: end, refDate: refDate, calendar: calendar, forward: context.options.forwardDate)
            }
        }
        return results
    }

    private func apply(to components: ParsingComponents, refDate: Date, calendar: Calendar, forward: Bool) {
        // Only bare months: month explicitly stated, day not.
        guard components.isCertain(.month), !components.isCertain(.day) else { return }
        components.imply(.day, value: 1)

        // Forward-date to next year if the 1st is already past (and the year wasn't explicit).
        guard forward, !components.isCertain(.year), let date = components.date() else { return }
        if calendar.startOfDay(for: date) < calendar.startOfDay(for: refDate), let year = components.get(.year) {
            components.imply(.year, value: year + 1)
        }
    }
}
