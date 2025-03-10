// JACasualDateParser.swift - Parser for Japanese casual date expressions
import Foundation

/// Parser for Japanese casual date references like "今日", "昨日", "明日" etc.
public final class JACasualDateParser: Parser {
    /// The pattern to match Japanese casual date references
    public func pattern(context: ParsingContext) -> String {
        return "今日|きょう|当日|とうじつ|昨日|きのう|一昨日|おととい|明日|あした|明後日|あさって|今夜|こんや|今晩|こんばん|今夕|こんゆう|今朝|けさ|夕方|ゆうがた|午前|ごぜん|午後|ごご|夜|よる|朝|あさ"
    }
    
    /// Normalizes hiragana text to kanji
    private func normalizeToKanji(_ text: String) -> String {
        switch text {
        case "きょう":
            return "今日"
        case "とうじつ":
            return "当日"
        case "きのう":
            return "昨日"
        case "おととい":
            return "一昨日"
        case "あした":
            return "明日"
        case "あさって":
            return "明後日"
        case "こんや":
            return "今夜"
        case "こんばん":
            return "今晩"
        case "こんゆう":
            return "今夕"
        case "けさ":
            return "今朝"
        case "ゆうがた":
            return "夕方"
        case "ごぜん":
            return "午前"
        case "ごご":
            return "午後"
        case "よる":
            return "夜"
        case "あさ":
            return "朝"
        default:
            return text
        }
    }
    
    /// Extracts date components from a Japanese casual date reference
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let component = context.createParsingComponents()
        
        let matchText = normalizeToKanji(match.matchedText)
        let refDate = context.refDate
        let calendar = Calendar.current
        
        switch matchText {
        case "今日", "当日":
            // Today
            let components = calendar.dateComponents([.year, .month, .day], from: refDate)
            component.assign(.year, value: components.year ?? 0)
            component.assign(.month, value: components.month ?? 0)
            component.assign(.day, value: components.day ?? 0)
            
        case "昨日":
            // Yesterday
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: refDate) {
                let components = calendar.dateComponents([.year, .month, .day], from: yesterday)
                component.assign(.year, value: components.year ?? 0)
                component.assign(.month, value: components.month ?? 0)
                component.assign(.day, value: components.day ?? 0)
            }
            
        case "一昨日":
            // Day before yesterday
            if let dayBeforeYesterday = calendar.date(byAdding: .day, value: -2, to: refDate) {
                let components = calendar.dateComponents([.year, .month, .day], from: dayBeforeYesterday)
                component.assign(.year, value: components.year ?? 0)
                component.assign(.month, value: components.month ?? 0)
                component.assign(.day, value: components.day ?? 0)
            }
            
        case "明日":
            // Tomorrow
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: refDate) {
                let components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
                component.assign(.year, value: components.year ?? 0)
                component.assign(.month, value: components.month ?? 0)
                component.assign(.day, value: components.day ?? 0)
            }
            
        case "明後日":
            // Day after tomorrow
            if let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: refDate) {
                let components = calendar.dateComponents([.year, .month, .day], from: dayAfterTomorrow)
                component.assign(.year, value: components.year ?? 0)
                component.assign(.month, value: components.month ?? 0)
                component.assign(.day, value: components.day ?? 0)
            }
            
        case "今夜", "今晩", "今夕", "夜":
            // Tonight
            let components = calendar.dateComponents([.year, .month, .day], from: refDate)
            component.assign(.year, value: components.year ?? 0)
            component.assign(.month, value: components.month ?? 0)
            component.assign(.day, value: components.day ?? 0)
            component.assign(.hour, value: 22)
            component.assign(.minute, value: 0)
            component.assign(.meridiem, value: Meridiem.pm.rawValue)
            
        case "今朝", "朝":
            // This morning
            let components = calendar.dateComponents([.year, .month, .day], from: refDate)
            component.assign(.year, value: components.year ?? 0)
            component.assign(.month, value: components.month ?? 0)
            component.assign(.day, value: components.day ?? 0)
            component.assign(.hour, value: 6)
            component.assign(.minute, value: 0)
            component.assign(.meridiem, value: Meridiem.am.rawValue)
            
        case "夕方":
            // Evening
            let components = calendar.dateComponents([.year, .month, .day], from: refDate)
            component.assign(.year, value: components.year ?? 0)
            component.assign(.month, value: components.month ?? 0)
            component.assign(.day, value: components.day ?? 0)
            component.assign(.hour, value: 17)
            component.assign(.minute, value: 0)
            component.assign(.meridiem, value: Meridiem.pm.rawValue)
            
        case "午前":
            // Morning
            let components = calendar.dateComponents([.year, .month, .day], from: refDate)
            component.assign(.year, value: components.year ?? 0)
            component.assign(.month, value: components.month ?? 0)
            component.assign(.day, value: components.day ?? 0)
            component.assign(.hour, value: 9)
            component.assign(.minute, value: 0)
            component.assign(.meridiem, value: Meridiem.am.rawValue)
            
        case "午後":
            // Afternoon
            let components = calendar.dateComponents([.year, .month, .day], from: refDate)
            component.assign(.year, value: components.year ?? 0)
            component.assign(.month, value: components.month ?? 0)
            component.assign(.day, value: components.day ?? 0)
            component.assign(.hour, value: 15)
            component.assign(.minute, value: 0)
            component.assign(.meridiem, value: Meridiem.pm.rawValue)
            
        default:
            return nil
        }
        
        component.addTag("JACasualDateParser")
        return component
    }
}