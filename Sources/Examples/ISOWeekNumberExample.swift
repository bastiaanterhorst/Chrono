// ISOWeekNumberExample.swift - Example for ISO week number parsing
import Foundation
import Chrono

/// Examples of ISO week number parsing
func isoWeekNumberExample() {
    print("\n=== ISO Week Number Parsing Examples ===\n")
    
    // Create a parser with English configuration with debug option
    let options = ParsingOptions(forwardDate: false, debug: true)
    
    // Use the standard casual configuration which now has ISO week parsing
    let chrono = EN.casual
    
    // Example 1: Basic week number - "Week 45"
    let examples = [
        "Meeting scheduled for Week 45",
        "The deadline is in Week 15 of 2023",
        "Project timeline: 2023-W15",
        "Another milestone at 2023W22",
        "Delivery expected in W15-2023",
        "Schedule the review for Week 30 '23",
        "Let's meet during the 22nd week",
        "We'll wrap up in week #37",
        "Progress check in week number 28"
    ]
    
    for example in examples {
        print("Testing: \"\(example)\"")
        let results = chrono.parse(text: example, referenceDate: Date(), options: options)
        printResults(results)
        print("-------------------------------------------\n")
    }
    
    // Relative week expressions
    print("\n=== Relative Week Expressions ===\n")
    
    let relativeExamples = [
        "Let's schedule the meeting for this week",
        "The project is due next week",
        "The report was submitted last week",
        "The problem started 3 weeks ago",
        "The launch is scheduled in 2 weeks",
        "We need to finish the work the week after next",
        "I met him the week before last",
        "Let's meet 4 weeks from now"
    ]
    
    for example in relativeExamples {
        print("Testing: \"\(example)\"")
        let results = chrono.parse(text: example, referenceDate: Date(), options: options)
        printResults(results)
        print("-------------------------------------------\n")
    }
}

// Helper function to print results
private func printResults(_ results: [ParsedResult]) {
    if results.isEmpty {
        print("No date/time information found")
    } else {
        for (index, result) in results.enumerated() {
            print("Result \(index + 1):")
            print("  Text: \"\(result.text)\"")
            print("  Date: \(result.start.date)")
            
            if let isoWeek = result.start.isoWeek, let isoWeekYear = result.start.isoWeekYear {
                print("  ISO Week: \(isoWeek) of \(isoWeekYear)")
                
                if let weekStart = result.start.isoWeekStart, let weekEnd = result.start.isoWeekEnd {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    print("  Week range: \(dateFormatter.string(from: weekStart)) to \(dateFormatter.string(from: weekEnd))")
                }
            }
            
            print("  Known values: \(result.start.knownValues)")
            print("  Implied values: \(result.start.impliedValues)")
            print("")
        }
    }
}

/// Helper function to print parsing results
private func printParseResults(chrono: Chrono, text: String) {
    print("Text: \"\(text)\"")
    
    let results = chrono.parse(text: text)
    
    if results.isEmpty {
        print("No date/time information found")
    } else {
        for (index, result) in results.enumerated() {
            print("Result \(index + 1):")
            print("  Text: \"\(result.text)\"")
            print("  Date: \(result.start.date)")
            
            if let isoWeek = result.start.isoWeek, let isoWeekYear = result.start.isoWeekYear {
                print("  ISO Week: \(isoWeek) of \(isoWeekYear)")
                
                if let weekStart = result.start.isoWeekStart, let weekEnd = result.start.isoWeekEnd {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    print("  Week range: \(dateFormatter.string(from: weekStart)) to \(dateFormatter.string(from: weekEnd))")
                }
            }
            
            print("  Known values: \(result.start.knownValues)")
            print("  Implied values: \(result.start.impliedValues)")
            print("")
        }
    }
    
    print("-------------------------------------------\n")
}