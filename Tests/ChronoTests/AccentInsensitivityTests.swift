// AccentInsensitivityTests.swift - Verifies that unaccented input parses
// identically to the accented form across the Latin locales.
import Testing
import Foundation
@testable import Chrono

/// Each case is (accented, unaccented). Both must parse, and both must resolve
/// to the same date — that is the whole point of diacritic-insensitive matching.
@Suite("Accent (diacritic) insensitivity")
struct AccentInsensitivityTests {
    static let ref = makeTestDate(year: 2012, month: 8, day: 10)

    private func expectSameDate(
        _ accented: String,
        _ plain: String,
        _ date: (String) -> Date?,
        _ comment: Comment? = nil
    ) {
        let a = date(accented)
        let b = date(plain)
        #expect(a != nil, "accented form should parse: '\(accented)'")
        #expect(b != nil, "unaccented form should parse: '\(plain)'")
        #expect(a == b, "'\(accented)' and '\(plain)' should resolve to the same date")
    }

    // MARK: Portuguese

    @Test(arguments: [
        ("próxima semana", "proxima semana"),   // next week
        ("próximo mês", "proximo mes"),          // next month (relative unit)
        ("sábado", "sabado"),                    // weekday
        ("amanhã", "amanha"),                    // casual
        ("10 de março de 2013", "10 de marco de 2013"), // month name
    ])
    func portuguese(_ pair: (String, String)) {
        let ref = Self.ref
        expectSameDate(pair.0, pair.1) {
            Chrono.pt.casual.parse(text: $0, referenceDate: ref).first?.start.date
        }
    }

    // MARK: Spanish

    @Test(arguments: [
        ("próxima semana", "proxima semana"),    // next week
        ("miércoles", "miercoles"),              // weekday
        ("mañana", "manana"),                    // casual (previously broken pair)
        ("próximo año", "proximo ano"),          // next year (accented-only key "año")
        ("próximo día", "proximo dia"),          // relative unit (accented-only key "día")
    ])
    func spanish(_ pair: (String, String)) {
        let ref = Self.ref
        expectSameDate(pair.0, pair.1) {
            Chrono.es.casual.parse(text: $0, referenceDate: ref).first?.start.date
        }
    }

    // MARK: French

    @Test(arguments: [
        ("10 février 2013", "10 fevrier 2013"),  // month name
        ("10 août 2013", "10 aout 2013"),        // month name
        ("10 décembre 2013", "10 decembre 2013"),// month name
        ("cet après-midi", "cet apres-midi"),    // casual (previously broken pair)
        ("lundi précédent", "lundi precedent"),  // weekday + modifier
    ])
    func french(_ pair: (String, String)) {
        let ref = Self.ref
        expectSameDate(pair.0, pair.1) {
            Chrono.fr.casual.parse(text: $0, referenceDate: ref).first?.start.date
        }
    }

    // MARK: German

    @Test(arguments: [
        ("nächste Woche", "nachste Woche"),      // next week
        ("10. März 2013", "10. Marz 2013"),      // month name
    ])
    func german(_ pair: (String, String)) {
        let ref = Self.ref
        expectSameDate(pair.0, pair.1) {
            Chrono.de.casual.parse(text: $0, referenceDate: ref).first?.start.date
        }
    }
}
