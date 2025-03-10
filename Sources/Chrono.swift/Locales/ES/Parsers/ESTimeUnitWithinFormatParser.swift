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
                    
                    if let unit = ESConstants.TIME_UNIT_DICTIONARY[unitText] {
                        // This is a future date - within the next time period
                        let date = context.refDate
                        let calendar = Calendar.current
                        var dateComponents = DateComponents()
                        
                        switch unit {
                        case .second:
                            dateComponents.second = Int(value)
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
                            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: futureDate)
                            
                            if let year = components.year {
                                result.assign(.year, value: year)
                            }
                            if let month = components.month {
                                result.assign(.month, value: month)
                            }
                            if let day = components.day {
                                result.assign(.day, value: day)
                            }
                            if let hour = components.hour {
                                result.assign(.hour, value: hour)
                            }
                            if let minute = components.minute {
                                result.assign(.minute, value: minute)
                            }
                            if let second = components.second {
                                result.assign(.second, value: second)
                            }
                            
                            return result
                        }
                    }
                }
            }
        }
        
        return nil
    }
}