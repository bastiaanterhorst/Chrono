// FRParserTests.swift - Tests for French parsers
import Testing
import Foundation
@testable import Chrono_swift

/// Tests for French casual date parser
@Test func frCasualDateParserTest() async throws {
    // Reference date: August 10, 2012
    let refDate = makeTestDate(year: 2012, month: 8, day: 10)
    
    // Test "aujourd'hui" (Today)
    let todayResults = Chrono.fr.casual.parse(text: "Rendez-vous aujourd'hui", referenceDate: refDate)
    #expect(todayResults.count == 1)
    #expect(todayResults[0].text == "aujourd'hui")
    
    let calendar = Calendar.current
    #expect(calendar.isDate(todayResults[0].start.date, inSameDayAs: refDate))
    
    // Test "demain" (Tomorrow)
    let tomorrowResults = Chrono.fr.casual.parse(text: "Je te verrai demain", referenceDate: refDate)
    #expect(tomorrowResults.count == 1)
    #expect(tomorrowResults[0].text == "demain")
    
    if let tomorrow = calendar.date(byAdding: .day, value: 1, to: refDate) {
        #expect(calendar.isDate(tomorrowResults[0].start.date, inSameDayAs: tomorrow))
    }
    
    // Test "hier" (Yesterday)
    let yesterdayResults = Chrono.fr.casual.parse(text: "Je l'ai vu hier", referenceDate: refDate)
    #expect(yesterdayResults.count == 1)
    #expect(yesterdayResults[0].text == "hier")
    
    if let yesterday = calendar.date(byAdding: .day, value: -1, to: refDate) {
        #expect(calendar.isDate(yesterdayResults[0].start.date, inSameDayAs: yesterday))
    }
    
    // Test "ce soir" (This evening)
    let eveningResults = Chrono.fr.casual.parse(text: "On dîne ce soir", referenceDate: refDate)
    #expect(eveningResults.count == 1)
    #expect(eveningResults[0].text == "ce soir")
    
    let eveningComponents = calendar.dateComponents([.hour, .minute], from: eveningResults[0].start.date)
    #expect(eveningComponents.hour == 20)
    #expect(eveningComponents.minute == 0)
}

/// Tests for French time expression parser
@Test func frTimeExpressionParserTest() async throws {
    // Reference date: August 10, 2012
    let refDate = makeTestDate(year: 2012, month: 8, day: 10)
    
    // Test each expression with its own parser to avoid conflicts
    let parser1 = Chrono.fr.casual.clone()
    
    // Test "15h30" (15:30)
    let timeResults = parser1.parse(text: "Rendez-vous à 15h30", referenceDate: refDate)
    #expect(timeResults.count == 1)
    #expect(timeResults[0].text == "à 15h30")
    
    let calendar = Calendar.current
    let timeComponents = calendar.dateComponents([.hour, .minute], from: timeResults[0].start.date)
    #expect(timeComponents.hour == 15)
    #expect(timeComponents.minute == 30)
    
    // Test "midi" (noon) with a separate parser
    let parser2 = Chrono.fr.casual.clone()
    let noonResults = parser2.parse(text: "Rendez-vous à midi", referenceDate: refDate)
    #expect(noonResults.count == 1)
    #expect(noonResults[0].text == "à midi")
    
    let noonComponents = calendar.dateComponents([.hour, .minute], from: noonResults[0].start.date)
    #expect(noonComponents.hour == 12)
    #expect(noonComponents.minute == 0)
    
    // Test "8h du matin" (8 AM) with a separate parser
    let parser3 = Chrono.fr.casual.clone()
    let morningResults = parser3.parse(text: "Rendez-vous à 8h du matin", referenceDate: refDate)
    #expect(morningResults.count == 1)
    #expect(morningResults[0].text == "à 8h du matin")
    
    let morningComponents = calendar.dateComponents([.hour, .minute], from: morningResults[0].start.date)
    #expect(morningComponents.hour == 8)
    #expect(morningComponents.minute == 0)
}

/// Tests for French weekday parser
@Test func frWeekdayParserTest() async throws {
    // Reference date: Thursday, August 9, 2012
    let refDate = makeTestDate(year: 2012, month: 8, day: 9) // A Thursday
    
    // Test "lundi" (Monday)
    let mondayResults = Chrono.fr.casual.parse(text: "Rendez-vous lundi", referenceDate: refDate)
    #expect(mondayResults.count == 1)
    #expect(mondayResults[0].text == "lundi")
    
    let mondayDate = makeTestDate(year: 2012, month: 8, day: 13) // Next Monday
    let calendar = Calendar.current
    #expect(calendar.isDate(mondayResults[0].start.date, inSameDayAs: mondayDate))
    
    // Test "lundi prochain" (Next Monday)
    let nextMondayResults = Chrono.fr.casual.parse(text: "Rendez-vous lundi prochain", referenceDate: refDate)
    #expect(nextMondayResults.count == 1)
    #expect(nextMondayResults[0].text == "lundi prochain")
    
    let nextMondayDate = makeTestDate(year: 2012, month: 8, day: 20) // Monday after next
    #expect(calendar.isDate(nextMondayResults[0].start.date, inSameDayAs: nextMondayDate))
}

/// Tests for French date-time merging
@Test func frMergeDateTimeTest() async throws {
    // Reference date: August 10, 2012
    let refDate = makeTestDate(year: 2012, month: 8, day: 10)
    
    // Test "lundi à 15h30" (Monday at 15:30)
    let dateTimeResults = Chrono.fr.casual.parse(text: "Rendez-vous lundi à 15h30", referenceDate: refDate)
    #expect(dateTimeResults.count == 1)
    #expect(dateTimeResults[0].text == "lundi à 15h30")
    
    let mondayDate = makeTestDate(year: 2012, month: 8, day: 13)
    let calendar = Calendar.current
    #expect(calendar.isDate(dateTimeResults[0].start.date, inSameDayAs: mondayDate))
    
    let timeComponents = calendar.dateComponents([.hour, .minute], from: dateTimeResults[0].start.date)
    #expect(timeComponents.hour == 15)
    #expect(timeComponents.minute == 30)
}

/// Tests for French date range handling
@Test func frDateRangeTest() async throws {
    // Reference date: August 10, 2012
    let refDate = makeTestDate(year: 2012, month: 8, day: 10)
    
    // Create a parser with month name patterns (to be implemented)
    // Test "du 10 au 15 août"
    let rangeResults = Chrono.fr.casual.parse(text: "Vacances du lundi au vendredi", referenceDate: refDate)
    #expect(rangeResults.count == 1)
    #expect(rangeResults[0].text == "lundi - vendredi")
    
    // Check start date (Monday)
    let startDate = makeTestDate(year: 2012, month: 8, day: 13)
    let calendar = Calendar.current
    #expect(calendar.isDate(rangeResults[0].start.date, inSameDayAs: startDate))
    
    // Check end date (Friday)
    let endDate = makeTestDate(year: 2012, month: 8, day: 17)
    #expect(calendar.isDate(rangeResults[0].end!.date, inSameDayAs: endDate))
}