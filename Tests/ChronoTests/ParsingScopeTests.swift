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

// MARK: - English

@Test func enNowIsNotParsed() {
    expectNoMatch("en", "now", "bare now")
    expectNoMatch("en", "do it now", "now inside a sentence")
}

@Test func enSecondsAreNotParsed() {
    expectNoMatch("en", "in 30 seconds", "within-parser seconds")
    expectNoMatch("en", "30 seconds ago", "ago-parser seconds")
    expectNoMatch("en", "ping me +30s", "casual-relative 's' abbreviation")
    expectNoMatch("en", "next 5 seconds", "casual-relative seconds")
    expectNoMatch("en", "30 seconds from now", "relative-date seconds")
}

@Test func enDurationsAreNotDeadlines() {
    expectNoMatch("en", "for 2 hours", "for + hours")
    expectNoMatch("en", "meeting for 2 hours", "for + hours mid-sentence")
    // "within"/"in" deadlines stay. (The span has always resolved to the inner "in 2 weeks"
    // via overlap resolution — pre-existing behavior, only the semantics are asserted here.)
    expectMatch("en", "within 2 weeks", "within stays", day: 27)
}

@Test func enBareNumbersAreNotTimes() {
    expectNoMatch("en", "buy 2 apples", "bare number after whitespace")
    expectNoMatch("en", "read chapter 12", "bare number after whitespace")
    expectNoMatch("en", "call, 7", "comma is not a connector")
    expectNoMatch("en", "test on 3", "'on' is not a time connector")
    expectNoMatch("en", "pay 50", "bare out-of-range number")
    expectNoMatch("en", "test 27", "bare out-of-range number")
    expectNoMatch("en", "version 2.0", "connector must not match inside 'version'")
}

@Test func enOutOfRangeTimesAreRejected() {
    expectNoMatch("en", "test at 27", "hour 27")
    expectNoMatch("en", "test at50", "no whitespace after connector")
    expectNoMatch("en", "test at 99", "hour 99")
    expectNoMatch("en", "27:00", "H:MM hour out of range")
    expectNoMatch("en", "5:80", "H:MM minute out of range")
    expectNoMatch("en", "99:99", "H:MM both out of range")
}

@Test func enConnectedBareHourIsAFragment() {
    // "at 3" stays matchable (so "tomorrow at 3" merges) but is a non-confident fragment:
    // hour known, meridiem only implied. Consumers ignore it standalone.
    let r = expectMatch("en", "test at 3", "connected bare hour", hour: 3, matchedText: "at 3")
    #expect(r?.start.isCertain(.hour) == true)
    #expect(r?.start.isCertain(.meridiem) == false)
    expectMatch("en", "test at 15", "connected 24h bare hour", hour: 15, matchedText: "at 15")
}

@Test func enUnmatchedTrailingNumberIsNotSwallowed() {
    // "tomorrow 8" must match ONLY "tomorrow" — the 8 stays out of the span (consumers strip
    // matched spans from task names) and contributes no time.
    let r = expectMatch("en", "tomorrow 8", "date keyword only", day: 17, matchedText: "tomorrow")
    #expect(r?.start.isCertain(.hour) == false)
}

@Test func enQualifiedTimesWithoutConnector() {
    expectMatch("en", "3pm", "meridiem at string start", hour: 15)
    expectMatch("en", "7p", "attached single-letter meridiem", hour: 19)
    expectMatch("en", "tomorrow at 3:30", "date + colon time", day: 17, hour: 3, minute: 30)
}

// MARK: - French

@Test func frScopeDown() {
    expectNoMatch("fr", "maintenant", "now-keyword")
    expectNoMatch("fr", "commande 3h", "'de' must not match inside 'commande'")
    expectNoMatch("fr", "villa 3h", "'a' must not match inside 'villa'")
    expectNoMatch("fr", "à 27h", "hour out of range")
    expectNoMatch("fr", "à 5h99", "minute out of range")
    expectNoMatch("fr", "score 3:2", "colon times need two-digit minutes")
    expectNoMatch("fr", "lendemain", "demain inside lendemain")
    expectNoMatch("fr", "une belle soirée", "soir inside soirée")
    expectNoMatch("fr", "après-midi", "midi inside après-midi")
    expectNoMatch("fr", "acheter 2 pommes", "bare number is not a time")
}

@Test func frKeptBehavior() {
    expectMatch("fr", "hier", "yesterday stays (consumer policy)", day: 15)
    expectMatch("fr", "réunion à 15h30", "connected h-marker time", hour: 15, minute: 30)
    expectMatch("fr", "15h30", "bare h-marker time at string start", hour: 15, minute: 30)
    expectMatch("fr", "8h du matin", "period keeps working", hour: 8)
    expectMatch("fr", "ce soir", "ce soir still parses")
}

// MARK: - Spanish

@Test func esScopeDown() {
    expectNoMatch("es", "ahora", "now-keyword")
    expectNoMatch("es", "en 30 segundos", "within-parser seconds")
    expectNoMatch("es", "dentro de 30 segundos", "within-parser seconds")
    expectNoMatch("es", "comprar 2 manzanas", "bare number after whitespace")
    expectNoMatch("es", "a las 27", "hour out of range")
    expectNoMatch("es", "a las50", "no whitespace after connector")
    expectNoMatch("es", "version 2.0", "decimal is not a time")
    expectNoMatch("es", "durante 2 horas", "duration phrase")
    expectNoMatch("es", "por 2 horas", "duration phrase")
}

@Test func esKeptBehavior() {
    let r = expectMatch("es", "a las 3", "connected bare hour", hour: 3, matchedText: "a las 3")
    #expect(r?.start.isCertain(.meridiem) == false)
    expectMatch("es", "a las 3pm", "connected meridiem hour", hour: 15)
    expectMatch("es", "hoy", "today", day: 16)
    expectMatch("es", "ayer", "yesterday stays (consumer policy)", day: 15)
    expectMatch("es", "reunión a las 15:30", "connected colon time", hour: 15, minute: 30)
}
