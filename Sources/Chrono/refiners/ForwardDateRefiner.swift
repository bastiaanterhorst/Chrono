import Foundation

/**
 * When the parsed date is before the reference date but close (within a day or two),
 * this refiner adjusts it to a future date instead.
 *
 * For example, if today is Sept 15 and the parsed date is Sept 14,
 * it likely refers to next year's Sept 14 rather than yesterday.
 */
public final class ForwardDateRefiner: Refiner {
    
    public func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        // If the option is disabled, skip this refiner
        if !context.options.forwardDate {
            return results
        }
        
        // Get the reference date
        let refDate = context.reference.instant

        // A stated month whose year was only *inferred* and that has already gone by means the
        // NEXT one: on 26 August, "april 22" is 22 April next year, not four months ago. The
        // reference year is the only year a month-name parser can infer, so the correction belongs
        // here — once, after every locale's parsers have run — rather than in each of them (they
        // variously get the month-first form right and the day-first form wrong, or miss a past day
        // inside the current month). Runs before the narrow 1–3 day nudge below, which it subsumes
        // for month-bearing results.
        for result in results {
            let shift = yearsForward(result.start, refDate: refDate)
            applyYearShift(result.start, years: shift)
            if let end = result.end {
                // Shift the end by at least as much as the start, so a range never inverts:
                // "20 August to 5 September" moves whole, and "28 December to 3 January" — where
                // only the end has gone by — still closes in the following year.
                applyYearShift(end, years: max(shift, yearsForward(end, refDate: refDate)))
            }
        }

        return results.map { result in
            // Handle week-number shorthand with an implied year (e.g. "w10").
            // If that inferred week is already behind the reference date, move it to next year.
            // "Behind" is measured a whole week at a time: the date these components resolve to is
            // the week's *first day*, so comparing it against the reference instant would call the
            // current week past from its second day onward — typing "w35" on the Wednesday of
            // week 35 would mean next year. A week has gone by only once its last day has.
            // Which day is first, and which numbering applies, comes from the parse's week rules —
            // never assume Monday, since the host may count weeks from Sunday or Saturday.
            if result.start.isCertain(.isoWeek),
               !result.start.isCertain(.isoWeekYear),
               let parsedDate = result.start.date(),
               Self.isWeekBehind(weekStart: parsedDate, refDate: refDate, calendar: context.weekCalendar),
               let week = result.start.get(.isoWeek),
               let inferredWeekYear = result.start.get(.isoWeekYear) {
                let targetWeekYear = inferredWeekYear + 1

                let isoCalendar = context.weekCalendar

                var weekComponents = DateComponents()
                weekComponents.weekOfYear = week
                weekComponents.yearForWeekOfYear = targetWeekYear
                weekComponents.weekday = isoCalendar.firstWeekday
                weekComponents.hour = result.start.get(.hour) ?? 12
                weekComponents.minute = result.start.get(.minute) ?? 0
                weekComponents.second = result.start.get(.second) ?? 0

                if let weekStart = isoCalendar.date(from: weekComponents) {
                    let updatedComponents = result.start.clone()
                    updatedComponents.assign(.isoWeekYear, value: targetWeekYear)
                    updatedComponents.setCertain(.isoWeekYear)

                    let values = isoCalendar.dateComponents([.year, .month, .day], from: weekStart)
                    if let year = values.year {
                        updatedComponents.assign(.year, value: year)
                        updatedComponents.setCertain(.year)
                    }
                    if let month = values.month {
                        updatedComponents.assign(.month, value: month)
                    }
                    if let day = values.day {
                        updatedComponents.assign(.day, value: day)
                    }

                    return ParsingResult(
                        reference: result.reference,
                        index: result.index,
                        text: result.text,
                        start: updatedComponents,
                        end: result.end
                    )
                }
            }

            // Skip if already has year
            if result.start.isCertain(.year) {
                return result
            }
            
            // Skip if the component isn't a DateTime
            guard let date = result.start.date() else {
                return result
            }
            
            // If the date is in the past by more than a few days, and not certain about the year,
            // then we shift the date forward
            if date < refDate {
                let dayDifference = Calendar.current.dateComponents([.day], from: date, to: refDate).day ?? 0
                
                // Only adjust if it's within a day or two, suggesting it's likely a reference to a future date
                if dayDifference > 0 && dayDifference <= 3 {
                    let calendar = Calendar.current
                    
                    // Try adjusting to next year
                    var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
                    components.year = (components.year ?? 0) + 1
                    
                    if let forwardDate = calendar.date(from: components) {
                        // Create a new components and mark year as certain
                        var updatedComponents = result.start.clone()
                        if let year = components.year {
                            updatedComponents.assign(.year, value: year)
                            updatedComponents.setCertain(.year)
                        }
                        
                        // Create a new result with updated components
                        return ParsingResult(
                            reference: result.reference,
                            index: result.index,
                            text: result.text,
                            start: updatedComponents,
                            end: result.end
                        )
                    }
                }
            }
            
            return result
        }
    }

    /// Whether these components state a month but only infer the year, making a year bump the
    /// right way to forward-date them. Weekday- and ISO-week-based results are excluded: those
    /// carry their own forward-dating, and a year is the wrong unit to move them by.
    private func isYearShiftable(_ components: ParsingComponents) -> Bool {
        components.isCertain(.month)
            && !components.isCertain(.year)
            && !components.isCertain(.weekday)
            && !components.isCertain(.isoWeek)
            && !components.isCertain(.isoWeekYear)
    }

    /// How many years these components must move to stop being in the past. Compared at day
    /// granularity so that "26 August", typed on the afternoon of 26 August, stays today rather
    /// than jumping a year. Bounded, so an impossible date (e.g. "february 30") can't spin.
    private func yearsForward(_ components: ParsingComponents, refDate: Date) -> Int {
        guard isYearShiftable(components) else { return 0 }
        let calendar = Calendar.current
        let refDay = calendar.startOfDay(for: refDate)
        let probe = components.clone()
        var years = 0
        while years < 4 {
            guard let date = probe.date(), calendar.startOfDay(for: date) < refDay,
                  let year = probe.get(.year) else { break }
            probe.imply(.year, value: year + 1)
            years += 1
        }
        return years
    }

    /// Moves the inferred year forward by `years`, leaving it inferred — the user never stated it.
    private func applyYearShift(_ components: ParsingComponents, years: Int) {
        guard years > 0, isYearShiftable(components), let year = components.get(.year) else { return }
        components.imply(.year, value: year + years)
    }

    /// Whether the whole week beginning at `weekStart` lies before the reference day. A week is
    /// seven days wherever it starts, so its last day is six on from its first — and it is past
    /// only once that last day is. The calendar is the parse's own, so a Sunday-first host asks the
    /// question about *its* week, which ends on a different day than ISO's.
    private static func isWeekBehind(weekStart: Date, refDate: Date, calendar: Calendar) -> Bool {
        guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return weekStart < refDate
        }
        return calendar.startOfDay(for: weekEnd) < calendar.startOfDay(for: refDate)
    }

}
