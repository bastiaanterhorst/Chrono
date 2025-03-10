// ESConstants.swift - Constants for Spanish locale
import Foundation

/// Spanish locale constants
public enum ESConstants {
    /// Dictionary of Spanish weekday names to corresponding weekday numbers (0-6, Sunday-Saturday)
    public static let WEEKDAY_DICTIONARY: [String: Int] = [
        "domingo": 0,
        "dom": 0,
        "lunes": 1,
        "lun": 1,
        "martes": 2,
        "mar": 2,
        "miércoles": 3,
        "miercoles": 3,
        "mié": 3,
        "mie": 3,
        "jueves": 4,
        "jue": 4,
        "viernes": 5,
        "vie": 5,
        "sábado": 6,
        "sabado": 6,
        "sáb": 6,
        "sab": 6
    ]
    
    /// Dictionary of Spanish month names to corresponding month numbers (1-12)
    public static let MONTH_DICTIONARY: [String: Int] = [
        "enero": 1,
        "ene": 1,
        "ene.": 1,
        "febrero": 2,
        "feb": 2,
        "feb.": 2,
        "marzo": 3,
        "mar": 3,
        "mar.": 3,
        "abril": 4,
        "abr": 4,
        "abr.": 4,
        "mayo": 5,
        "may": 5,
        "may.": 5,
        "junio": 6,
        "jun": 6,
        "jun.": 6,
        "julio": 7,
        "jul": 7,
        "jul.": 7,
        "agosto": 8,
        "ago": 8,
        "ago.": 8,
        "septiembre": 9,
        "setiembre": 9,
        "sep": 9,
        "sep.": 9,
        "octubre": 10,
        "oct": 10,
        "oct.": 10,
        "noviembre": 11,
        "nov": 11,
        "nov.": 11,
        "diciembre": 12,
        "dic": 12,
        "dic.": 12
    ]
    
    /// Dictionary of Spanish integer words to corresponding numbers
    public static let INTEGER_WORD_DICTIONARY: [String: Int] = [
        "uno": 1,
        "dos": 2,
        "tres": 3,
        "cuatro": 4,
        "cinco": 5,
        "seis": 6,
        "siete": 7,
        "ocho": 8,
        "nueve": 9,
        "diez": 10,
        "once": 11,
        "doce": 12,
        "trece": 13
    ]
    
    /// Dictionary of Spanish time unit words to corresponding Calendar.Component values
    public static let TIME_UNIT_DICTIONARY: [String: Calendar.Component] = [
        "seg": .second,
        "segundo": .second,
        "segundos": .second,
        "min": .minute,
        "mins": .minute,
        "minuto": .minute,
        "minutos": .minute,
        "h": .hour,
        "hr": .hour,
        "hrs": .hour,
        "hora": .hour,
        "horas": .hour,
        "día": .day,
        "días": .day,
        "semana": .weekOfYear,
        "semanas": .weekOfYear,
        "mes": .month,
        "meses": .month,
        "cuarto": .quarter,
        "cuartos": .quarter,
        "año": .year,
        "años": .year
    ]
    
    /// Pattern for matching Spanish numbers, including written numbers
    public static let NUMBER_PATTERN = "(?:\(PatternUtils.matchAnyPattern(INTEGER_WORD_DICTIONARY))|[0-9]+|[0-9]+\\.[0-9]+|un?|uno?|una?|algunos?|unos?|media?)"
    
    /// Pattern for matching years in Spanish text
    public static let YEAR_PATTERN = "[0-9]{1,4}(?![^\\s]\\d)(?:\\s*[a|d]\\.?\\s*c\\.?|\\s*a\\.?\\s*d\\.?)?"
    
    /// Pattern for matching a single time unit in Spanish text
    public static let SINGLE_TIME_UNIT_PATTERN = "(\(NUMBER_PATTERN))\\s{0,5}(\(PatternUtils.matchAnyPattern(TIME_UNIT_DICTIONARY)))\\s{0,5}"
    
    /// Pattern for matching multiple time units in Spanish text
    public static let TIME_UNITS_PATTERN = PatternUtils.repeatedTimeunitPattern(
        prefix: "",
        singleTimeunitPattern: SINGLE_TIME_UNIT_PATTERN
    )
    
    /// Parses a string representation of a number in Spanish to a numeric value.
    /// - Parameter match: The string to parse
    /// - Returns: The numeric value of the string
    public static func parseNumberPattern(_ match: String) -> Double {
        let lowercaseMatch = match.lowercased()
        
        if let value = INTEGER_WORD_DICTIONARY[lowercaseMatch] {
            return Double(value)
        } else if lowercaseMatch == "un" || lowercaseMatch == "una" || lowercaseMatch == "uno" {
            return 1
        } else if lowercaseMatch.matches(pattern: "algunos?") {
            return 3
        } else if lowercaseMatch.matches(pattern: "unos?") {
            return 3
        } else if lowercaseMatch.matches(pattern: "media?") {
            return 0.5
        }
        
        return Double(lowercaseMatch) ?? 0
    }
    
    /// Parses a string representation of a year in Spanish to a numeric year value.
    /// - Parameter match: The string to parse
    /// - Returns: The numeric year value
    public static func parseYear(_ match: String) -> Int {
        if match.matches(pattern: "^[0-9]{1,4}$") {
            var yearNumber = Int(match) ?? 0
            if yearNumber < 100 {
                if yearNumber > 50 {
                    yearNumber += 1900
                } else {
                    yearNumber += 2000
                }
            }
            return yearNumber
        }
        
        if match.matches(pattern: "a\\.?\\s*c\\.?", options: [.caseInsensitive]) {
            let cleanMatch = match.replacingOccurrences(of: "a\\.?\\s*c\\.?", with: "", options: .regularExpression, range: nil)
            return -(Int(cleanMatch) ?? 0)
        }
        
        return Int(match) ?? 0
    }
}

// Helper extension to check if a string matches a pattern
extension String {
    /// Checks if the string matches the given regular expression pattern
    /// - Parameters:
    ///   - pattern: The regular expression pattern to match against
    ///   - options: Regular expression options
    /// - Returns: True if the string matches the pattern
    func matches(pattern: String, options: NSRegularExpression.Options = []) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return false
        }
        return regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) != nil
    }
}