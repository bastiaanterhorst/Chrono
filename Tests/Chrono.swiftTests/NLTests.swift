import Testing
import Foundation
@testable import Chrono_swift

/// Simple test for Dutch namespace - using English implementation for now
@Test func nlTemporaryImplementationTest() async throws {
    // This test verifies that the Dutch locale is currently mapped to English
    let results = Chrono.nl.casual.parse(text: "tomorrow at 3pm")
    #expect(results.count > 0)
}