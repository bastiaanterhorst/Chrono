import Testing
import Foundation
@testable import Chrono

/// Cross-locale coverage for dotted numeric dates (e.g. "15.6", "6.15").
///
/// Users write dates with dots — `dd.mm` in most European locales, `mm.dd` in English. These must
/// be parsed as dates, not times. Genuine times (where the second part can't be a month, e.g.
/// "15.30") must still parse as times.
struct DottedNumericDateTests {
    private let calendar = Calendar.current

    private func firstDate(_ chrono: Chrono, _ text: String) -> (day: Int, month: Int, isDate: Bool)? {
        let results = chrono.parse(text: text)
        guard let r = results.first(where: { $0.start.isCertain(.day) && $0.start.isCertain(.month) }) else {
            return nil
        }
        let d = r.start.date
        return (calendar.component(.day, from: d), calendar.component(.month, from: d), true)
    }

    // MARK: Little-endian locales (day.month)

    @Test func frenchDottedDate() async throws {
        for text in ["15.6", "15.06", "15/6", "rendezvous 15.6"] {
            let r = firstDate(Chrono.fr.casual, text)
            #expect(r?.isDate == true, "Expected FR '\(text)' to be a date")
            #expect(r?.day == 15)
            #expect(r?.month == 6)
        }
        // "15h30" is a French time, not a date.
        let timeResults = Chrono.fr.casual.parse(text: "15h30")
        #expect(timeResults.first?.start.isCertain(.hour) == true)
        #expect(timeResults.first?.start.isCertain(.month) == false)
    }

    @Test func spanishDottedDate() async throws {
        for text in ["15.6", "15.06", "15/6"] {
            let r = firstDate(Chrono.es.casual, text)
            #expect(r?.isDate == true, "Expected ES '\(text)' to be a date")
            #expect(r?.day == 15)
            #expect(r?.month == 6)
        }
    }

    @Test func portugueseDottedDate() async throws {
        for text in ["15.6", "15.06", "15/6", "consulta 15.6"] {
            let r = firstDate(Chrono.pt.casual, text)
            #expect(r?.isDate == true, "Expected PT '\(text)' to be a date")
            #expect(r?.day == 15)
            #expect(r?.month == 6)
        }
        // "15h30" is a Portuguese time, not a date.
        let timeResults = Chrono.pt.casual.parse(text: "15h30")
        #expect(timeResults.first?.start.isCertain(.hour) == true)
        #expect(timeResults.first?.start.isCertain(.month) == false)
    }

    @Test func dutchDottedDateRegression() async throws {
        for text in ["15.6", "15.06", "afspraak 15.6"] {
            let r = firstDate(Chrono.nl.casual, text)
            #expect(r?.isDate == true, "Expected NL '\(text)' to be a date")
            #expect(r?.day == 15)
            #expect(r?.month == 6)
        }
        // "15.30 uur" stays a time.
        let timeResults = Chrono.nl.casual.parse(text: "15.30 uur")
        #expect(timeResults.first?.start.isCertain(.hour) == true)
    }

    // MARK: Middle-endian locale (month.day)

    @Test func englishDottedDateRegression() async throws {
        for text in ["6.15", "06.15", "meeting 6.15"] {
            let r = firstDate(Chrono.casual, text)
            #expect(r?.isDate == true, "Expected EN '\(text)' to be a date")
            #expect(r?.day == 15)
            #expect(r?.month == 6)
        }
    }
}
