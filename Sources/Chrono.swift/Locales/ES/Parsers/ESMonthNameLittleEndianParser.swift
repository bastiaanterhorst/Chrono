// ESMonthNameLittleEndianParser.swift - Parser for month name expressions in Spanish in little-endian format
import Foundation

/// Parser for month name expressions in Spanish in little-endian format (e.g., "5 de enero de 2022")
public struct ESMonthNameLittleEndianParser: Parser {
    private static let PATTERN = "(?:(?:desde|de|el|la)\\s*)?([0-9]{1,2})(?:º|°|\\.|\\s)?(?:\\s*(?:de|\\-|\\–|\\,|al?)?\\s*)(de\\s*)?(\(PatternUtils.matchAnyPattern(ESConstants.MONTH_DICTIONARY)))(?:\\s*(?:de|\\-|\\–|\\,|del?)?\\s*)(de\\s*)?([0-9]{1,4}(?![^\\s]\\d))(?=\\W|$)?"
    
    private static let DAY_GROUP = 1
    private static let MONTH_GROUP = 3
    private static let YEAR_GROUP = 5
    
    public func pattern(context: ParsingContext) -> String {
        return ESMonthNameLittleEndianParser.PATTERN
    }
    
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let result = ParsingComponents(reference: context.reference)
        
        // Day
        if let day = match.string(at: ESMonthNameLittleEndianParser.DAY_GROUP) {
            let dayNumber = Int(day) ?? 0
            if dayNumber > 31 {
                // Too large to be a day
                return nil
            }
            result.assign(.day, value: dayNumber)
        }
        
        // Month
        if let month = match.string(at: ESMonthNameLittleEndianParser.MONTH_GROUP)?.lowercased() {
            if let monthNumber = ESConstants.MONTH_DICTIONARY[month] {
                result.assign(.month, value: monthNumber)
            } else {
                // Try to match partial month names
                for (key, value) in ESConstants.MONTH_DICTIONARY {
                    if key.contains(month) || month.contains(key) {
                        result.assign(.month, value: value)
                        break
                    }
                }
                
                // If still no match, return nil
                if result.get(.month) == nil {
                    return nil
                }
            }
        }
        
        // Year
        if let year = match.string(at: ESMonthNameLittleEndianParser.YEAR_GROUP) {
            let yearNumber = ESConstants.parseYear(year)
            result.assign(.year, value: yearNumber)
        } else {
            // If the year is not specified, we set it to the current year
            let today = context.refDate
            let calendar = Calendar.current
            let year = calendar.component(.year, from: today)
            result.imply(.year, value: year)
        }
        
        return result
    }
}