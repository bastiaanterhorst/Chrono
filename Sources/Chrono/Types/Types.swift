// Types.swift - Core types for Chrono.swift
import Foundation

/// Components of a date/time that can be parsed
public enum Component: String, CaseIterable, Sendable {
    case year
    case month
    case day
    case weekday
    case hour
    case minute
    case second
    case millisecond
    case meridiem // AM/PM
    case timezoneOffset
    case isoWeek    // ISO 8601 week number (1-53)
    case isoWeekYear // Year for ISO week (can differ from calendar year)
}

/// Time of day (AM/PM)
public enum Meridiem: Int, Sendable {
    case am = 0
    case pm = 1
}

/// Days of the week
public enum Weekday: Int, Sendable {
    case sunday = 0
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6
}

/// A component dictionary representing a parsed date
public typealias ParsedComponents = [Component: Int]

/// Reference date and timezone for parsing
public struct ParsingReference {
    /// The reference date instance
    public var instant: Date
    
    /// The timezone to use for parsing (as string or offset in minutes)
    public var timezone: Any?
    
    /// Creates a new parsing reference
    /// - Parameters:
    ///   - instant: The reference date (defaults to current date)
    ///   - timezone: The timezone (string or minutes offset, defaults to nil)
    public init(instant: Date = Date(), timezone: Any? = nil) {
        self.instant = instant
        self.timezone = timezone
    }
}

/// How weeks are numbered and where they begin.
///
/// Week numbering is not universal: ISO 8601 runs Monday–Sunday and gives week 1 to the first week
/// holding four days of the new year, while the United States (among others) starts weeks on Sunday
/// and gives week 1 to whichever week holds 1 January. The same day can therefore sit in week 35
/// under one convention and week 36 under another, and near the turn of the year *every* week can
/// differ by one.
///
/// So a host application whose users pick their own first day of the week must say which convention
/// it counts in — otherwise "w5" parses as one week and displays as another. Pass the very calendar
/// the app numbers its weeks with; the default is ISO 8601.
public struct WeekRules: Sendable, Equatable {
    /// The first day of the week, in `Calendar`'s numbering: 1 = Sunday … 7 = Saturday.
    public let firstWeekday: Int

    /// How many days of the new year the first week must contain to be week 1.
    public let minimumDaysInFirstWeek: Int

    /// ISO 8601: weeks begin on Monday, and week 1 is the first with four days in the new year.
    public static let iso = WeekRules(firstWeekday: 2, minimumDaysInFirstWeek: 4)

    public init(firstWeekday: Int, minimumDaysInFirstWeek: Int) {
        self.firstWeekday = firstWeekday
        self.minimumDaysInFirstWeek = minimumDaysInFirstWeek
    }

    /// Adopts the week convention of an existing calendar — the usual way to stay in step with
    /// whatever the host application already counts and displays weeks with.
    public init(_ calendar: Calendar) {
        self.init(firstWeekday: calendar.firstWeekday,
                  minimumDaysInFirstWeek: calendar.minimumDaysInFirstWeek)
    }

    /// A calendar that counts weeks by these rules.
    var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = firstWeekday
        c.minimumDaysInFirstWeek = minimumDaysInFirstWeek
        return c
    }
}

/// Options for parsing
public struct ParsingOptions {
    /// Enable debug mode
    public var debug: Any?
    
    /// Forward date adjustment (move dates to future if they're in the past)
    public var forwardDate: Bool
    
    /// Custom timezone mappings for overriding standard timezone abbreviations
    public var timezones: [String: Int]?

    /// The week convention every week number in this parse is read and written in. Defaults to
    /// ISO 8601; pass the host application's own calendar when its users choose a first weekday.
    public var weekRules: WeekRules
    
