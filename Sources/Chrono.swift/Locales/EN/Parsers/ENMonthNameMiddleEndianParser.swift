// ENMonthNameMiddleEndianParser.swift
import Foundation

/// Parser for dates with the format "month day, year" in English (e.g., "January 31, 2020", "Jan 31st, 2020")
public struct ENMonthNameMiddleEndianParser: Parser {
    private let monthDictionary: [String: Int] = [
        "january": 1, "jan": 1, "jan.": 1,
        "february": 2, "feb": 2, "feb.": 2,
        "march": 3, "mar": 3, "mar.": 3,
        "april": 4, "apr": 4, "apr.": 4,
        "may": 5,
        "june": 6, "jun": 6, "jun.": 6,
        "july": 7, "jul": 7, "jul.": 7,
        "august": 8, "aug": 8, "aug.": 8,
        "september": 9, "sep": 9, "sept": 9, "sep.": 9, "sept.": 9,
        "october": 10, "oct": 10, "oct.": 10,
        "november": 11, "nov": 11, "nov.": 11,
        "december": 12, "dec": 12, "dec.": 12
    ]
    
    public init() {}
    
    public func pattern(context: ParsingContext) -> String {
        return "(\\W|^)(?:on\\s*)?(" + monthDictionary.keys.joined(separator: "|") + ")" +
               "\\s*" +
               "([0-9]{1,2})(?:st|nd|rd|th)?" +
               "(?:,?\\s*([0-9]{1,4}))?" +
               "(?=\\W|$)"
    }
    
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let monthStr = match.string(at: 2)?.lowercased(), 
              let month = monthDictionary[monthStr] else {
            return nil
        }
        
        let text = match.text
        
        // Parse the day
        guard let dayStr = match.string(at: 3),
              let day = Int(dayStr),
              day >= 1 && day <= 31 else {
            return nil
        }
        
        let components = ParsingComponents(reference: context.reference)
        components.assign(.day, value: day)
        components.assign(.month, value: month)
        
        // Parse the year if present
        if let yearStr = match.string(at: 4), 
           let year = Int(yearStr) {
            if year < 100 {
                components.assign(.year, value: year + (year >= 50 ? 1900 : 2000))
            } else {
                components.assign(.year, value: year)
            }
        } else {
            // No year found, use the reference year
            let referenceDate = context.reference.instant
            let referenceYear = Calendar.current.component(.year, from: referenceDate)
            components.imply(.year, value: referenceYear)
        }
        
        return components
    }
}