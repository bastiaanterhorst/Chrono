import Foundation

/// Which of the two leading numbers in a purely numeric date is the day.
///
/// This is a property of the reader's *region*, not their language: 22/4 is 22 April to most of the
/// world and an impossible date in the United States, and the same person may well read English
/// while writing dates the European way. So a host should pass the convention its user actually
/// reads, taken from the system region, rather than letting the parsing language decide.
public enum NumericDateOrder: Sendable, Equatable {
    /// 22/4 is 22 April — most of the world.
    case dayFirst
    /// 4/22 is 22 April — chiefly the United States.
    case monthFirst

    /// Reads the convention out of a locale's own short-date pattern.
    ///
    /// Taken from CLDR rather than a hand-kept list of regions, so it follows the system exactly and
    /// stays right as territories change. Returns nil for a locale that states neither field.
    public init?(_ locale: Locale) {
        guard let pattern = DateFormatter.dateFormat(fromTemplate: "yMd", options: 0, locale: locale),
              let day = pattern.firstIndex(of: "d"),
              let month = pattern.firstIndex(of: "M") else { return nil }
        self = day < month ? .dayFirst : .monthFirst
    }
}

/// Turns the two leading numbers of a numeric date into a day and a month.
enum NumericDateInterpreter {
    /// Reads `first` and `second` in the given order, falling back to the other order when the
    /// stated one is impossible — "22/4" cannot be month 22, and refusing it outright would serve
    /// nobody. An unreadable pair (both above 12, or either out of range) returns nil rather than
    /// a guess.
    static func dayAndMonth(first: Int, second: Int, order: NumericDateOrder) -> (day: Int, month: Int)? {
        func readable(_ pair: (day: Int, month: Int)) -> Bool {
            (1...31).contains(pair.day) && (1...12).contains(pair.month)
        }
        let stated: (day: Int, month: Int) = order == .dayFirst ? (first, second) : (second, first)
        if readable(stated) { return stated }
        let swapped: (day: Int, month: Int) = order == .dayFirst ? (second, first) : (first, second)
        if readable(swapped) { return swapped }
        return nil
    }
}
