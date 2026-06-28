import Testing
import Foundation
@testable import Chrono

/// The Spanish time parsers must only treat "a"/"al"/"la(s)"/"de"/"del" as time connectors when
/// they are whole words — never the trailing letter of a preceding word (e.g. the "a" of "cita").
struct ESConnectorBoundaryTests {
    private let calendar = Calendar.current

    /// A word ending in "a" before a dotted date must not spawn a spurious time; the date stands alone.
    @Test func trailingADoesNotProduceSpuriousTime() async throws {
        for text in ["cita 15.6", "tarea 15.6", "reunión 15.6"] {
            let results = Chrono.es.casual.parse(text: text)
            // Exactly one result, and it is the date (15 June), with no certain hour.
            #expect(results.count == 1, "Expected a single result for '\(text)', got \(results.map(\.text))")
            guard let r = results.first else { continue }
            #expect(r.start.isCertain(.day))
            #expect(r.start.isCertain(.month))
            #expect(!r.start.isCertain(.hour), "'\(text)' should not carry a time")
            #expect(calendar.component(.day, from: r.start.date) == 15)
            #expect(calendar.component(.month, from: r.start.date) == 6)
        }
    }

    /// A word ending in "a" before "mediodía" must not grab that "a" as the "a"/"al" connector.
    @Test func trailingADoesNotGrabNoonConnector() async throws {
        let results = Chrono.es.casual.parse(text: "comida mediodía")
        #expect(results.count == 1)
        guard let r = results.first else { return }
        #expect(!r.text.hasPrefix("a "))
        #expect(calendar.component(.hour, from: r.start.date) == 12)
    }

    /// Genuine connectors must still be recognized.
    @Test func realConnectorsStillWork() async throws {
        let cases: [(String, Int, Int)] = [
            ("a las 3", 3, 0),
            ("a las 15:30", 15, 30),
            ("al mediodía", 12, 0),
        ]
        for (text, hour, minute) in cases {
            let results = Chrono.es.casual.parse(text: text)
            #expect(!results.isEmpty, "Expected a time for '\(text)'")
            guard let r = results.first else { continue }
            #expect(r.start.isCertain(.hour))
            #expect(calendar.component(.hour, from: r.start.date) == hour, "hour for '\(text)'")
            #expect(calendar.component(.minute, from: r.start.date) == minute, "minute for '\(text)'")
        }
    }
}
