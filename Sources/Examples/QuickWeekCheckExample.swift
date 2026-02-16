// QuickWeekCheckExample.swift - Minimal runtime check for week parsing
import Foundation
import Chrono

/// Runs a minimal check to verify that "this week" parses correctly outside XCTest.
struct QuickWeekCheckExample {
    static func run() {
        let isoCalendar = Calendar(identifier: .iso8601)
        let formatter = ISO8601DateFormatter()

        guard let referenceDate = formatter.date(from: "2025-01-15T12:00:00Z") else {
            print("Failed to create reference date")
            return
        }

        let text = "this week"
        let results = Chrono.casual.parse(text: text, referenceDate: referenceDate)
        let expectedWeek = isoCalendar.component(.weekOfYear, from: referenceDate)
        let expectedWeekYear = isoCalendar.component(.yearForWeekOfYear, from: referenceDate)

        print("=== Quick Week Check ===")
        print("Reference date: \(formatter.string(from: referenceDate))")
        print("Input: \"\(text)\"")
        print("Expected ISO week: \(expectedWeek), year: \(expectedWeekYear)")
        print("Matches found: \(results.count)")

        guard let first = results.first else {
            print("Result: FAIL (no parse result)")
            return
        }

        let parsedWeek = first.start.get(.isoWeek)
        let parsedWeekYear = first.start.get(.isoWeekYear)
        let parsedDate = formatter.string(from: first.start.date)
        let passed = parsedWeek == expectedWeek && parsedWeekYear == expectedWeekYear

        print("Parsed text: \"\(first.text)\"")
        print("Parsed date: \(parsedDate)")
        print("Parsed ISO week: \(parsedWeek ?? -1), year: \(parsedWeekYear ?? -1)")
        print("Result: \(passed ? "PASS" : "FAIL")")
    }
}
