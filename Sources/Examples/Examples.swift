// Examples.swift - Main entry point for Chrono examples
import Foundation
import Chrono

/// Main entry point for running examples
@main
struct ExamplesRunner {
    static func main() {
        if CommandLine.arguments.contains("--quick-week-check") {
            QuickWeekCheckExample.run()
            return
        }

        print("Chrono Examples")
        print("===============\n")
        
        print("Select an example to run:")
        print("1. Basic Date Parsing")
        print("2. Multi-Locale Date Parsing")
        print("3. Parsing Options")
        print("4. Advanced Date Range Handling")
        print("5. Custom Parsers and Refiners")
        print("6. ISO Week Number Parsing")
        print("7. Run All Examples")
        print("8. Quick Week Check")
        print("9. Exit")
        
        print("\nEnter your choice (1-9): ", terminator: "")
        if let choice = readLine() {
            switch choice {
            case "1":
                BasicDateParsingExample.run()
            case "2":
                MultiLocaleExample.run()
            case "3":
                ParsingOptionsExample.run()
            case "4":
                AdvancedDateRangeExample.run()
            case "5":
                CustomParserExample.run()
            case "6":
                isoWeekNumberExample()
            case "7":
                runAllExamples()
            case "8":
                QuickWeekCheckExample.run()
            case "9":
                print("Exiting...")
            default:
                print("Invalid choice. Exiting...")
            }
        }
    }
    
    private static func runAllExamples() {
        print("\n\n")
        print("==============================================")
        print("Running Basic Date Parsing Examples...")
        print("==============================================")
        BasicDateParsingExample.run()
        
        print("\n\n")
        print("==============================================")
        print("Running Multi-Locale Date Parsing Examples...")
        print("==============================================")
        MultiLocaleExample.run()
        
        print("\n\n")
        print("==============================================")
        print("Running Parsing Options Examples...")
        print("==============================================")
        ParsingOptionsExample.run()
        
        print("\n\n")
        print("==============================================")
        print("Running Advanced Date Range Examples...")
        print("==============================================")
        AdvancedDateRangeExample.run()
        
        print("\n\n")
        print("==============================================")
        print("Running Custom Parsers and Refiners Examples...")
        print("==============================================")
        CustomParserExample.run()
        
        print("\n\n")
        print("==============================================")
        print("Running ISO Week Number Parsing Examples...")
        print("==============================================")
        isoWeekNumberExample()
    }
}
