// ParsingComponents.swift - Date components for parsing
import Foundation

/// Components of a parsed date
public final class ParsingComponents: @unchecked Sendable {
    /// Known (explicitly specified) component values
    private var knownValues: [Component: Int]
    
    /// Implied (inferred) component values
    private var impliedValues: [Component: Int]
    
    /// The reference date and timezone
    private let reference: ReferenceWithTimezone
    
    /// Provides access to known values dictionary
    public var knownValuesDictionary: [Component: Int] {
        return knownValues
    }
    
    /// Provides access to implied values dictionary
    public var impliedValuesDictionary: [Component: Int] {
        return impliedValues
    }
    
    /// Tags for this component set
    private var tags: Set<String> = []
    
    /// Creates a new components object
    /// - Parameters:
    ///   - reference: The reference date/timezone
    ///   - knownValues: Initial known values
    init(reference: ReferenceWithTimezone, knownValues: [Component: Int] = [:]) {
        self.reference = reference
        self.knownValues = knownValues
        self.impliedValues = [:]
        
        // Set default implied values from reference date
        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second, .nanosecond],
            from: reference.instant
        )
        
        imply(.year, value: components.year ?? calendar.component(.year, from: Date()))
        imply(.month, value: components.month ?? calendar.component(.month, from: Date()))
        imply(.day, value: components.day ?? calendar.component(.day, from: Date()))
        imply(.hour, value: 12)
        imply(.minute, value: 0)
        imply(.second, value: 0)
        imply(.millisecond, value: 0)
        
        // Set default implied values for ISO week
        let isoCalendar = Calendar(identifier: .iso8601)
        let isoComponents = isoCalendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: reference.instant)
        
        imply(.isoWeek, value: isoComponents.weekOfYear ?? 1)
        imply(.isoWeekYear, value: isoComponents.yearForWeekOfYear ?? components.year ?? calendar.component(.year, from: Date()))
    }
    
    /// Gets a component value
    /// - Parameter component: The component to retrieve
    /// - Returns: The component value or nil if not set
    func get(_ component: Component) -> Int? {
        if knownValues.keys.contains(component) {
            // Special handling for null values (marked with -1)
            let value = knownValues[component]
            return value == -1 ? nil : value
        }
        
        if impliedValues.keys.contains(component) {
            // Special handling for null values (marked with -1)
            let value = impliedValues[component]
            return value == -1 ? nil : value
        }
        
        return nil
    }
    
    /// Specifically marks a component as "null" to prevent it from being implied
    /// This is useful for preventing conflicts between parsers (e.g., hour vs. isoWeek)
    /// - Parameter component: The component to mark as null
    /// - Returns: Self for chaining
    @discardableResult
    func assignNull(_ component: Component) -> ParsingComponents {
        // We use -1 as a special sentinel value meaning "explicitly not set"
        knownValues[component] = -1
        impliedValues.removeValue(forKey: component)
        return self
    }
    
    /// Sets a known component value
    /// - Parameters:
    ///   - component: The component to set
    ///   - value: The value to set
    /// - Returns: Self for chaining
    @discardableResult
    func assign(_ component: Component, value: Int) -> ParsingComponents {
        knownValues[component] = value
        return self
    }
    
    /// Sets an implied component value
    /// - Parameters:
    ///   - component: The component to imply
    ///   - value: The value to set
    /// - Returns: Self for chaining
    @discardableResult
    func imply(_ component: Component, value: Int) -> ParsingComponents {
        if !knownValues.keys.contains(component) {
            impliedValues[component] = value
        }
        return self
    }
    
    /// Checks if a component is certain (explicitly set)
    /// - Parameter component: The component to check
    /// - Returns: True if the component has a known value
    func isCertain(_ component: Component) -> Bool {
        return knownValues.keys.contains(component)
    }
    
    /// Marks a component as certain (moves it from implied to known)
    /// - Parameter component: The component to mark as certain
    /// - Returns: Self for chaining
    @discardableResult
    func setCertain(_ component: Component) -> ParsingComponents {
        if !knownValues.keys.contains(component) && impliedValues.keys.contains(component) {
            knownValues[component] = impliedValues[component]
            impliedValues.removeValue(forKey: component)
        }
        return self
    }
    
    /// Gets a list of certain components
    /// - Returns: Array of certain component keys
    func getCertainComponents() -> [Component] {
        return Array(knownValues.keys)
    }
    
    /// Adds a tag to this component set
    /// - Parameter tag: The tag to add
    func addTag(_ tag: String) {
        tags.insert(tag)
    }
    
    /// Checks if this component set has a specific tag
    /// - Parameter tag: The tag to check
    /// - Returns: True if the tag is present
    func hasTag(_ tag: String) -> Bool {
        return tags.contains(tag)
    }
    
    /// Calculate and return the date represented by these components
    /// - Returns: A Date object
    func date() -> Date? {
        // Check if we have ISO week values and should use those for date calculation
        if let isoWeek = get(.isoWeek), let isoWeekYear = get(.isoWeekYear),
           (isCertain(.isoWeek) || isCertain(.isoWeekYear)) {
            // When ISO week components are certain (explicitly set), we prioritize them
            // for date calculation over regular date components
            return dateFromISOWeek(week: isoWeek, year: isoWeekYear)
        }
        
        // Otherwise use regular date components
        var dateComponents = DateComponents()
        
        if let year = get(.year) {
            dateComponents.year = year
        }
        
        if let month = get(.month) {
            dateComponents.month = month
        }
        
        if let day = get(.day) {
            dateComponents.day = day
        }
        
        if let hour = get(.hour) {
            dateComponents.hour = hour
        }
        
        if let minute = get(.minute) {
            dateComponents.minute = minute
        }
        
        if let second = get(.second) {
            dateComponents.second = second
        }
        
        if let millisecond = get(.millisecond) {
            dateComponents.nanosecond = millisecond * 1_000_000
        }
        
        // TODO: Handle timezone offset
        
        return Calendar.current.date(from: dateComponents)
    }
    
    /// Convert ISO week number and year to a date (Monday of that week)
    /// - Parameters:
    ///   - week: The ISO week number (1-53)
    ///   - year: The ISO week year
    /// - Returns: Date representing the Monday of that week
    private func dateFromISOWeek(week: Int, year: Int) -> Date? {
        var calendar = Calendar(identifier: .iso8601)
        calendar.firstWeekday = 2 // Monday is the first day
        
        var components = DateComponents()
        components.weekOfYear = week
        components.yearForWeekOfYear = year
        components.weekday = 2 // Monday (2 in ISO 8601)
        
        // Add time components if available
        if let hour = get(.hour) {
            components.hour = hour
        } else {
            components.hour = 12 // Default to noon
        }
        
        if let minute = get(.minute) {
            components.minute = minute
        } else {
            components.minute = 0
        }
        
        if let second = get(.second) {
            components.second = second
        } else {
            components.second = 0
        }
        
        if let millisecond = get(.millisecond) {
            components.nanosecond = millisecond * 1_000_000
        }
        
        return calendar.date(from: components)
    }
    
    /// Creates a copy of this components object
    /// - Returns: A new ParsingComponents with the same values
    func clone() -> ParsingComponents {
        let cloned = ParsingComponents(reference: reference)
        
        // Copy known values
        for (component, value) in knownValues {
            cloned.assign(component, value: value)
        }
        
        // Copy implied values
        for (component, value) in impliedValues {
            cloned.imply(component, value: value)
        }
        
        // Copy tags
        for tag in tags {
            cloned.addTag(tag)
        }
        
        return cloned
    }
    
    /// Converts to a public date result
    /// - Returns: A public ParsedResultDate
    func toPublicDate() -> ParsedResultDate {
        // Use a safe fallback for date calculation
        let finalDate: Date
        if let calculatedDate = date() {
            finalDate = calculatedDate
        } else {
            // If date calculation fails, use reference date as fallback
            finalDate = reference.instant
        }
        
        return ParsedResultDate(
            date: finalDate,
            knownValues: knownValuesDictionary,
            impliedValues: impliedValuesDictionary
        )
    }
}