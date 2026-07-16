import Testing
import Foundation
@testable import Chrono

// Regression tests for the scope-down-eager-parsing change (openspec/changes/scope-down-eager-parsing).
//
// Chrono's casual parsers must NOT recognize: "now"-keywords, second-granularity relative
// expressions, duration phrases ("for 2 hours"), bare numbers as hours ("buy 2 apples"),
// out-of-range hours/minutes ("at 27", "5:80"), or keywords inside longer words ("version 2.0",
// "Feierabend"). They MUST keep recognizing qualified times ("dinner 7pm"), connected bare hours
// for date+time merging ("tomorrow at 3"), and locale clock conventions ("um 24 Uhr", "27時").
//
// Reference instant for every case: 2026-07-16 10:30 (a Thursday).

private func scopeRefDate() -> ParsingReference {
    var c = DateComponents()
    c.year = 2026; c.month = 7; c.day = 16; c.hour = 10; c.minute = 30
    return ParsingReference(instant: Calendar.current.date(from: c)!)
}

private func chrono(_ locale: String) -> Chrono {
    switch locale {
    case "es": return Chrono.es.casual
    case "fr": return Chrono.fr.casual
    case "de": return Chrono.de.casual
    case "nl": return Chrono.nl.casual
    case "pt": return Chrono.pt.casual
    case "ja": return Chrono.ja.casual
    default: return Chrono.casual
    }
}

private func parseScope(_ locale: String, _ text: String, forward: Bool = false) -> [ParsedResult] {
    chrono(locale).parse(text: text, referenceDate: scopeRefDate(),
                         options: ParsingOptions(forwardDate: forward))
}

/// The text must produce no result at all.
func expectNoMatch(_ locale: String, _ text: String, _ comment: Comment) {
    let results = parseScope(locale, text)
    #expect(results.isEmpty, "\(comment): \"\(text)\" [\(locale)] should not parse, got \(results.map { "'\($0.text)'" })")
}

/// The text must produce at least one result; optional component assertions run on the first.
@discardableResult
func expectMatch(_ locale: String, _ text: String, _ comment: Comment,
                 day: Int? = nil, hour: Int? = nil, minute: Int? = nil,
                 matchedText: String? = nil) -> ParsedResult? {
    let results = parseScope(locale, text)
    #expect(!results.isEmpty, "\(comment): \"\(text)\" [\(locale)] should parse")
    guard let r = results.first else { return nil }
    if let day { #expect(r.start.get(.day) == day, "\(comment): day of \"\(text)\"") }
    if let hour { #expect(r.start.get(.hour) == hour, "\(comment): hour of \"\(text)\"") }
    if let minute { #expect(r.start.get(.minute) == minute, "\(comment): minute of \"\(text)\"") }
    if let matchedText {
        #expect(r.text.trimmingCharacters(in: .whitespaces) == matchedText,
                "\(comment): match span of \"\(text)\" should be '\(matchedText)', got '\(r.text)'")
    }
    return r
}

// MARK: - Merge protection (must hold before AND after every pattern change)

@Test func mergeProtectionDatePlusTime() {
    // Date + connected bare hour keeps merging into a full datetime (meridiem becomes known).
    expectMatch("en", "tomorrow at 3", "EN date + bare hour merge", day: 17, hour: 3)
    expectMatch("en", "tomorrow at 15", "EN date + 24h bare hour merge", day: 17, hour: 15)
    expectMatch("en", "friday at 3", "EN weekday + bare hour merge", day: 17, hour: 3)
    expectMatch("ja", "明日の3時", "JA date + hour merge", day: 17, hour: 3)
}

@Test func mergeProtectionQualifiedTimes() {
    // Qualified times (meridiem / minutes / hour marker) parse without a connector word.
    expectMatch("en", "dinner 7pm", "EN meridiem after whitespace", hour: 19)
    expectMatch("en", "gym 15:00", "EN H:MM after whitespace", hour: 15, minute: 0)
    expectMatch("en", "14:30", "EN bare H:MM", hour: 14, minute: 30)
    expectMatch("fr", "à 3h", "FR h-marker time", hour: 3)
    expectMatch("pt", "amanhã às 15h", "PT date + h-marker time", day: 17, hour: 15)
    expectMatch("nl", "morgen om 15:00", "NL date + connected H:MM", day: 17)
}

@Test func mergeProtectionLocaleClockConventions() {
    // DE/NL hour 24 = midnight; JA late-night hours 24-29 roll into the next day by convention.
    expectMatch("de", "um 24 Uhr", "DE midnight convention", hour: 24)
    expectMatch("nl", "om 24 uur", "NL midnight convention", hour: 24)
    // Day component stays on the reference day; the resolved Date rolls to next-day 03:00.
    expectMatch("ja", "27時", "JA late-night hour", hour: 27)
}

@Test func mergeProtectionForwardRelatives() {
    // Future-direction relative phrases keep working after duration/seconds removal.
    expectMatch("en", "in 2 hours", "EN in + hours", hour: 12, minute: 30)
    expectMatch("en", "in 2 minutes", "EN in + minutes", hour: 10, minute: 32)
    // NOTE: "in 5 Stunden" (DE) is asserted in the DE section below — today the bare-number bug
    // hijacks it to 05:00; the correct now+5h assertion lands together with the DE fix.
    expectMatch("nl", "over 2 dagen", "NL over + days", day: 18)
    expectMatch("es", "en 2 horas", "ES en + hours", hour: 12)
    expectMatch("pt", "daqui a 2 dias", "PT daqui a + days", day: 18)
    expectMatch("ja", "2日後", "JA N days later", day: 18)
}

@Test func mergeProtectionCasualKeywords() {
    // Sibling casual keywords survive the "now" removal.
    expectMatch("en", "tomorrow", "EN tomorrow", day: 17)
    expectMatch("de", "morgen", "DE morgen", day: 17)
    expectMatch("nl", "morgen", "NL morgen", day: 17)
    expectMatch("fr", "demain", "FR demain", day: 17)
    expectMatch("es", "mañana", "ES mañana", day: 17)
    expectMatch("pt", "amanhã", "PT amanhã", day: 17)
    expectMatch("ja", "明日", "JA ashita", day: 17)
    expectMatch("en", "yesterday", "EN yesterday stays (forward-only is consumer policy)", day: 15)
}
