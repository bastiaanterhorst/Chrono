// ISOWeekNumberExample.swift - Example for ISO week number parsing
import Foundation
import Chrono

/// Examples of ISO week number parsing
func isoWeekNumberExample() {
    print("\n=== ISO Week Number Parsing Examples ===\n")
    
    // Create a parser with English configuration
    let chrono = Chrono.english()
    
    // Example 1: Basic week number - "Week 45"
    let example1 = "Meeting scheduled for Week 45"
    printParseResults(chrono: chrono, text: example1)
    
    // Example 2: Week number with year - "Week 15 2023"
    let example2 = "The deadline is in Week 15 2023"
    printParseResults(chrono: chrono, text: example2)
    
    // Example 3: ISO format - "2023-W15"
    let example3 = "Project timeline: 2023-W15 to 2023-W22"
    printParseResults(chrono: chrono, text: example3)
    
    // Example 4: Alternative ISO format - "W15-2023"
    let example4 = "Delivery expected in W15-2023"
    printParseResults(chrono: chrono, text: example4)
    
    // Example 5: Week number with abbreviated year - "Week 30 '23"
    let example5 = "Schedule the review for Week 30 '23"
    printParseResults(chrono: chrono, text: example5)
    
    // Example 6: Conversational format - "the 22nd week"
    let example6 = "Let's meet during the 22nd week"
    printParseResults(chrono: chrono, text: example6)
    
    // Example 7: Relative week expressions
    print("\n=== Relative Week Expressions ===\n")
    
    // This week
    let example7 = "Let's schedule the meeting for this week"
    printParseResults(chrono: chrono, text: example7)
    
    // Next week
    let example8 = "The project is due next week"
    printParseResults(chrono: chrono, text: example8)
    
    // Last week
    let example9 = "The report was submitted last week"
    printParseResults(chrono: chrono, text: example9)
    
    // N weeks ago
    let example10 = "The problem started 3 weeks ago"
    printParseResults(chrono: chrono, text: example10)
    
    // In N weeks
    let example11 = "The launch is scheduled in 2 weeks"
    printParseResults(chrono: chrono, text: example11)
    
    // Complex relative expressions
    let example12 = "We need to finish the work the week after next"
    printParseResults(chrono: chrono, text: example12)
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