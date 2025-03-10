// ParsingOptionsExample.swift - Demonstrating parsing options in Chrono.swift
import Foundation
import Chrono_swift

/// Example showing how to use parsing options with Chrono.swift
struct ParsingOptionsExample {
    static func run() {
        print("Chrono.swift Parsing Options Examples")
        print("====================================\n")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        // Example 1: Enabling debug output
        let example1 = "Meet tomorrow at 3pm"
        print("Example 1: Debug Output")
        print("Text: \"\(example1)\"")
        
        // Create debugging options
        var debugOptions = ParsingOptions()
        debugOptions.debug = true
        
        print("Parsing with debug enabled:")
        let results1 = Chrono.parse(text: example1, options: debugOptions)
        printResults(results1)
        
        // Example 2: Setting a forward date boundary
        let example2 = "Let's meet on January 15"
        print("\nExample 2: Forward Date Boundary")
        print("Text: \"\(example2)\"")
        
        // Create options with a forward date boundary
        var forwardOptions = ParsingOptions()
        forwardOptions.forwardDate = true
        
        // Use a fixed reference date for consistency
        let referenceDate = Date(timeIntervalSince1970: 1735603200) // January 1, 2025
        
        print("Reference date: \(dateFormatter.string(from: referenceDate))")
        print("Normal parsing (without forward date):")
        let normalResults2 = Chrono.parse(text: example2, referenceDate: referenceDate)
        printResults(normalResults2)
        
        print("With forward date option:")
        let forwardResults2 = Chrono.parse(text: example2, referenceDate: referenceDate, options: forwardOptions)
        printResults(forwardResults2)
        
        // Example 3: Setting custom timezone mappings
        let example3 = "Meeting is at 9am EDT tomorrow"
        print("\nExample 3: Custom Timezone Handling")
        print("Text: \"\(example3)\"")
        
        // Create options with different timezone mappings
        var defaultOptions = ParsingOptions()
        
        var customTimezoneOptions = ParsingOptions(
            timezones: [
                "EDT": -4 * 60, // Eastern Daylight Time (UTC-4)
                "EST": -5 * 60, // Eastern Standard Time (UTC-5)
                "PDT": -7 * 60, // Pacific Daylight Time (UTC-7)
                "PST": -8 * 60  // Pacific Standard Time (UTC-8)
            ]
        )
        
        print("Default timezone handling:")
        let defaultResults = Chrono.parse(text: example3, referenceDate: referenceDate, options: defaultOptions)
        printResults(defaultResults)
        
        print("Custom timezone mappings:")
        let customResults = Chrono.parse(text: example3, referenceDate: referenceDate, options: customTimezoneOptions)
        printResults(customResults)
        
        // Example 4: Using reference dates with different timezones
        let example4 = "Let's meet next Monday"
        print("\nExample 4: Reference Dates with Timezones")
        print("Text: \"\(example4)\"")
        
        // Create references with different timezones
        let utcReference = ParsingReference(instant: referenceDate, timezone: 0) // UTC
        let estReference = ParsingReference(instant: referenceDate, timezone: -5 * 60) // EST (UTC-5)
        
        print("UTC reference timezone:")
        let utcResults = Chrono.parse(text: example4, referenceDate: utcReference)
        printResults(utcResults)
        
        print("EST reference timezone:")
        let estResults = Chrono.parse(text: example4, referenceDate: estReference)
        printResults(estResults)
        
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
            print("    Date: \(dateFormatter.string(from: result.start.date))")
            
            if let endDate = result.end?.date {
                print("    End date: \(dateFormatter.string(from: endDate))")
            }
            
            print("")
        }
    }
}