import Testing
import Foundation
@testable import Chrono

// Regression tests for "common word" collisions: short weekday/month abbreviations that are also
// ordinary words. See the dictionaries/parsers in each Locale folder.
//
// Two failure modes were identified; the handling differs:
//   1. Standalone common words ("mit" = with, "die" = the, "so" = so) — handled by removing the
//      abbreviation from the matching dictionary, GERMAN ONLY. Other locales intentionally keep
//      their short forms (EN "sun"/"sat", ES "mar", FR "mer"/"jeu", NL "zo"/"zon"/"vrij"/"zat",
//      PT "ter"/"mar") and DO parse them as dates.
//   2. Common words that merely *end* with an abbreviation ("lemon" → "mon", "lago" → "ago") — fixed
//      by a leading word-boundary guard in the parser pattern; applies to ALL locales and stays.

private func collisionRefDate() -> ParsingReference {
    var c = DateComponents()
    c.year = 2023; c.month = 1; c.day = 10; c.hour = 12 // 2023-01-10 is a Tuesday
    return ParsingReference(instant: Calendar.current.date(from: c)!)
}

private func expectNoDate(_ chrono: Chrono, _ text: String, _ comment: Comment) {
    let results = chrono.parse(text: text, referenceDate: collisionRefDate())
    #expect(results.isEmpty, "\(comment): \"\(text)\" should not parse as a date, got \(results.map { $0.text })")
}

private func expectDate(_ chrono: Chrono, _ text: String, _ comment: Comment) {
    let results = chrono.parse(text: text, referenceDate: collisionRefDate())
    #expect(!results.isEmpty, "\(comment): \"\(text)\" should still parse as a date")
}

// MARK: - German

@Test func deCommonWordsAreNotDates() {
    expectNoDate(Chrono.de.casual, "Einkaufen mit Anna", "mit = with")
    expectNoDate(Chrono.de.casual, "die Präsentation vorbereiten", "die = the")
    expectNoDate(Chrono.de.casual, "Bericht so schnell wie möglich", "so = so/thus")
    expectNoDate(Chrono.de.casual, "Damit anfangen", "mit must not match inside 'damit'")
}

@Test func deRealWeekdaysStillParse() {
    let ref = collisionRefDate()
    let mittwoch = Chrono.de.casual.parse(text: "Termin am Mittwoch", referenceDate: ref)
    #expect(mittwoch.count == 1)
    #expect(mittwoch.first?.start.get(.weekday) == 3) // Wednesday

    // "mi" is an unambiguous abbreviation and is kept.
    #expect(Chrono.de.casual.parse(text: "Termin am mi", referenceDate: ref).first?.start.get(.weekday) == 3)

    expectDate(Chrono.de.casual, "Wir treffen uns am Montag", "Montag still parses")
    expectDate(Chrono.de.casual, "Bis Sonntag", "Sonntag still parses")
    expectDate(Chrono.de.casual, "Termin im März", "März still parses")
}

// MARK: - English

@Test func enCommonWordsAreNotDates() {
    // Abbreviations matched as a word *suffix* must not match (word-boundary guard).
    expectNoDate(Chrono.casual, "buy a lemon", "lemon ends in 'mon'")
    expectNoDate(Chrono.casual, "a common task", "common ends in 'mon'")
    expectNoDate(Chrono.casual, "look at the statue", "statue ends in 'tue'")
    expectNoDate(Chrono.casual, "I screwed it up", "screwed ends in 'wed'")
    expectNoDate(Chrono.casual, "eat salmon", "salmon ends in 'mon'")
    expectNoDate(Chrono.casual, "summon the team", "summon ends in 'mon'")
}

