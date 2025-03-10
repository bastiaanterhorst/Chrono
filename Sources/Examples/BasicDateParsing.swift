// BasicDateParsing.swift - Examples of basic date parsing with Chrono.swift
import Foundation
import Chrono

/// Example showing basic date parsing capabilities of Chrono.swift
struct BasicDateParsingExample {
    static func run() {
        print("Chrono.swift Basic Date Parsing Examples")
        print("=======================================\n")
        
        // Example 1: Parse a simple date using the default parser
        let example1 = "Let's meet tomorrow at 2pm"
        let results1 = Chrono.parse(text: example1)
        
        print("Example 1: \"\(example1)\"")
        printResults(results1)
        
        // Example 2: Parse a date with reference date
        let example2 = "Let's meet next Friday"
        let referenceDate = Date(timeIntervalSince1970: 1735603200) // January 1, 2025
        let results2 = Chrono.parse(text: example2, referenceDate: referenceDate)
        
        print("\nExample 2: \"\(example2)\" (with reference date Jan 1, 2025)")
        printResults(results2)
        
        // Example 3: Parse a date range
        let example3 = "The conference runs from March 15 to March 20, 2025"
        let results3 = Chrono.parse(text: example3)
        
        print("\nExample 3: \"\(example3)\"")
        printResults(results3)
        
        // Example 4: Parse a relative time
        let example4 = "The deadline is in 3 days"
        let results4 = Chrono.parse(text: example4)
        
        print("\nExample 4: \"\(example4)\"")
        printResults(results4)
        
        // Example 5: Parse multiple dates in a single text
        let example5 = "The store opens at 9am and closes at 9pm"
        let results5 = Chrono.parse(text: example5)
        
        print("\nExample 5: \"\(example5)\"")
        printResults(results5)
        
        // Example 6: Parse a date directly to get a Date object
        let example6 = "Meeting on January 15, 2025"
        if let date6 = Chrono.parseDate(text: example6) {
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            formatter.timeStyle = .short
            
            print("\nExample 6: \"\(example6)\"")
            print("Parsed date: \(formatter.string(from: date6))")
        }
        
        // Example 7: Parse with strict mode (formal formats only)
        let example7 = "The event is on 2025-03-15 at 14:30"
        let casualResults7 = Chrono.casual.parse(text: example7)
        let strictResults7 = Chrono.strict.parse(text: example7)
        
        print("\nExample 7: \"\(example7)\"")
        print("Casual mode results:")
        printResults(casualResults7)
        print("Strict mode results:")
        printResults(strictResults7)
    }
    
    /// Helper function to print parsed results
    static func printResults(_ results: [ParsedResult]) {
        if results.isEmpty {
            print("  No dates found")
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        for (index, result) in results.enumerated() {
            print("  Result \(index + 1):")
            print("    Text: \"\(result.text)\"")
            print("    Start date: \(dateFormatter.string(from: result.start.date))")
            
            if let endDate = result.end?.date {
                print("    End date: \(dateFormatter.string(from: endDate))")
            }
            
            // Print known values (explicitly found in text)
            if !result.start.knownValues.isEmpty {
                let knownComponents = result.start.knownValues.map { 
                    "\($0.key.rawValue): \($0.value)" 
                }.joined(separator: ", ")
                print("    Known components: \(knownComponents)")
            }
            
            print("")
        }
    }
}
