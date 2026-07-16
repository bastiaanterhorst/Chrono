// ESTimeUnitWithinFormatParser.swift - Parser for time units within expressions in Spanish
import Foundation

/// Parser for time units within expressions in Spanish (e.g., "dentro de 5 horas", "en 3 días")
public struct ESTimeUnitWithinFormatParser: Parser {
    private static let PATTERN = "(?:dentro\\s*de|en)\\s*(\(ESConstants.TIME_UNITS_PATTERN))(?=\\W|$)"
    
    public func pattern(context: ParsingContext) -> String {
        return ESTimeUnitWithinFormatParser.PATTERN
    }
    
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let timeUnitsText = match.string(at: 1) ?? ""
        
        // Extract time units using regex pattern
        let regex = try? NSRegularExpression(
            pattern: ESConstants.SINGLE_TIME_UNIT_PATTERN,
            options: [.caseInsensitive]
        )
        
        let timeUnitMatches = regex?.matches(
            in: timeUnitsText,
            options: [],
            range: NSRange(location: 0, length: timeUnitsText.utf16.count)
        )
        
        let result = ParsingComponents(reference: context.reference)
        
        guard let matches = timeUnitMatches, !matches.isEmpty else {
            return nil
        }
        
        let nsString = timeUnitsText as NSString
        
        for match in matches {
            if match.numberOfRanges >= 3 {
                let valueRange = match.range(at: 1)
                let unitRange = match.range(at: 2)
                
                if valueRange.location != NSNotFound, unitRange.location != NSNotFound {
                    let valueText = nsString.substring(with: valueRange)
                    let unitText = nsString.substring(with: unitRange).lowercased()

                    let value = ESConstants.parseNumberPattern(valueText)

                    if let unit = ESConstants.TIME_UNIT_DICTIONARY.matchValue(for: unitText) {
                        // This is a future date - within the next time period
                        let date = context.refDate
                        let calendar = Calendar.current
                        var dateComponents = DateComponents()
                        
                        switch unit {
                        case .minute:
                            dateComponents.minute = Int(value)
                        case .hour:
                            dateComponents.hour = Int(value)
                        case .day:
                            dateComponents.day = Int(value)
                        case .weekOfYear:
                            dateComponents.weekOfYear = Int(value)
                        case .month:
                            dateComponents.month = Int(value)
                        case .year:
                            dateComponents.year = Int(value)
                        case .quarter:
                            dateComponents.quarter = Int(value)
                        default:
                            continue
                        }
                        
                        if let futureDate = calendar.date(byAdding: dateComponents, to: date) {
                            // The date portion is known; the time-of-day is only known for time
                            // units (e.g. "en 5 horas"), otherwise implied (e.g. "en 3 días").
                            let isTimeUnit = (unit == .minute || unit == .hour)
                            result.assignRelativeDate(from: futureDate, unitIsTime: isTimeUnit, calendar: calendar)
                            return result
                        }
                    }
                }
            }
        }
        
        return nil
    }
}