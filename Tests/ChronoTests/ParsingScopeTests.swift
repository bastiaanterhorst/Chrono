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

// MARK: - Strict configurations (share the same time parsers)

@Test func strictConfigurationsShareTheFixes() {
    let strict = Chrono.strict
    #expect(strict.parse(text: "test at 27", referenceDate: scopeRefDate()).isEmpty,
            "strict: out-of-range hour must reject")
    #expect(strict.parse(text: "buy 2 apples", referenceDate: scopeRefDate()).isEmpty,
            "strict: bare numbers are not times")
    #expect(!strict.parse(text: "14:30", referenceDate: scopeRefDate()).isEmpty,
            "strict: proper times still parse")
}

// MARK: - Japanese

@Test func jaScopeDown() {
    expectNoMatch("ja", "会議は2時間です", "時間 duration is not a clock time")
    expectNoMatch("ja", "2時間かかる", "時間 duration is not a clock time")
    expectNoMatch("ja", "24時間営業", "時間 duration is not a clock time")
    expectNoMatch("ja", "100時間の作業", "no partial match inside digit runs")
    expectNoMatch("ja", "99時", "hour out of range (>29)")
    expectNoMatch("ja", "30時", "hour out of range (>29)")
    expectNoMatch("ja", "10時70分", "minute out of range")
    expectNoMatch("ja", "朝ごはんを作る", "bare 朝 removed (no word boundaries in Japanese)")
    expectNoMatch("ja", "深夜まで作業", "bare 夜 removed")
    expectNoMatch("ja", "今すぐ電話する", "今 is not a now-keyword (verifies no regression)")
    expectNoMatch("ja", "りんごを2つ買う", "bare number is not a time")
}

@Test func jaKeptBehavior() {
    expectMatch("ja", "3時に集合", "hour with 時 marker", hour: 3)
    expectMatch("ja", "14時30分", "hour and minutes", hour: 14, minute: 30)
    expectMatch("ja", "午後3時", "meridiem marker", hour: 15)
    expectMatch("ja", "今朝メール", "compound 今朝 stays", hour: 6)
    expectMatch("ja", "今夜やる", "compound 今夜 stays")
    expectMatch("ja", "昨日の資料", "yesterday stays (consumer policy)", day: 15)
    expectMatch("ja", "2日前に完了", "days-ago stays (consumer policy)", day: 14)
    expectMatch("ja", "27時", "late-night hour stays", hour: 27)
}

// MARK: - Portuguese

@Test func ptScopeDown() {
    expectNoMatch("pt", "agora", "now-keyword")
    expectNoMatch("pt", "comprar 2 maçãs", "bare number after whitespace")
    expectNoMatch("pt", "às 27", "hour out of range")
    expectNoMatch("pt", "reunião 2024", "no partial match inside digit runs")
    expectNoMatch("pt", "em 30 segundos", "seconds phrase must not leak into the time parser")
    expectNoMatch("pt", "há 2 minutos", "minutes phrase must not leak into the time parser")
    expectNoMatch("pt", "durante 2 horas", "duration phrase")
    expectNoMatch("pt", "por 2 horas", "duration phrase")
    expectNoMatch("pt", "item 2 dias", "'em' must not match inside 'item'")
    expectNoMatch("pt", "apanha 2 dias", "'ha' must not match inside 'apanha'")
    // "versão 2.5" still reads as a dotted DATE (May 2) — deliberate 7c3b13b behavior, out of
    // scope here (see design.md open questions). It must just never be a TIME again.
    let dotted = parseScope("pt", "versão 2.5 do app")
    #expect(dotted.allSatisfy { !$0.start.isCertain(.hour) }, "2.5 must not be read as a clock time")
}

@Test func ptKeptBehavior() {
    let r = expectMatch("pt", "chamar às 3", "connected bare hour is a fragment", hour: 3, matchedText: "às 3")
    #expect(r?.start.isCertain(.minute) == false)
    let marker = expectMatch("pt", "às 15h", "h-marker makes minutes known", hour: 15, minute: 0)
    #expect(marker?.start.isCertain(.minute) == true)
    expectMatch("pt", "15h30", "bare h-marker time with minutes", hour: 15, minute: 30)
    expectMatch("pt", "3h da tarde", "h-marker plus day period", hour: 15)
    expectMatch("pt", "ontem", "yesterday stays (consumer policy)", day: 15)
    expectMatch("pt", "há 2 dias", "days-ago stays (consumer policy)", day: 14)
    expectMatch("pt", "em 2 dias", "in 2 days", day: 18)
}

