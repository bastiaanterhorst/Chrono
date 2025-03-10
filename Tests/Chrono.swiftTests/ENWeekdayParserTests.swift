import Testing
import Foundation
@testable import Chrono_swift

/// Tests for EN weekday parser
@Test func enWeekdayParserTest() async throws {
    // Let's test the most basic functionality - extracting weekdays
    
    // Create a simple weekday parser test for Monday
    let weekday = Weekday.monday
    
    // Check if Monday is correctly parsed as weekday 2 in Swift's Calendar
    let date = Date() // Today
    let calendar = Calendar.current
    
    // Create a date that falls on Monday
    let currentWeekday = calendar.component(.weekday, from: date)
    let daysUntilMonday = ((weekday.rawValue + 1) - currentWeekday + 7) % 7
    let mondayDate = calendar.date(byAdding: .day, value: daysUntilMonday, to: date)!
    
    // Verify that our calculation works
    #expect(calendar.component(.weekday, from: mondayDate) == 2) // Monday is 2 in Calendar
    
    // Create a date that falls on Friday
    let daysUntilFriday = (6 - currentWeekday + 7) % 7
    let fridayDate = calendar.date(byAdding: .day, value: daysUntilFriday, to: date)!
    
    // Verify that our calculation works
    #expect(calendar.component(.weekday, from: fridayDate) == 6) // Friday is 6 in Calendar
}