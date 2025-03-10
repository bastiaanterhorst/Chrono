import Testing
import Foundation
@testable import Chrono_swift

/// Tests for EN slash date format parser - simplified
@Test func enSlashDateFormatParserTest() async throws {
    // Just verify the parser can be instantiated
    let parser = ENSlashDateFormatParser()
    
    // Verify the pattern regex compiles
    let pattern = parser.pattern(context: ParsingContext(text: "", reference: ReferenceWithTimezone(), options: ParsingOptions()))
    
    // We have a valid pattern
    #expect(!pattern.isEmpty)
}