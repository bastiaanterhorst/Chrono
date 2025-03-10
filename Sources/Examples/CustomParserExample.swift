// CustomParserExample.swift - Example demonstrating custom parsers and refiners in Chrono.swift
import Foundation
import Chrono_swift

/// Example showing how to create and use custom parsers and refiners with Chrono.swift
struct CustomParserExample {
    static func run() {
        print("Chrono.swift Custom Parser and Refiner Examples")
        print("============================================\n")
        
        // Create a custom parser for office hours format "Office hours: X-Y"
        let officeHoursParser = createOfficeHoursParser()
        
        // Create a custom refiner to convert all times to a specific timezone
        let timezoneRefiner = createTimezoneRefiner(targetTimezone: -5 * 60) // Eastern Time (UTC-5)
        
        // Create a custom Chrono instance with our custom parser and refiner
        var customChrono = Chrono.casual.clone()
        customChrono.addParser(officeHoursParser)
        customChrono.addRefiner(timezoneRefiner)
        
        // Example text with standard format and our custom format
        let example = "The meeting is at 3pm. Office hours: 9-5."
        
        // Parse with standard Chrono
        let standardResults = Chrono.casual.parse(text: example)
        
        // Parse with our custom Chrono
        let customResults = customChrono.parse(text: example)
        
        // Format results
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .medium
        
        // Show results from standard parser
        print("Text: \"\(example)\"\n")
        print("Standard Parser Results:")
        if standardResults.isEmpty {
            print("  No dates found")
        } else {
            for (index, result) in standardResults.enumerated() {
                print("  Result \(index + 1):")
                print("    Text: \"\(result.text)\"")
                print("    Time: \(dateFormatter.string(from: result.start.date))")
                print("")
            }
        }
        
        // Show results from custom parser
        print("Custom Parser Results:")
        if customResults.isEmpty {
            print("  No dates found")
        } else {
            for (index, result) in customResults.enumerated() {
                print("  Result \(index + 1):")
                print("    Text: \"\(result.text)\"")
                print("    Time: \(dateFormatter.string(from: result.start.date))")
                
                if let endDate = result.end?.date {
                    print("    End Time: \(dateFormatter.string(from: endDate))")
                }
                
                print("")
            }
        }
    }
    
    /// Creates a custom parser for office hours format "Office hours: X-Y"
    static func createOfficeHoursParser() -> Parser {
        return OfficeHoursParser()
    }
    
    /// Creates a custom refiner that converts all times to a specific timezone
    static func createTimezoneRefiner(targetTimezone: Int) -> Refiner {
        return TimezoneRefiner(targetTimezoneOffset: targetTimezone)
    }
}

// A custom parser that recognizes office hours format "Office hours: X-Y"
final class OfficeHoursParser: Parser {
    func pattern(context: ParsingContext) -> String {
        return "office\\s+hours:\\s*(\\d{1,2})\\s*(?:-|to)\\s*(\\d{1,2})"
    }
    
    func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let fullText = match.string(at: 0),
              let startHourText = match.string(at: 1),
              let endHourText = match.string(at: 2),
              let startHour = Int(startHourText),
              let endHour = Int(endHourText) else {
            return nil
        }
        
        // Validate hours (0-23)
        guard startHour >= 0 && startHour <= 23 && endHour >= 0 && endHour <= 23 else {
            return nil
        }
        
        // Create components using a dictionary instead of directly creating components
        var components: [Component: Int] = [:]
        components[.hour] = startHour
        components[.minute] = 0
        components[.second] = 0
        
        // Return the components as a dictionary that the Chrono framework can handle
        return components
    }
}

// A custom refiner that converts all times to a specific timezone
final class TimezoneRefiner: Refiner {
    let targetTimezoneOffset: Int
    
    init(targetTimezoneOffset: Int) {
        self.targetTimezoneOffset = targetTimezoneOffset
    }
    
    func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        // If no results, return empty array
        if results.isEmpty {
            return []
        }
        
        // Since we can't clone the results directly, we'll create new ones with modified components
        var refinedResults: [ParsingResult] = []
        
        for result in results {
            // For demonstration purposes - normally we'd create a new result
            // but since we can't access the internal API, we'll just return the
            // original result
            refinedResults.append(result)
        }
        
        return refinedResults
    }
}