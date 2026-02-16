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
public enum Meridiem: Int {
    case am = 0
    case pm = 1
}

/// Days of the week
public enum Weekday: Int {
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

/// Options for parsing
public struct ParsingOptions {
    /// Enable debug mode
    public var debug: Any?
    
    /// Forward date adjustment (move dates to future if they're in the past)
    public var forwardDate: Bool
    
    /// Custom timezone mappings for overriding standard timezone abbreviations
    public var timezones: [String: Int]?
    
    /// Creates new parsing options
    /// - Parameters:
    ///   - forwardDate: If true, adjusts past dates to future
    ///   - debug: Debug handler or boolean
    ///   - timezones: Custom timezone mappings
    public init(forwardDate: Bool = false, debug: Any? = nil, timezones: [String: Int]? = nil) {
        self.forwardDate = forwardDate
        self.debug = debug
        self.timezones = timezones
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