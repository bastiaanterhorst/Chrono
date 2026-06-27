import Testing
import Foundation
@testable import Chrono

// Regression tests for "common word" collisions: short weekday/month abbreviations that are also
// ordinary words in their language must NOT be parsed as dates, while the full names (and the
// unambiguous abbreviations) must keep working. See the dictionaries/parsers in each Locale folder.
//
// Two failure modes are covered:
//   1. Standalone common words ("mit" = with, "mar" = sea, "ter" = to have, …) — fixed by removing
//      the abbreviation from the matching dictionary.
//   2. Common words that merely *end* with an abbreviation ("lemon" → "mon", "lago" → "ago") — fixed
//      by a leading word-boundary guard in the parser pattern.

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
    // Standalone common words.
    expectNoDate(Chrono.casual, "I sat in the meeting", "sat = verb")
    expectNoDate(Chrono.casual, "lunch in the sun", "sun = noun")
    // Abbreviations matched as a word *suffix*.
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
}

// MARK: - Spanish

@Test func esCommonWordsAreNotDates() {
    expectNoDate(Chrono.es.casual, "ir al mar", "mar = sea (weekday/month)")
    expectNoDate(Chrono.es.casual, "el mar está tranquilo", "mar = sea")
    expectNoDate(Chrono.es.casual, "hago la cena", "hago ends in 'ago'")
    expectNoDate(Chrono.es.casual, "pagar el pago", "pago ends in 'ago'")
}

@Test func esRealDatesStillParse() {
    let ref = collisionRefDate()
    #expect(Chrono.es.casual.parse(text: "reunión el martes", referenceDate: ref).first?.start.get(.weekday) == 2)
    expectDate(Chrono.es.casual, "nos vemos el lunes", "lunes still parses")
    expectDate(Chrono.es.casual, "en marzo", "marzo still parses")
    expectDate(Chrono.es.casual, "el 15 de marzo", "15 de marzo still parses")
}

// MARK: - French

@Test func frCommonWordsAreNotDates() {
    expectNoDate(Chrono.fr.casual, "au bord de la mer", "mer = sea")
    expectNoDate(Chrono.fr.casual, "un jeu de societe", "jeu = game")
    expectNoDate(Chrono.fr.casual, "j'ai un jeu", "jeu = game")
}

@Test func frRealDatesStillParse() {
    expectDate(Chrono.fr.casual, "reunion mercredi", "mercredi still parses")
    expectDate(Chrono.fr.casual, "rendez-vous jeudi", "jeudi still parses")
    expectDate(Chrono.fr.casual, "lundi prochain", "lundi still parses")
    expectDate(Chrono.fr.casual, "en mars", "mars still parses")
}

// MARK: - Dutch

@Test func nlCommonWordsAreNotDates() {
    expectNoDate(Chrono.nl.casual, "ik ben vrij", "vrij = free")
    expectNoDate(Chrono.nl.casual, "doe het zo", "zo = so/thus")
    expectNoDate(Chrono.nl.casual, "de zon schijnt", "zon = sun")
    expectNoDate(Chrono.nl.casual, "ik zat te wachten", "zat = sat/drunk")
}

@Test func nlRealDatesStillParse() {
    expectDate(Chrono.nl.casual, "afspraak op woensdag", "woensdag still parses")
    expectDate(Chrono.nl.casual, "op vrijdag", "vrijdag still parses")
    expectDate(Chrono.nl.casual, "op zaterdag", "zaterdag still parses")
    expectDate(Chrono.nl.casual, "op maandag", "maandag still parses")
}

// MARK: - Portuguese

@Test func ptCommonWordsAreNotDates() {
    expectNoDate(Chrono.pt.casual, "vou ter uma reuniao", "ter = to have")
    expectNoDate(Chrono.pt.casual, "ir ao lago", "lago ends in 'ago'")
    expectNoDate(Chrono.pt.casual, "ir ao mar", "mar = sea")
}

@Test func ptRealDatesStillParse() {
    expectDate(Chrono.pt.casual, "reuniao na quarta", "quarta still parses")
    expectDate(Chrono.pt.casual, "na terça", "terça still parses")
    expectDate(Chrono.pt.casual, "em março", "março still parses")
    expectDate(Chrono.pt.casual, "na sexta", "sexta still parses")
}
