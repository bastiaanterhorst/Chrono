// NLTimeUnitRelativeFormatParserTests.swift - Tests for Dutch time unit relative expressions
import XCTest
@testable import Chrono

final class NLTimeUnitRelativeFormatParserTests: XCTestCase {
    // Reference date: January 1, 2025
    let refDate = Date(timeIntervalSince1970: 1735603200)
    
    func testParser() throws {
        // Create the parser directly
        let parser = NLTimeUnitRelativeFormatParser()
        
        // Test "volgende week"
        let text = "volgende week"
        let options = ParsingOptions()
        let reference = ReferenceWithTimezone(instant: refDate)
        let pattern = parser.pattern(context: ParsingContext(text: text, reference: reference, options: options))
        
        // Create a regex from the pattern
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            XCTFail("Invalid pattern")
            return
        }
        
        // Test the pattern
        let range = NSRange(location: 0, length: text.utf16.count)
        let matches = regex.matches(in: text, options: [], range: range)
        print("Pattern: \(pattern)")
        print("Matches for '\(text)': \(matches.count)")
        
        if !matches.isEmpty {
            for (i, match) in matches.enumerated() {
                print("Match \(i+1):")
                for j in 0..<match.numberOfRanges {
                    if let range = Range(match.range(at: j), in: text) {
                        print("  Capture group \(j): \(text[range])")
                    } else {
                        print("  Capture group \(j): nil")
                    }
                }
            }
        }
    }
}
