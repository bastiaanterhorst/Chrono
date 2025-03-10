// DEConstants.swift - German language constants
import Foundation

/// Constants for German date parsing
public enum DEConstants {
    /// Days of the week in German
    public static let WEEKDAY_DICTIONARY: [String: Int] = [
        "sonntag": 0, "son": 0, "so": 0,
        "montag": 1, "mon": 1, "mo": 1,
        "dienstag": 2, "die": 2, "di": 2,
        "mittwoch": 3, "mit": 3, "mi": 3,
        "donnerstag": 4, "don": 4, "do": 4,
        "freitag": 5, "fre": 5, "fr": 5,
        "samstag": 6, "sam": 6, "sa": 6
    ]
    
    /// Months in German
    public static let MONTH_DICTIONARY: [String: Int] = [
        "januar": 1, "jan": 1,
        "februar": 2, "feb": 2,
        "märz": 3, "maerz": 3, "mär": 3, "mar": 3, "mrz": 3,
        "april": 4, "apr": 4,
        "mai": 5,
        "juni": 6, "jun": 6,
        "juli": 7, "jul": 7,
        "august": 8, "aug": 8,
        "september": 9, "sep": 9, "sept": 9,
        "oktober": 10, "okt": 10, "oct": 10,
        "november": 11, "nov": 11,
        "dezember": 12, "dez": 12, "dec": 12
    ]
    
    /// Numbers in German written as words
    public static let INTEGER_WORD_DICTIONARY: [String: Int] = [
        "eins": 1, "eine": 1, "einem": 1, "einen": 1, "einer": 1, "eines": 1,
        "zwei": 2, "drei": 3, "vier": 4, "fünf": 5, "fuenf": 5, "sechs": 6,
        "sieben": 7, "acht": 8, "neun": 9, "zehn": 10, "elf": 11, "zwölf": 12, "zwoelf": 12
    ]
    
    /// Time units in German
    public static let TIMEUNIT_DICTIONARY: [String: Calendar.Component] = [
        "sekunde": .second, "sekunden": .second, "sek": .second, "s": .second,
        "minute": .minute, "minuten": .minute, "min": .minute, "m": .minute,
        "stunde": .hour, "stunden": .hour, "std": .hour, "h": .hour,
        "tag": .day, "tage": .day, "tagen": .day, "d": .day,
        "woche": .weekOfYear, "wochen": .weekOfYear, "w": .weekOfYear,
        "monat": .month, "monate": .month, "monaten": .month, "mon": .month,
        "jahr": .year, "jahre": .year, "jahren": .year, "j": .year
    ]
}