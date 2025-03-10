// DESpecificTimeExpressionParser.swift - Parser for specific time expressions in German
import Foundation

/// Parser for specific time expressions in German like "13:15", "5:30 uhr", etc.
public struct DESpecificTimeExpressionParser: Parser {
    public init() {}
    
    public func pattern(context: ParsingContext) -> String {
        return "(?:^|\\s|T)" +
               "(?:(um)\\s+)?" +
               "([0-1]?[0-9]|2[0-4]):([0-5][0-9])(?::([0-5][0-9])(?:\\.(\\d{1,6}))?)?" +
               "(?:\\s*uhr)?" +
               "(?:\\s*(morgens?|vormittags?|mittags?|nachmittags?|abends?|nachts?))?" +
               "(?=\\W|$)"
    }
    
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let result = ParsingComponents(reference: context.reference)
        
        // Hours & minutes (required)
        guard let hourStr = match.string(at: 2), let hourVal = Int(hourStr),
              let minuteStr = match.string(at: 3), let minuteVal = Int(minuteStr) else {
            return nil
        }
        
        // Meridiem handling
        var meridiem: Meridiem?
        if let meridiemStr = match.string(at: 6)?.lowercased() {
            if meridiemStr.contains("nachmittag") || meridiemStr.contains("abend") || meridiemStr.contains("nacht") {
                meridiem = .pm
            } else if meridiemStr.contains("morgen") || meridiemStr.contains("vormittag") {
                meridiem = .am
            }
        }
        
        let adjustedHour: Int
        if meridiem == .pm && hourVal < 12 {
            adjustedHour = hourVal + 12
        } else if meridiem == .am && hourVal == 12 {
            adjustedHour = 0
        } else {
            adjustedHour = hourVal
        }
        
        // Assign components
        result.assign(.hour, value: adjustedHour)
        result.assign(.minute, value: minuteVal)
        
        // Seconds (optional)
        if let secondStr = match.string(at: 4), let secondVal = Int(secondStr) {
            result.assign(.second, value: secondVal)
        }
        
        // Milliseconds (optional)
        if let millisecondStr = match.string(at: 5)?.nilIfEmpty() {
            // Pad with zeros to ensure consistent length (up to 3 digits)
            let paddedMilliseconds = millisecondStr.padding(toLength: 3, withPad: "0", startingAt: 0)
            if let millisecondVal = Int(paddedMilliseconds.prefix(3)) {
                result.assign(.millisecond, value: millisecondVal)
            }
        }
        
        return result
    }
}