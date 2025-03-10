// AdvancedDateRangeExample.swift - Examples of advanced date range parsing with Chrono.swift
import Foundation
import Chrono_swift

/// Example showing advanced date range parsing capabilities of Chrono.swift
struct AdvancedDateRangeExample {
    static func run() {
        print("Chrono.swift Advanced Date Range Examples")
        print("=======================================\n")
        
        // Set up date formatters
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.dateStyle = .long
        dateOnlyFormatter.timeStyle = .none
        
        let timeOnlyFormatter = DateFormatter()
        timeOnlyFormatter.dateStyle = .none
        timeOnlyFormatter.timeStyle = .medium
        
        let referenceDate = Date(timeIntervalSince1970: 1735603200) // January 1, 2025
        
        // Example 1: Explicit date range with "to" or "-"
        let example1 = "The event runs from January 15, 2025 to January 20, 2025"
        print("Example 1: Explicit Date Range")
        print("Text: \"\(example1)\"")
        
        let results1 = Chrono.parse(text: example1)
        printRangeResults(results1, dateFormatter: dateOnlyFormatter)
        
        // Example 2: Implicit date range with start and end times
        let example2 = "The meeting is from 10am to 12pm tomorrow"
        print("\nExample 2: Time Range on a Single Day")
        print("Text: \"\(example2)\"")
        
        let results2 = Chrono.parse(text: example2, referenceDate: referenceDate)
        printRangeResults(results2, dateFormatter: dateFormatter)
        
        // Example 3: Complex date range with abbreviated months
        let example3 = "Conference from Feb 15 - Mar 15, 2025"
        print("\nExample 3: Date Range with Abbreviated Months")
        print("Text: \"\(example3)\"")
        
        let results3 = Chrono.parse(text: example3)
        printRangeResults(results3, dateFormatter: dateOnlyFormatter)
        
        // Example 4: Date range with weekdays
        let example4 = "Available Monday through Friday next week"
        print("\nExample 4: Weekday Range")
        print("Text: \"\(example4)\"")
        
        let results4 = Chrono.parse(text: example4, referenceDate: referenceDate)
        printRangeResults(results4, dateFormatter: dateOnlyFormatter)
        
        // Example 5: Business quarters
        let example5 = "Q1 2025 projections"
        print("\nExample 5: Business Quarters")
        print("Text: \"\(example5)\"")
        
        let results5 = Chrono.parse(text: example5)
        printRangeResults(results5, dateFormatter: dateOnlyFormatter)
        
        // Example 6: Date range with explicit time on end
        let example6 = "Event from January 15 to January 16 at 3pm"
        print("\nExample 6: Date Range with End Time")
        print("Text: \"\(example6)\"")
        
        let results6 = Chrono.parse(text: example6, referenceDate: referenceDate)
        printRangeResults(results6, dateFormatter: dateFormatter)
        
        // Example 7: Calculate duration of a date range
        let example7 = "Vacation from June 1 to June 15, 2025"
        print("\nExample 7: Calculating Duration")
        print("Text: \"\(example7)\"")
        
        let results7 = Chrono.parse(text: example7)
        if let result = results7.first, let endDate = result.end?.date {
            let duration = Calendar.current.dateComponents([.day], from: result.start.date, to: endDate)
            
            print("  Start: \(dateOnlyFormatter.string(from: result.start.date))")
            print("  End: \(dateOnlyFormatter.string(from: endDate))")
            print("  Duration: \(duration.day ?? 0) days")
        } else {
            print("  No date range found")
        }
    }
    
    /// Helper function to print date range results
    static func printRangeResults(_ results: [ParsedResult], dateFormatter: DateFormatter) {
        if results.isEmpty {
            print("  No date ranges found")
            return
        }
        
        for (index, result) in results.enumerated() {
            print("  Result \(index + 1):")
            print("    Text: \"\(result.text)\"")
            print("    Start: \(dateFormatter.string(from: result.start.date))")
            
            if let endDate = result.end?.date {
                print("    End: \(dateFormatter.string(from: endDate))")
                
                // Calculate duration in days
                let duration = Calendar.current.dateComponents([.day, .hour, .minute], from: result.start.date, to: endDate)
                var durationStr = ""
                
                if let days = duration.day, days > 0 {
                    durationStr += "\(days) day\(days > 1 ? "s" : "")"
                }
                
                if let hours = duration.hour, hours > 0 {
                    if !durationStr.isEmpty {
                        durationStr += ", "
                    }
                    durationStr += "\(hours) hour\(hours > 1 ? "s" : "")"
                }
                
                if let minutes = duration.minute, minutes > 0 {
                    if !durationStr.isEmpty {
                        durationStr += ", "
                    }
                    durationStr += "\(minutes) minute\(minutes > 1 ? "s" : "")"
                }
                
                if !durationStr.isEmpty {
                    print("    Duration: \(durationStr)")
                }
            } else {
                print("    Note: This is a single date/time, not a range")
            }
            
            print("")
        }
    }
}