// FRWeekdayParser.swift - Parser for French weekday expressions
import Foundation

/// Parser for French weekday expressions like "lundi", "mardi prochain", etc.
public final class FRWeekdayParser: Parser {
    /// French weekday pattern
    private let PATTERN = "\\b(" +
                                "dimanche|dim|" +
                                "lundi|lun|" +
                                "mardi|mar|" +
                                "mercredi|mer|" +
                                "jeudi|jeu|" +
                                "vendredi|ven|" +
                                "samedi|sam" +
                           ")" +
                           "(?:\\s*(?:prochain|dernier|suivant|passe|précédent|precedent))?" +
                           "\\b"
    
    /// Maps French weekday names to their numeric values (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
    private let WEEKDAY_DICTIONARY: [String: Int] = [
        "dimanche": 1, "dim": 1,
        "lundi": 2, "lun": 2,
        "mardi": 3, "mar": 3,
        "mercredi": 4, "mer": 4,
        "jeudi": 5, "jeu": 5,
        "vendredi": 6, "ven": 6,
        "samedi": 7, "sam": 7
    ]
    
    /// The pattern to match French weekday expressions
    public func pattern(context: ParsingContext) -> String {
        return PATTERN
    }
    
    /// Extracts weekday components from a French weekday expression
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let component = context.createParsingComponents()
        
        let dayOfWeekText = match.string(at: 1)?.lowercased() ?? ""
        guard let dayOfWeek = WEEKDAY_DICTIONARY[dayOfWeekText] else {
            return nil
        }
        
        // Check for modifiers like "prochain", "dernier", etc.
        let remainingText = match.matchedText.lowercased()
        let isNextWeek = remainingText.contains("prochain") || remainingText.contains("suivant")
        let isLastWeek = remainingText.contains("dernier") || remainingText.contains("passe") || 
                          remainingText.contains("précédent") || remainingText.contains("precedent")
        
        // Get the current date
        let calendar = Calendar.current
        let today = context.refDate
        let dayOfToday = calendar.component(.weekday, from: today)
        
        // Calculate the target date
        var daysToAdd = dayOfWeek - dayOfToday
        
        if daysToAdd < 0 {
            // If the target day is earlier in the week, move to next week
            daysToAdd += 7
        }
        
        if daysToAdd == 0 && !isNextWeek && !isLastWeek {
            // Same day of week and no modifiers, assume it's today
        } else if isNextWeek {
            // "Next" weekday means add a week
            daysToAdd += 7
        } else if isLastWeek {
            // "Last" weekday means go back a week
            daysToAdd -= 7
        }
        
        // Create the result date
        if let targetDate = calendar.date(byAdding: .day, value: daysToAdd, to: today) {
            let components = calendar.dateComponents([.year, .month, .day], from: targetDate)
            component.assign(.year, value: components.year ?? 0)
            component.assign(.month, value: components.month ?? 0)
            component.assign(.day, value: components.day ?? 0)
            component.assign(.weekday, value: dayOfWeek)
        }
        
        component.addTag("FRWeekdayParser")
        return component
    }
}