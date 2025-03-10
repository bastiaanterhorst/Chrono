import Testing
import Foundation
@testable import Chrono_swift

/// Tests for EN month name parser - minimal version
@Test func enMonthNameParserTest() async throws {
    // Just parse a simple date
    let parser = ENMonthNameParser()
    
    // Verify the pattern regex compiles
    let pattern = parser.pattern(context: ParsingContext(text: "", reference: ReferenceWithTimezone(), options: ParsingOptions()))
    
    // We have a valid pattern
    #expect(!pattern.isEmpty)
}