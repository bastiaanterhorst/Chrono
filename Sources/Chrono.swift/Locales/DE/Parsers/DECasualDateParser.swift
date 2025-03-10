// DECasualDateParser.swift - Parser for casual date references in German
import Foundation

/// Parser for casual date references in German like "heute", "morgen", "gestern", etc.
public struct DECasualDateParser: Parser {
    public init() {}
    
    public func pattern(context: ParsingContext) -> String {
        // Match both lowercase and uppercase initial letters with word boundaries
        return "(?:\\W|^)([Jj]etzt|[Hh]eute|[Mm]orgen|[Üü]bermorgen|[Uu]ebermorgen|[Gg]estern|[Vv]orgestern|[Ll]etzte\\s*[Nn]acht)(?=\\W|$)"
    }
    
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        // Get the first capture group (the actual date reference)
        guard let dateWord = match.string(at: 1) else {
            return nil
        }
        
        let lowerText = dateWord.lowercased()
        let referenceDate = context.reference.instant
        let components = ParsingComponents(reference: context.reference)
        
        let calendar = Calendar.current
        
        // Process date references
        if lowerText == "heute" || lowerText == "jetzt" {
            // Today
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: referenceDate)
            if let year = dateComponents.year {
                components.assign(.year, value: year)
            }
            if let month = dateComponents.month {
                components.assign(.month, value: month)
            }
            if let day = dateComponents.day {
                components.assign(.day, value: day)
            }
            
        } else if lowerText == "morgen" {
            // Tomorrow
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: referenceDate) {
                let dateComponents = calendar.dateComponents([.year, .month, .day], from: tomorrow)
                if let year = dateComponents.year {
                    components.assign(.year, value: year)
                }
                if let month = dateComponents.month {
                    components.assign(.month, value: month)
                }
                if let day = dateComponents.day {
                    components.assign(.day, value: day)
                }
            }
            
        } else if lowerText == "übermorgen" || lowerText == "uebermorgen" {
            // Day after tomorrow
            if let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: referenceDate) {
                let dateComponents = calendar.dateComponents([.year, .month, .day], from: dayAfterTomorrow)
                if let year = dateComponents.year {
                    components.assign(.year, value: year)
                }
                if let month = dateComponents.month {
                    components.assign(.month, value: month)
                }
                if let day = dateComponents.day {
                    components.assign(.day, value: day)
                }
            }
            
        } else if lowerText == "gestern" {
            // Yesterday
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: referenceDate) {
                let dateComponents = calendar.dateComponents([.year, .month, .day], from: yesterday)
                if let year = dateComponents.year {
                    components.assign(.year, value: year)
                }
                if let month = dateComponents.month {
                    components.assign(.month, value: month)
                }
                if let day = dateComponents.day {
                    components.assign(.day, value: day)
                }
            }
            
        } else if lowerText == "vorgestern" {
            // Day before yesterday
            if let dayBeforeYesterday = calendar.date(byAdding: .day, value: -2, to: referenceDate) {
                let dateComponents = calendar.dateComponents([.year, .month, .day], from: dayBeforeYesterday)
                if let year = dateComponents.year {
                    components.assign(.year, value: year)
                }
                if let month = dateComponents.month {
                    components.assign(.month, value: month)
                }
                if let day = dateComponents.day {
                    components.assign(.day, value: day)
                }
            }
            
        } else if lowerText.contains("letzte") && lowerText.contains("nacht") {
            // Last night (evening of previous day)
            if let lastNight = calendar.date(byAdding: .day, value: -1, to: referenceDate) {
                let dateComponents = calendar.dateComponents([.year, .month, .day], from: lastNight)
                if let year = dateComponents.year {
                    components.assign(.year, value: year)
                }
                if let month = dateComponents.month {
                    components.assign(.month, value: month)
                }
                if let day = dateComponents.day {
                    components.assign(.day, value: day)
                }
                components.assign(.hour, value: 22)
                components.assign(.minute, value: 0)
                components.assign(.second, value: 0)
            }
        }
        
        return components
    }
}