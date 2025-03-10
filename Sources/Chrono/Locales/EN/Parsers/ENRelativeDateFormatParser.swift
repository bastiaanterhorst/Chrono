// ENRelativeDateFormatParser.swift - Parser for relative dates
import Foundation

/// Parser for relative date expressions like "5 days ago", "2 weeks from now"
public final class ENRelativeDateFormatParser: Parser {
    private static let PATTERN = "(?:within\\s*)?" +
                               "(\\d+|few|half(?:\\s*an?)?|an?|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve)\\s*" +
                               "(seconds?|minutes?|hours?|days?|weeks?|months?|years?)\\s*" +
                               "(ago|before|earlier|prior|(?:from|before|after)\\s*now|from\\s*today|later|after|from)"
    
    private static let NUMBER_DICTIONARY: [String: Double] = [
        "few": 3,
        "half": 0.5,
        "a": 1, "an": 1, "one": 1,
        "two": 2, "three": 3, "four": 4, "five": 5,
        "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
        "eleven": 11, "twelve": 12
    ]
    
    /// Returns the regex pattern for this parser
    public func pattern(context: ParsingContext) -> String {
        return ENRelativeDateFormatParser.PATTERN
    }
    
    /// Extracts date from relative date expressions
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let component = context.createParsingComponents()
        let calendar = Calendar.current
        
        // Get the number part
        guard let numberText = match.string(at: 1)?.lowercased() else { return nil }
        
        var number: Double
        if let num = ENRelativeDateFormatParser.NUMBER_DICTIONARY[numberText] {
            number = Double(num)
        } else if let num = Double(numberText) {
            number = num
        } else {
            return nil
        }
        
        // Handle "half" special case for "half an hour"
        if numberText == "half" {
            if let unitText = match.string(at: 2)?.lowercased(),
               unitText.starts(with: "hour") {
                number = 0.5
            } else {
                return nil
            }
        }
        
        // Get the unit part
        guard let unitText = match.string(at: 2)?.lowercased() else { return nil }
        
        // Determine if this is past or future
        let tenseHint = match.string(at: 3)?.lowercased() ?? ""
        var isPast = false
        if tenseHint.contains("ago") || tenseHint.contains("before") || tenseHint.contains("earlier") || tenseHint.contains("prior") {
            isPast = true
        }
        
        // Adjust the sign for past dates
        if isPast {
            number = -number
        }
        
        // Apply the modification to the reference date
        let refDate = context.refDate
        var targetDate: Date?
        
        // Determine the calendar component
        if unitText.starts(with: "year") {
            targetDate = calendar.date(byAdding: .year, value: Int(number), to: refDate)
        } else if unitText.starts(with: "month") {
            targetDate = calendar.date(byAdding: .month, value: Int(number), to: refDate)
        } else if unitText.starts(with: "week") {
            targetDate = calendar.date(byAdding: .day, value: Int(number * 7), to: refDate)
        } else if unitText.starts(with: "day") {
            targetDate = calendar.date(byAdding: .day, value: Int(number), to: refDate)
        } else if unitText.starts(with: "hour") {
            targetDate = calendar.date(byAdding: .hour, value: Int(number), to: refDate)
            if abs(number - Double(Int(number))) > 0.0001 {
                // Handle fractional hours
                let minutes = Int((number - Double(Int(number))) * 60)
                targetDate = calendar.date(byAdding: .minute, value: minutes, to: targetDate ?? refDate)
            }
        } else if unitText.starts(with: "minute") {
            targetDate = calendar.date(byAdding: .minute, value: Int(number), to: refDate)
        } else if unitText.starts(with: "second") {
            targetDate = calendar.date(byAdding: .second, value: Int(number), to: refDate)
        } else {
            return nil
        }
        
        // Extract the date components
        guard let finalDate = targetDate else { return nil }
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: finalDate)
        
        // Assign all components
        if let year = dateComponents.year {
            component.assign(.year, value: year)
        }
        
        if let month = dateComponents.month {
            component.assign(.month, value: month)
        }
        
        if let day = dateComponents.day {
            component.assign(.day, value: day)
        }
        
        if unitText.starts(with: "hour") || unitText.starts(with: "minute") || unitText.starts(with: "second") {
            if let hour = dateComponents.hour {
                component.assign(.hour, value: hour)
            }
            
            if let minute = dateComponents.minute {
                component.assign(.minute, value: minute)
            }
            
            if let second = dateComponents.second {
                component.assign(.second, value: second)
            }
        }
        
        component.addTag("ENRelativeDateFormatParser")
        return component
    }
}