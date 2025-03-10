// PTConstants.swift - Constants for Portuguese date parsing
import Foundation

/// Constants for Portuguese date parsing
public enum PTConstants {
    /// Dictionary mapping Portuguese weekday names to their index (0 = Sunday, 1 = Monday, etc.)
    public static let WEEKDAY_DICTIONARY: [String: Int] = [
        "domingo": 0,
        "dom": 0,
        "segunda": 1,
        "segunda-feira": 1,
        "seg": 1,
        "terça": 2,
        "terça-feira": 2,
        "ter": 2,
        "quarta": 3,
        "quarta-feira": 3,
        "qua": 3,
        "quinta": 4,
        "quinta-feira": 4,
        "qui": 4,
        "sexta": 5,
        "sexta-feira": 5,
        "sex": 5,
        "sábado": 6,
        "sabado": 6,
        "sab": 6
    ]
    
    /// Dictionary mapping Portuguese month names to their index (1 = January, etc.)
    public static let MONTH_DICTIONARY: [String: Int] = [
        "janeiro": 1,
        "jan": 1,
        "jan.": 1,
        "fevereiro": 2,
        "fev": 2,
        "fev.": 2,
        "março": 3,
        "marco": 3,
        "mar": 3,
        "mar.": 3,
        "abril": 4,
        "abr": 4,
        "abr.": 4,
        "maio": 5,
        "mai": 5,
        "mai.": 5,
        "junho": 6,
        "jun": 6,
        "jun.": 6,
        "julho": 7,
        "jul": 7,
        "jul.": 7,
        "agosto": 8,
        "ago": 8,
        "ago.": 8,
        "setembro": 9,
        "set": 9,
        "set.": 9,
        "outubro": 10,
        "out": 10,
        "out.": 10,
        "novembro": 11,
        "nov": 11,
        "nov.": 11,
        "dezembro": 12,
        "dez": 12,
        "dez.": 12
    ]
    
    /// Function to parse year with era designation
    public static func parseYear(_ match: String) -> Int {
        if match.range(of: "^[0-9]{1,4}$", options: .regularExpression) != nil {
            var yearNumber = Int(match) ?? 0
            if yearNumber < 100 {
                if yearNumber > 50 {
                    yearNumber = yearNumber + 1900
                } else {
                    yearNumber = yearNumber + 2000
                }
            }
            return yearNumber
        }
        
        if match.range(of: "a\\.?\\s*c\\.?", options: [.regularExpression, .caseInsensitive]) != nil {
            let withoutEra = match.replacingOccurrences(
                of: "a\\.?\\s*c\\.?",
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
            return -(Int(withoutEra) ?? 0)
        }
        
        return Int(match) ?? 0
    }
}