// MARK: - Dutch

@Test func nlScopeDown() {
    expectNoMatch("nl", "doe het nu even", "'nu' now-keyword")
    expectNoMatch("nl", "over 30 seconden", "seconds unit")
    expectNoMatch("nl", "30 seconden geleden", "seconds unit, past")
    expectNoMatch("nl", "binnen 30 seconden", "within-parser seconds")
    expectNoMatch("nl", "ik wil 3 a 4 appels", "lone-letter meridiem removed")
    expectNoMatch("nl", "versie 2.0", "dot decimal is not a time")
    expectNoMatch("nl", "kost 3.50 euro", "dot decimal is not a time")
    expectNoMatch("nl", "gedurende 2 uur", "bare 'N uur' is a duration")
    expectNoMatch("nl", "voor 2 uur", "'voor' is deliberately not a connector")
    expectNoMatch("nl", "koop 2 appels", "bare number is not a time")
    expectNoMatch("nl", "om 27", "hour out of range")
}

@Test func nlKeptBehavior() {
    let uur = expectMatch("nl", "om 2 uur", "connected uur time is exact", hour: 2, minute: 0)
    #expect(uur?.start.isCertain(.minute) == true)
    let bare = expectMatch("nl", "bel om 3", "connected bare hour is a fragment", hour: 3, matchedText: "om 3")
    #expect(bare?.start.isCertain(.minute) == false)
    expectMatch("nl", "15:00", "bare colon time", hour: 15, minute: 0)
    expectMatch("nl", "15.30 uur", "dot minutes with uur marker", hour: 15, minute: 30)
    expectMatch("nl", "3pm", "meridiem time", hour: 15)
    expectMatch("nl", "gisteren", "yesterday stays (consumer policy)", day: 15)
    expectMatch("nl", "2 minuten geleden", "minutes-ago stays (consumer policy)", minute: 28)
}

// MARK: - German

@Test func deScopeDown() {
    expectNoMatch("de", "jetzt", "now-keyword")
    expectNoMatch("de", "in 30 Sekunden", "seconds unit")
    expectNoMatch("de", "vor 30 Sekunden", "seconds unit, past")
    expectNoMatch("de", "in 30s", "seconds abbreviation")
    expectNoMatch("de", "kaufe 2 Äpfel", "bare number after whitespace")
    expectNoMatch("de", "Version 2.0", "dot decimal is not a time")
    expectNoMatch("de", "kostet 2,50 Euro", "comma decimal is not a time")
    expectNoMatch("de", "während 2 Stunden Meeting", "'während' marks a duration")
    expectNoMatch("de", "etwa 2 Stunden", "approximation alone is a duration")
    expectNoMatch("de", "3 Wochen", "bare week count is a duration")
    expectNoMatch("de", "Feierabend vorbereiten", "'abend' inside Feierabend")
    expectNoMatch("de", "um 27", "hour out of range")
}

@Test func deKeptBehavior() {
    expectMatch("de", "in 5 Stunden", "in + hours (was hijacked to 05:00 by the bare-number bug)", hour: 15, minute: 30)
    expectMatch("de", "in etwa 2 Stunden", "direction + approximation stays", hour: 12)
    expectMatch("de", "um 3", "connected bare hour", hour: 3, matchedText: "um 3")
    expectMatch("de", "8 Uhr", "Uhr marker after whitespace", hour: 8)
    expectMatch("de", "um 15.30", "German dot minutes", hour: 15, minute: 30)
    expectMatch("de", "gestern", "yesterday stays (consumer policy)", day: 15)
    expectMatch("de", "vor 2 Wochen", "weeks ago stays (consumer policy)")
    expectMatch("de", "mittags", "casual time keyword", hour: 12)
}

@Test func deUnmatchedTrailingNumberIsNotSwallowed() {
    let r = expectMatch("de", "morgen 8", "date keyword only", day: 17, matchedText: "morgen")
    #expect(r?.start.isCertain(.hour) == false)
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