    /// Creates new parsing options
    /// - Parameters:
    ///   - forwardDate: If true, adjusts past dates to future
    ///   - debug: Debug handler or boolean
    ///   - timezones: Custom timezone mappings
    ///   - weekRules: Week numbering convention (defaults to ISO 8601)
    public init(forwardDate: Bool = false, debug: Any? = nil, timezones: [String: Int]? = nil,
                weekRules: WeekRules = .iso) {
        self.forwardDate = forwardDate
        self.debug = debug
        self.timezones = timezones
        self.weekRules = weekRules
    }
}

/// Result of a successful parse operation
public struct ParsedResult {
    /// Index where the date/time text was found in the original string
    public let index: Int
    
    /// The text that was recognized as a date/time
    public let text: String
    
    /// The start date components
    public let start: ParsedResultDate
    
    /// The end date components (for ranges)
    public let end: ParsedResultDate?
    
    /// Creates a new parsed result
    /// - Parameters:
    ///   - index: The index in the original text
    ///   - text: The matched text
    ///   - start: The start date
    ///   - end: The end date (optional)
    public init(index: Int, text: String, start: ParsedResultDate, end: ParsedResultDate? = nil) {
        self.index = index
        self.text = text
        self.start = start
        self.end = end
    }
}

/// A date in a parsed result
public struct ParsedResultDate {
    /// The parsed date
    public let date: Date
    
    /// Known components from the parse operation
    public let knownValues: [Component: Int]
    
    /// Implied components added during parsing
    public let impliedValues: [Component: Int]
    
    /// Creates a new parsed result date
    /// - Parameters:
    ///   - date: The date value
    ///   - knownValues: Components explicitly found in the text
    ///   - impliedValues: Components inferred during parsing
    public init(date: Date, knownValues: [Component: Int], impliedValues: [Component: Int]) {
        self.date = date
        self.knownValues = knownValues
        self.impliedValues = impliedValues
    }
    
    /// Gets the value of a component
    /// - Parameter component: The component to retrieve
    /// - Returns: The component value or nil if not present
    public func get(_ component: Component) -> Int? {
        return knownValues[component] ?? impliedValues[component]
    }
    
    /// Checks if a component is certain (explicitly found in text)
    /// - Parameter component: The component to check
    /// - Returns: True if the component was explicitly found
    public func isCertain(_ component: Component) -> Bool {
        return knownValues.keys.contains(component)
    }
    
    /// Gets the ISO week number for this date
    /// - Returns: The ISO week number (1-53) or nil if not available
    public var isoWeek: Int? {
        return get(.isoWeek)
    }
    
    /// Gets the ISO week year for this date (can differ from calendar year)
    /// - Returns: The ISO week year or nil if not available
    public var isoWeekYear: Int? {
        return get(.isoWeekYear)
    }
    
    /// Gets the start date of the ISO week (Monday)
    ///
    /// - Important: This reads the week components strictly as ISO 8601. When the parse ran under
    ///   non-ISO `WeekRules` — a host that counts weeks from Sunday, say — the stored week number
    ///   is in *that* numbering, and interpreting it as ISO here gives the wrong day. Prefer
    ///   `date`, which is resolved with the parse's own week rules.
    /// - Returns: Date representing the start of the ISO week (Monday)
    public var isoWeekStart: Date? {
        guard let week = isoWeek, let year = isoWeekYear else {
            return nil
        }
        
        var calendar = Calendar(identifier: .iso8601)
        calendar.firstWeekday = 2 // Monday is the first day
        
        var components = DateComponents()
        components.weekOfYear = week
        components.yearForWeekOfYear = year
        components.weekday = 2 // Monday (2 in ISO 8601)
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        return calendar.date(from: components)
    }
    
    /// Gets the end date of the ISO week (Sunday)
    /// - Returns: Date representing the end of the ISO week (Sunday)
    public var isoWeekEnd: Date? {
        guard let weekStart = isoWeekStart else {
            return nil
        }
        
        // Add 6 days to get to Sunday (end of ISO week)
        return Calendar(identifier: .iso8601).date(byAdding: .day, value: 6, to: weekStart)
    }
}