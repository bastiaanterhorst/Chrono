import Testing
import Foundation
@testable import Chrono

// A helper function to create a Date at a specific time
func makeDate(hour: Int, minute: Int, second: Int = 0) -> Date {
    let calendar = Calendar.current
    let now = Date()
    let components = calendar.dateComponents([.year, .month, .day], from: now)
    var dateComponents = DateComponents()
    dateComponents.year = components.year
    dateComponents.month = components.month
    dateComponents.day = components.day
    dateComponents.hour = hour
    dateComponents.minute = minute
    dateComponents.second = second
    return calendar.date(from: dateComponents) ?? now
}

/// Tests for the core Chrono functionality
@Test func chronoCoreTest() async throws {
    // Test the static methods
    let testDate = Date()
    let results = Chrono.parse(text: "today")
    
    #expect(results.count == 1)
    #expect(results[0].text == "today")
    
    // Test date is today
    let calendar = Calendar.current
    #expect(calendar.isDate(results[0].start.date, inSameDayAs: testDate))
}

/// Tests for EN casual date parser
@Test func enCasualDateParserTest() async throws {
    // Test "today"
    let testDate = Date()
    let results = Chrono.parse(text: "Let's meet today")
    
    #expect(results.count == 1)
    #expect(results[0].text == "today")
    
    let calendar = Calendar.current
    #expect(calendar.isDate(results[0].start.date, inSameDayAs: testDate))
    
    // Test "tomorrow"
    let tomorrowResults = Chrono.parse(text: "I'll see you tomorrow")
    #expect(tomorrowResults.count == 1)
    #expect(tomorrowResults[0].text == "tomorrow")
    
    if let tomorrow = calendar.date(byAdding: .day, value: 1, to: testDate) {
        #expect(calendar.isDate(tomorrowResults[0].start.date, inSameDayAs: tomorrow))
    }
    
    // Test "yesterday"
    let yesterdayResults = Chrono.parse(text: "I saw her yesterday")
    #expect(yesterdayResults.count == 1)
    #expect(yesterdayResults[0].text == "yesterday")
    
    if let yesterday = calendar.date(byAdding: .day, value: -1, to: testDate) {
        #expect(calendar.isDate(yesterdayResults[0].start.date, inSameDayAs: yesterday))
    }
}