@Test func enRealWeekdaysStillParse() {
    let ref = collisionRefDate()
    #expect(Chrono.casual.parse(text: "meeting on monday", referenceDate: ref).first?.start.get(.weekday) == 1)
    #expect(Chrono.casual.parse(text: "meeting on mon", referenceDate: ref).first?.start.get(.weekday) == 1)
    expectDate(Chrono.casual, "see you saturday", "saturday still parses")
    expectDate(Chrono.casual, "see you sunday", "sunday still parses")
    expectDate(Chrono.casual, "next friday", "friday still parses")
    // "sun"/"sat" short forms are intentionally kept (standalone-word removal is DE-only).
    #expect(Chrono.casual.parse(text: "see you sun", referenceDate: ref).first?.start.get(.weekday) == 0)
    #expect(Chrono.casual.parse(text: "see you sat", referenceDate: ref).first?.start.get(.weekday) == 6)
}

// MARK: - Spanish

@Test func esCommonWordsAreNotDates() {
    // Suffix-only collisions stay guarded ("ago" = agosto abbreviation).
    expectNoDate(Chrono.es.casual, "hago la cena", "hago ends in 'ago'")
    expectNoDate(Chrono.es.casual, "pagar el pago", "pago ends in 'ago'")
}

@Test func esRealDatesStillParse() {
    let ref = collisionRefDate()
    #expect(Chrono.es.casual.parse(text: "reunión el martes", referenceDate: ref).first?.start.get(.weekday) == 2)
    expectDate(Chrono.es.casual, "nos vemos el lunes", "lunes still parses")
    expectDate(Chrono.es.casual, "en marzo", "marzo still parses")
    expectDate(Chrono.es.casual, "el 15 de marzo", "15 de marzo still parses")
    // "mar" short form is intentionally kept (weekday Tuesday / month March).
    expectDate(Chrono.es.casual, "ir al mar", "mar parses again")
}

// MARK: - French

@Test func frRealDatesStillParse() {
    expectDate(Chrono.fr.casual, "reunion mercredi", "mercredi still parses")
    expectDate(Chrono.fr.casual, "rendez-vous jeudi", "jeudi still parses")
    expectDate(Chrono.fr.casual, "lundi prochain", "lundi still parses")
    expectDate(Chrono.fr.casual, "en mars", "mars still parses")
    // "mer"/"jeu" short forms are intentionally kept (Wednesday / Thursday).
    expectDate(Chrono.fr.casual, "rendez-vous mer", "mer parses as Wednesday")
    expectDate(Chrono.fr.casual, "un jeu", "jeu parses as Thursday")
}

// MARK: - Dutch

@Test func nlRealDatesStillParse() {
    expectDate(Chrono.nl.casual, "afspraak op woensdag", "woensdag still parses")
    expectDate(Chrono.nl.casual, "op vrijdag", "vrijdag still parses")
    expectDate(Chrono.nl.casual, "op zaterdag", "zaterdag still parses")
    expectDate(Chrono.nl.casual, "op maandag", "maandag still parses")
    // "zo"/"zon"/"vrij"/"zat" short forms are intentionally kept.
    expectDate(Chrono.nl.casual, "op zo", "zo parses as Sunday")
    expectDate(Chrono.nl.casual, "de zon", "zon parses as Sunday")
    expectDate(Chrono.nl.casual, "ben vrij", "vrij parses as Friday")
    expectDate(Chrono.nl.casual, "op zat", "zat parses as Saturday")
}

// MARK: - Portuguese

@Test func ptCommonWordsAreNotDates() {
    // Suffix-only collision stays guarded ("ago" = agosto abbreviation).
    expectNoDate(Chrono.pt.casual, "ir ao lago", "lago ends in 'ago'")
}

@Test func ptRealDatesStillParse() {
    expectDate(Chrono.pt.casual, "reuniao na quarta", "quarta still parses")
    expectDate(Chrono.pt.casual, "na terça", "terça still parses")
    expectDate(Chrono.pt.casual, "em março", "março still parses")
    expectDate(Chrono.pt.casual, "na sexta", "sexta still parses")
    // "ter"/"mar" short forms are intentionally kept.
    expectDate(Chrono.pt.casual, "na ter", "ter parses as Tuesday")
    expectDate(Chrono.pt.casual, "em mar", "mar parses as March")
}
