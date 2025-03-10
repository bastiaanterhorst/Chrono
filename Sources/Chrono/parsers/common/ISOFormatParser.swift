import Foundation

/**
 * Parser for ISO 8601 date formats:
 * - YYYY-MM-DD
 * - YYYY-MM-DDThh:mmTZD
 * - YYYY-MM-DDThh:mm:ssTZD
 * - YYYY-MM-DDThh:mm:ss.sTZD
 * - TZD = (Z or +hh:mm or -hh:mm)
 */
public final class ISOFormatParser: AbstractParserWithWordBoundaryChecking, @unchecked Sendable {
    
    private static let PATTERN = #"([0-9]{4})\-([0-9]{1,2})\-([0-9]{1,2})(?:T([0-9]{1,2}):([0-9]{1,2})(?::([0-9]{1,2})(?:\.(\d{1,4}))?)?([zZ]|([+-]\d{2}):?(\d{2})?)?)?(?=\W|$)"#
    
    private static let YEAR_NUMBER_GROUP = 1
    private static let MONTH_NUMBER_GROUP = 2
    private static let DATE_NUMBER_GROUP = 3
    private static let HOUR_NUMBER_GROUP = 4
    private static let MINUTE_NUMBER_GROUP = 5
    private static let SECOND_NUMBER_GROUP = 6
    private static let MILLISECOND_NUMBER_GROUP = 7
    private static let TZD_GROUP = 8
    private static let TZD_HOUR_OFFSET_GROUP = 9
    private static let TZD_MINUTE_OFFSET_GROUP = 10
    
    override func innerPattern(context: ParsingContext) -> String {
        return Self.PATTERN
    }
    
    override func innerExtract(context: ParsingContext, match: TextMatch) -> Any? {
        // Get the capture groups
        guard let yearStr = match.string(at: Self.YEAR_NUMBER_GROUP),
              let monthStr = match.string(at: Self.MONTH_NUMBER_GROUP),
              let dayStr = match.string(at: Self.DATE_NUMBER_GROUP),
              let year = Int(yearStr),
              let month = Int(monthStr),
              let day = Int(dayStr) else {
            return nil
        }
        
        let components = context.createParsingComponents(components: [
            .year: year,
            .month: month,
            .day: day,
        ])
        
        if let hourStr = match.string(at: Self.HOUR_NUMBER_GROUP),
           let minuteStr = match.string(at: Self.MINUTE_NUMBER_GROUP),
           let hour = Int(hourStr),
           let minute = Int(minuteStr) {
            
            components.assign(Component.hour, value: hour)
            components.assign(Component.minute, value: minute)
            
            if let secondStr = match.string(at: Self.SECOND_NUMBER_GROUP),
               let second = Int(secondStr) {
                components.assign(Component.second, value: second)
            }
            
            if let millisecondStr = match.string(at: Self.MILLISECOND_NUMBER_GROUP),
               let millisecond = Int(millisecondStr) {
                components.assign(Component.millisecond, value: millisecond)
            }
            
            if match.hasValue(at: Self.TZD_GROUP) {
                // The Zulu time zone (Z) is equivalent to UTC
                var offset = 0
                
                if let hourOffsetStr = match.string(at: Self.TZD_HOUR_OFFSET_GROUP),
                   let hourOffset = Int(hourOffsetStr) {
                    
                    var minuteOffset = 0
                    
                    if let minuteOffsetStr = match.string(at: Self.TZD_MINUTE_OFFSET_GROUP),
                       let parsedMinuteOffset = Int(minuteOffsetStr) {
                        minuteOffset = parsedMinuteOffset
                    }
                    
                    offset = hourOffset * 60
                    if offset < 0 {
                        offset -= minuteOffset
                    } else {
                        offset += minuteOffset
                    }
                }
                
                components.assign(Component.timezoneOffset, value: offset)
            }
        }
        
        components.addTag("parser/ISOFormatParser")
        return components
    }
}