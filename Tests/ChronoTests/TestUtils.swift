// TestUtils.swift - Common utilities for testing
import Foundation
@testable import Chrono

/// Creates a test date with the given components
/// - Parameters:
///   - year: The year
///   - month: The month (1-12)
///   - day: The day of month
///   - hour: The hour (0-23)
///   - minute: The minute (0-59)
///   - second: The second (0-59)
/// - Returns: A Date object with the specified components
func makeTestDate(year: Int, month: Int, day: Int, hour: Int = 12, minute: Int = 0, second: Int = 0) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    components.second = second
    
    return Calendar.current.date(from: components) ?? Date()
}
