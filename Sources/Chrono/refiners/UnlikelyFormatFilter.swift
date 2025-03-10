import Foundation

/**
 * A refiner that filters out unlikely/impossible date parsing results.
 * For example, it filters out:
 * - Dates with year > 9999 or < 0
 * - Dates with month > 12 or < 1
 * - Dates with day > 31 or < 1
 * - Hours > 24
 * - Minutes/Seconds > 59
 */
public final class UnlikelyFormatFilter: Refiner {
    
    private let strictMode: Bool
    
    public init(strictMode: Bool = false) {
        self.strictMode = strictMode
    }
    
    public func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        return results.filter { result in
            // Filter out results with unlikely year values
            if let year = result.start.get(.year) {
                if year < 0 || year > 9999 {
                    return false
                }
            }
            
            // Filter out results with impossible month values
            if let month = result.start.get(.month) {
                if month < 1 || month > 12 {
                    return false
                }
            }
            
            // Filter out results with impossible day values
            if let day = result.start.get(.day) {
                if day < 1 || day > 31 {
                    return false
                }
                
                // Check for specific month lengths
                if let month = result.start.get(.month), let year = result.start.get(.year) {
                    let isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
                    
                    switch month {
                    case 2: // February
                        let maxDay = isLeapYear ? 29 : 28
                        if day > maxDay {
                            return false
                        }
                    case 4, 6, 9, 11: // April, June, September, November
                        if day > 30 {
                            return false
                        }
                    default:
                        break
                    }
                }
            }
            
            // Filter out results with impossible hour values
            if let hour = result.start.get(.hour) {
                if hour < 0 || hour > 24 {
                    return false
                }
                
                // Hour 24 is only valid if minute, second, and millisecond are all 0
                if hour == 24 {
                    if result.start.get(.minute) != 0 ||
                       result.start.get(.second) != 0 ||
                       result.start.get(.millisecond) != 0 {
                        return false
                    }
                }
            }
            
            // Filter out results with impossible minute/second values
            if let minute = result.start.get(.minute) {
                if minute < 0 || minute > 59 {
                    return false
                }
            }
            
            if let second = result.start.get(.second) {
                if second < 0 || second > 59 {
                    return false
                }
            }
            
            // Apply the same validation to end date if present
            if let end = result.end {
                if let year = end.get(.year) {
                    if year < 0 || year > 9999 {
                        return false
                    }
                }
                
                if let month = end.get(.month) {
                    if month < 1 || month > 12 {
                        return false
                    }
                }
                
                if let day = end.get(.day) {
                    if day < 1 || day > 31 {
                        return false
                    }
                    
                    // Check for specific month lengths
                    if let month = end.get(.month), let year = end.get(.year) {
                        let isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
                        
                        switch month {
                        case 2: // February
                            let maxDay = isLeapYear ? 29 : 28
                            if day > maxDay {
                                return false
                            }
                        case 4, 6, 9, 11: // April, June, September, November
                            if day > 30 {
                                return false
                            }
                        default:
                            break
                        }
                    }
                }
                
                if let hour = end.get(.hour) {
                    if hour < 0 || hour > 24 {
                        return false
                    }
                    
                    // Hour 24 is only valid if minute, second, and millisecond are all 0
                    if hour == 24 {
                        if end.get(.minute) != 0 ||
                           end.get(.second) != 0 ||
                           end.get(.millisecond) != 0 {
                            return false
                        }
                    }
                }
                
                if let minute = end.get(.minute) {
                    if minute < 0 || minute > 59 {
                        return false
                    }
                }
                
                if let second = end.get(.second) {
                    if second < 0 || second > 59 {
                        return false
                    }
                }
            }
            
            // Additional checks for strict mode
            if strictMode {
                // In strict mode, require more components to be present
                if !result.start.isCertain(.day) && !result.start.isCertain(.weekday) {
                    return false
                }
                
                if !result.start.isCertain(.month) {
                    return false
                }
            }
            
            return true
        }
    }
}