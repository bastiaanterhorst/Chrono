import Testing
import Foundation
@testable import Chrono_swift

@Test func simpleISOTest() async {
    // Test basic ISO format (YYYY-MM-DD)
    let results = Chrono.parse(text: "Meeting on 2023-01-15")
    
    #expect(results.count > 0)
    #expect(results[0].text.trimmingCharacters(in: .whitespaces) == "2023-01-15")
}