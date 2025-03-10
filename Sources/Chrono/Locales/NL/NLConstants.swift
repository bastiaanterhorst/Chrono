// NLConstants.swift - Constants for Dutch locale
import Foundation

/// Constants for Dutch locale
struct NLConstants {
    /// Days of the week in Dutch (full names)
    static let WEEKDAY_DICTIONARY: [String: Int] = [
        "zondag": 0,
        "zon": 0,
        "zo": 0,
        "maandag": 1,
        "ma": 1,
        "dinsdag": 2,
        "di": 2,
        "woensdag": 3,
        "woe": 3,
        "wo": 3,
        "donderdag": 4,
        "don": 4,
        "do": 4,
        "vrijdag": 5,
        "vrij": 5,
        "vr": 5,
        "zaterdag": 6,
        "zat": 6,
        "za": 6
    ]
    
    /// Months in Dutch (full names and abbreviations)
    static let MONTH_DICTIONARY: [String: Int] = [
        "januari": 1,
        "jan": 1,
        "februari": 2,
        "feb": 2,
        "maart": 3,
        "mrt": 3,
        "april": 4,
        "apr": 4,
        "mei": 5,
        "juni": 6,
        "jun": 6,
        "juli": 7,
        "jul": 7,
        "augustus": 8,
        "aug": 8,
        "september": 9,
        "sep": 9,
        "sept": 9,
        "oktober": 10,
        "okt": 10,
        "november": 11,
        "nov": 11,
        "december": 12,
        "dec": 12
    ]
    
    /// Time units in Dutch
    static let TIME_UNIT_DICTIONARY: [String: Component] = [
        "sec": .second,
        "seconde": .second,
        "seconden": .second,
        "min": .minute,
        "minuut": .minute,
        "minuten": .minute,
        "uur": .hour,
        "uren": .hour,
        "dag": .day,
        "dagen": .day,
        "week": .day, // Use day, but we'll handle weeks specially in the code
        "weken": .day, // Use day, but we'll handle weeks specially in the code
        "maand": .month,
        "maanden": .month,
        "jaar": .year,
        "jaren": .year,
        "jr": .year
    ]
    
    /// Check if a time unit is a week
    static func isWeek(_ unit: String) -> Bool {
        return unit == "week" || unit == "weken"
    }
    
    /// Integer modifier words in Dutch
    static let INTEGER_WORD_DICTIONARY: [String: Int] = [
        "een": 1,
        "twee": 2,
        "drie": 3,
        "vier": 4,
        "vijf": 5,
        "zes": 6,
        "zeven": 7,
        "acht": 8,
        "negen": 9,
        "tien": 10,
        "elf": 11,
        "twaalf": 12
    ]
    
    /// Ordinal words in Dutch
    static let ORDINAL_WORD_DICTIONARY: [String: Int] = [
        "eerste": 1,
        "tweede": 2,
        "derde": 3,
        "vierde": 4,
        "vijfde": 5,
        "zesde": 6,
        "zevende": 7,
        "achtste": 8,
        "negende": 9,
        "tiende": 10,
        "elfde": 11,
        "twaalfde": 12,
        "dertiende": 13,
        "veertiende": 14,
        "vijftiende": 15,
        "zestiende": 16,
        "zeventiende": 17,
        "achttiende": 18,
        "negentiende": 19,
        "twintigste": 20,
        "eenentwintigste": 21,
        "tweeëntwintigste": 22,
        "drieëntwintigste": 23,
        "vierentwintigste": 24,
        "vijfentwintigste": 25,
        "zesentwintigste": 26,
        "zevenentwintigste": 27,
        "achtentwintigste": 28,
        "negenentwintigste": 29,
        "dertigste": 30,
        "eenendertigste": 31
    ]
    
    /// Pattern for casual day mentions in Dutch
    static let CASUAL_DATE_PATTERN = """
    (nu|vandaag|gisteren|eergisteren|morgen|overmorgen|vanavond|vannacht|vanochtend|vanmiddag)
    (?:\\s*(,|om))?
    """
}