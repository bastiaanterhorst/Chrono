// DETimeExpressionParser.swift - Parser for time expressions in German
import Foundation

/// Parser for time expressions in German like "um 5 Uhr", "15:30", etc.
public struct DETimeExpressionParser: Parser {
    public init() {}
    
    public func pattern(context: ParsingContext) -> String {
        return "(?:^|\\s|T)" +
               "(?:(um|von|nach|vor)\\s*)?" +
               "([0-9]|0[0-9]|1[0-9]|2[0-4])(?:[.,]([0-9]{1,2}))?" +
               "(?:\\s*(?:uhr|h))?" +
               "(?:\\s*(?:([0-9]{1,2})\\s*(?:m(?:in(?:uten)?)?|Min)|\\.([0-9]{1,2})))?" +
               "(?:\\s*(?:([0-9]{1,2})\\s*(?:s(?:ek(?:unden)?)?|Sek)|\\.([0-9]{1,2})))?" +
               "(?:\\s*(morgens?|vormittags?|mittags?|nachmittags?|abends?|nachts?))?" +
               "(?=\\W|$)"
    }
    
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let result = ParsingComponents(reference: context.reference)
        
        // Hour
        guard let hourStr = match.string(at: 2), let hour = Int(hourStr) else {
            return nil
        }
        
        // Process hour with meridiem
        var meridiem: Meridiem?
        if let meridiemStr = match.string(at: 8)?.lowercased() {
            if meridiemStr.contains("nachmittag") || meridiemStr.contains("abend") || meridiemStr.contains("nacht") {
                meridiem = .pm
            } else if meridiemStr.contains("morgen") || meridiemStr.contains("vormittag") {
                meridiem = .am
            }
        }
        
        let adjustedHour: Int
        if meridiem == .pm && hour < 12 {
            adjustedHour = hour + 12
        } else if meridiem == .am && hour == 12 {
            adjustedHour = 0
        } else {
            adjustedHour = hour
        }
        
        result.assign(.hour, value: adjustedHour)
        
        // Minutes
        if let minuteStr1 = match.string(at: 3), let minute = Int(minuteStr1) {
            result.assign(.minute, value: minute)
        } else if let minuteStr2 = match.string(at: 4), let minute = Int(minuteStr2) {
            result.assign(.minute, value: minute)
        } else if let minuteStr3 = match.string(at: 5), let minute = Int(minuteStr3) {
            result.assign(.minute, value: minute)
        } else {
            result.assign(.minute, value: 0)
        }
        
        // Seconds
        if let secondStr1 = match.string(at: 6), let second = Int(secondStr1) {
            result.assign(.second, value: second)
        } else if let secondStr2 = match.string(at: 7), let second = Int(secondStr2) {
            result.assign(.second, value: second)
        } else {
            result.assign(.second, value: 0)
        }
        
        return result
    }
}