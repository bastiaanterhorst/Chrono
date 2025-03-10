import Foundation
import Chrono_swift

@main
struct ChronoSwiftApp {
    static func main() {
        print("Testing Chrono.swift")
        
        // Test all the core functionality
        runChronoCoreTest()
        runCasualDateParserTest()
        
        // Test the Spanish locale implementation
        runESCasualDateParserTest()
    }
    
    // Replicating the test from Chrono_swiftTests
    static func runChronoCoreTest() {
        print("\n=== Core Test ===")
        
        // Test the static methods
        let testDate = Date()
        let results = Chrono.parse(text: "today")
        
        print("Results count for 'today': \(results.count)")
        if !results.isEmpty {
            print("Text: \(results[0].text)")
            
            // Test date is today
            let calendar = Calendar.current
            let isToday = calendar.isDate(results[0].start.date, inSameDayAs: testDate)
            print("Is today: \(isToday)")
        }
    }
    
    static func runCasualDateParserTest() {
        print("\n=== Casual Date Parser Test ===")
        
        // Test "today"
        let testDate = Date()
        let results = Chrono.parse(text: "Let's meet today")
        
        print("Results count for 'Let's meet today': \(results.count)")
        if !results.isEmpty {
            print("Text: \(results[0].text)")
            
            let calendar = Calendar.current
            let isToday = calendar.isDate(results[0].start.date, inSameDayAs: testDate)
            print("Is today: \(isToday)")
        }
        
        // Test "tomorrow"
        let tomorrowResults = Chrono.parse(text: "I'll see you tomorrow")
        print("\nResults count for 'I'll see you tomorrow': \(tomorrowResults.count)")
        if !tomorrowResults.isEmpty {
            print("Text: \(tomorrowResults[0].text)")
            
            let calendar = Calendar.current
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: testDate) {
                let isTomorrow = calendar.isDate(tomorrowResults[0].start.date, inSameDayAs: tomorrow)
                print("Is tomorrow: \(isTomorrow)")
            }
        }
        
        // Test "yesterday"
        let yesterdayResults = Chrono.parse(text: "I saw her yesterday")
        print("\nResults count for 'I saw her yesterday': \(yesterdayResults.count)")
        if !yesterdayResults.isEmpty {
            print("Text: \(yesterdayResults[0].text)")
            
            let calendar = Calendar.current
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: testDate) {
                let isYesterday = calendar.isDate(yesterdayResults[0].start.date, inSameDayAs: yesterday)
                print("Is yesterday: \(isYesterday)")
            }
        }
    }
    
    static func runESCasualDateParserTest() {
        print("\n=== Spanish (ES) Casual Date Parser Test ===")
        
        let testDate = Date()
        let calendar = Calendar.current
        let parser = Chrono.es.casual
        
        // Test "hoy" (today)
        let hoyResults = parser.parse(text: "Nos vemos hoy", referenceDate: testDate)
        print("Results count for 'Nos vemos hoy': \(hoyResults.count)")
        if !hoyResults.isEmpty {
            print("Text: \(hoyResults[0].text)")
            let isToday = calendar.isDate(hoyResults[0].start.date, inSameDayAs: testDate)
            print("Is today: \(isToday)")
        }
        
        // Test "mañana" (tomorrow)
        let mañanaResults = parser.parse(text: "Te veré mañana", referenceDate: testDate)
        print("\nResults count for 'Te veré mañana': \(mañanaResults.count)")
        if !mañanaResults.isEmpty {
            print("Text: \(mañanaResults[0].text)")
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: testDate) {
                let isTomorrow = calendar.isDate(mañanaResults[0].start.date, inSameDayAs: tomorrow)
                print("Is tomorrow: \(isTomorrow)")
            }
        }
        
        // Test "ayer" (yesterday)
        let ayerResults = parser.parse(text: "La vi ayer", referenceDate: testDate)
        print("\nResults count for 'La vi ayer': \(ayerResults.count)")
        if !ayerResults.isEmpty {
            print("Text: \(ayerResults[0].text)")
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: testDate) {
                let isYesterday = calendar.isDate(ayerResults[0].start.date, inSameDayAs: yesterday)
                print("Is yesterday: \(isYesterday)")
            }
        }
        
        // Test weekday "lunes" (Monday)
        let lunesResults = parser.parse(text: "Nos vemos el lunes", referenceDate: testDate)
        print("\nResults count for 'Nos vemos el lunes': \(lunesResults.count)")
        if !lunesResults.isEmpty {
            print("Text: \(lunesResults[0].text)")
            let weekday = calendar.component(.weekday, from: lunesResults[0].start.date)
            print("Weekday: \(weekday)") // Should be 2 for Monday
        }
        
        // Test "mediodía" (noon)
        let mediodiaResults = parser.parse(text: "A mediodía", referenceDate: testDate)
        print("\nResults count for 'A mediodía': \(mediodiaResults.count)")
        if !mediodiaResults.isEmpty {
            print("Text: \(mediodiaResults[0].text)")
            if let hour = mediodiaResults[0].start.get(.hour) {
                print("Hour: \(hour)") // Should be 12
            }
        }
        
        // Test time expression
        let tiempoResults = parser.parse(text: "a las 3:30 PM", referenceDate: testDate)
        print("\nResults count for 'a las 3:30 PM': \(tiempoResults.count)")
        if !tiempoResults.isEmpty {
            print("Text: \(tiempoResults[0].text)")
            if let hour = tiempoResults[0].start.get(.hour),
               let minute = tiempoResults[0].start.get(.minute) {
                print("Time: \(hour):\(minute)")
            }
        }
        
        // Test time unit within expression
        let dentroResults = parser.parse(text: "dentro de 2 días", referenceDate: testDate)
        print("\nResults count for 'dentro de 2 días': \(dentroResults.count)")
        if !dentroResults.isEmpty {
            print("Text: \(dentroResults[0].text)")
            if let futureDate = calendar.date(byAdding: .day, value: 2, to: testDate) {
                let isCorrect = calendar.isDate(dentroResults[0].start.date, inSameDayAs: futureDate)
                print("Is 2 days in the future: \(isCorrect)")
            }
        }
    }
}