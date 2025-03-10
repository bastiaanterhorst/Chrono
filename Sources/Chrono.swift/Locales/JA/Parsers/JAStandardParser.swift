// JAStandardParser.swift - Parser for standard Japanese date formats like "2013年12月26日"
import Foundation

/// Parser for standard Japanese date formats like "2013年12月26日", "平成26年12月29日", etc.
public final class JAStandardParser: Parser {
    /// The pattern to match Japanese standard date formats
    public func pattern(context: ParsingContext) -> String {
        return "(?:(?:([同今本])|((昭和|平成|令和)?([0-9０-９]{1,4}|元)))年\\s*)?([0-9０-９]{1,2})月\\s*([0-9０-９]{1,2})日"
    }
    
    /// Extracts date components from a standard Japanese date format
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        // Convert full-width numbers to half-width
        func normalizeNumber(_ str: String?) -> Int? {
            guard let str = str else { return nil }
            let normalized = str.map { char -> Character in
                // Safe conversion from full-width to half-width
                if let index = "０１２３４５６７８９".firstIndex(of: char) {
                    // Get the numeric index rather than the String.Index type
                    let distance = "０１２３４５６７８９".distance(from: "０１２３４５６７８９".startIndex, to: index)
                    // Safely convert to the corresponding half-width digit
                    if distance >= 0 && distance < 10 {
                        return "0123456789"[String.Index(utf16Offset: distance, in: "0123456789")]
                    }
                }
                return char
            }
            return Int(String(normalized))
        }
        
        let monthText = match.string(at: 5) ?? ""
        let dayText = match.string(at: 6) ?? ""
        
        guard !monthText.isEmpty && !dayText.isEmpty else { return nil }
        
        let month = normalizeNumber(monthText) ?? 0
        let day = normalizeNumber(dayText) ?? 0
        
        let component = context.createParsingComponents()
        component.assign(.month, value: month)
        component.assign(.day, value: day)
        
        // Check for special year indicators like "今年", "本年", "同年"
        if let specialYear = match.string(at: 1), !specialYear.isEmpty {
            // Current year
            let calendar = Calendar.current
            let year = calendar.component(.year, from: context.refDate)
            component.assign(.year, value: year)
        }
        // Check for explicit year and era
        else if let yearGroup = match.string(at: 2), !yearGroup.isEmpty {
            let eraText = match.string(at: 3)
            let yearNumberText = match.string(at: 4) ?? ""
            
            // Convert "元" (first year of era) to 1
            let yearNumber = yearNumberText == "元" ? 1 : (normalizeNumber(yearNumberText) ?? 0)
            
            var year = yearNumber
            if let era = eraText {
                if era == "令和" {
                    year += 2018 // Reiwa era starts in 2019 (Reiwa 1 = 2019)
                } else if era == "平成" {
                    year += 1988 // Heisei era starts in 1989 (Heisei 1 = 1989)
                } else if era == "昭和" {
                    year += 1925 // Showa era starts in 1926 (Showa 1 = 1926)
                }
            }
            
            component.assign(.year, value: year)
        } else {
            // Implicit year - find the closest year for the given month and day
            let calendar = Calendar.current
            let refYear = calendar.component(.year, from: context.refDate)
            let refMonth = calendar.component(.month, from: context.refDate)
            let refDay = calendar.component(.day, from: context.refDate)
            
            var year = refYear
            
            // If the specified date is earlier than the reference date, 
            // it's probably next year
            if month < refMonth || (month == refMonth && day < refDay) {
                if context.options.forwardDate {
                    year += 1
                }
            }
            // If the specified date is later than the reference date,
            // it could be this year
            else if month > refMonth || (month == refMonth && day >= refDay) {
                // Default behavior - keep the same year
            }
            // For the same month and day, just use the reference year
            
            component.imply(.year, value: year)
        }
        
        component.addTag("JAStandardParser")
        return component
    }
}