// MultiLocaleExample.swift - Examples of multi-locale date parsing with Chrono.swift
import Foundation
import Chrono

/// Example showing multi-locale date parsing capabilities of Chrono.swift
struct MultiLocaleExample {
    static func run() {
        print("Chrono.swift Multi-Locale Date Parsing Examples")
        print("============================================\n")
        
        // Helper for formatting
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        // Reference date for consistent results
        let refDate = Date(timeIntervalSince1970: 1735603200) // January 1, 2025
        
        // Example 1: English (default)
        let englishExample = "Let's meet tomorrow at 2pm"
        let englishResults = Chrono.casual.parse(text: englishExample, referenceDate: refDate)
        
        print("English: \"\(englishExample)\"")
        if let result = englishResults.first {
            print("  Parsed: \(dateFormatter.string(from: result.start.date))\n")
        }
        
        // Example 2: German
        let germanExample = "Treffen wir uns morgen um 14 Uhr"
        let germanResults = Chrono.de.casual.parse(text: germanExample, referenceDate: refDate)
        
        print("German: \"\(germanExample)\"")
        if let result = germanResults.first {
            print("  Parsed: \(dateFormatter.string(from: result.start.date))\n")
        }
        
        // Example 3: French
        let frenchExample = "Rencontrons-nous demain à 14h"
        let frenchResults = Chrono.fr.casual.parse(text: frenchExample, referenceDate: refDate)
        
        print("French: \"\(frenchExample)\"")
        if let result = frenchResults.first {
            print("  Parsed: \(dateFormatter.string(from: result.start.date))\n")
        }
        
        // Example 4: Japanese
        let japaneseExample = "明日の午後2時に会いましょう"
        let japaneseResults = Chrono.ja.casual.parse(text: japaneseExample, referenceDate: refDate)
        
        print("Japanese: \"\(japaneseExample)\"")
        if let result = japaneseResults.first {
            print("  Parsed: \(dateFormatter.string(from: result.start.date))\n")
        }
        
        // Example 5: Spanish
        let spanishExample = "Reunámonos mañana a las 2 de la tarde"
        let spanishResults = Chrono.es.casual.parse(text: spanishExample, referenceDate: refDate)
        
        print("Spanish: \"\(spanishExample)\"")
        if let result = spanishResults.first {
            print("  Parsed: \(dateFormatter.string(from: result.start.date))\n")
        }
        
        // Example 6: Portuguese
        let portugueseExample = "Vamos nos encontrar amanhã às 2 da tarde"
        let portugueseResults = Chrono.pt.casual.parse(text: portugueseExample, referenceDate: refDate)
        
        print("Portuguese: \"\(portugueseExample)\"")
        if let result = portugueseResults.first {
            print("  Parsed: \(dateFormatter.string(from: result.start.date))\n")
        }
        
        // Example 7: Date formats in different locales
        print("Date Formats Across Locales:\n")
        
        // American format (month/day/year)
        let americanFormat = "The meeting is on 01/15/2025 at 10:30am"
        let americanResults = Chrono.casual.parse(text: americanFormat)
        
        print("American Format: \"\(americanFormat)\"")
        if let result = americanResults.first {
            print("  Parsed: \(dateFormatter.string(from: result.start.date))\n")
        }
        
        // European format (day/month/year)
        let europeanFormat = "Die Besprechung ist am 15.01.2025 um 10:30 Uhr"
        let europeanResults = Chrono.de.casual.parse(text: europeanFormat)
        
        print("European Format: \"\(europeanFormat)\"")
        if let result = europeanResults.first {
            print("  Parsed: \(dateFormatter.string(from: result.start.date))\n")
        }
        
        // ISO format (year-month-day)
        let isoFormat = "La réunion est le 2025-01-15 à 10h30"
        let isoResults = Chrono.fr.casual.parse(text: isoFormat)
        
        print("ISO Format: \"\(isoFormat)\"")
        if let result = isoResults.first {
            print("  Parsed: \(dateFormatter.string(from: result.start.date))\n")
        }
        
        // Japanese format (year month day)
        let japaneseFormat = "会議は2025年1月15日の午前10時30分です"
        let japaneseFormatResults = Chrono.ja.casual.parse(text: japaneseFormat)
        
        print("Japanese Format: \"\(japaneseFormat)\"")
        if let result = japaneseFormatResults.first {
            print("  Parsed: \(dateFormatter.string(from: result.start.date))\n")
        }
    }
}
