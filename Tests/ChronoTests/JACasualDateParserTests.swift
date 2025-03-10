import Testing
import Foundation
@testable import Chrono

/// Tests for JA casual date parser
@Test func jaCasualDateParserTest() async throws {
    // Test "今日" (today)
    let testDate = Date()
    let results1 = Chrono.ja.casual.parse(text: "今日の会議")
    
    #expect(results1.count == 1)
    #expect(results1[0].text == "今日")
    
    let calendar = Calendar.current
    #expect(calendar.isDate(results1[0].start.date, inSameDayAs: testDate))
    
    // Test "明日" (tomorrow)
    let results2 = Chrono.ja.casual.parse(text: "明日の予定")
    
    #expect(results2.count == 1)
    #expect(results2[0].text == "明日")
    
    if let tomorrow = calendar.date(byAdding: .day, value: 1, to: testDate) {
        #expect(calendar.isDate(results2[0].start.date, inSameDayAs: tomorrow))
    }
    
    // Test "昨日" (yesterday)
    let results3 = Chrono.ja.casual.parse(text: "昨日の出来事")
    
    #expect(results3.count == 1)
    #expect(results3[0].text == "昨日")
    
    if let yesterday = calendar.date(byAdding: .day, value: -1, to: testDate) {
        #expect(calendar.isDate(results3[0].start.date, inSameDayAs: yesterday))
    }
}
