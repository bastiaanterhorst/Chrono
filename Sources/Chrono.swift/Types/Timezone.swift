// Timezone.swift - Timezone handling
import Foundation

/// A type representing timezone information that varies between standard and daylight saving time
public struct AmbiguousTimezone {
    /// The timezone offset in minutes during daylight saving time
    let timezoneOffsetDuringDst: Int
    
    /// The timezone offset in minutes during standard time
    let timezoneOffsetNonDst: Int
    
    /// A function that determines the DST start date for a given year
    let dstStart: (Int) -> Date
    
    /// A function that determines the DST end date for a given year
    let dstEnd: (Int) -> Date
}

/// A dictionary mapping timezone abbreviations to their offsets in minutes
public typealias TimezoneAbbrMap = [String: Any]

/// Months used in timezone calculations (1-indexed to match JS implementation)
public enum Month: Int {
    case january = 1
    case february = 2
    case march = 3
    case april = 4
    case may = 5
    case june = 6
    case july = 7
    case august = 8
    case september = 9
    case october = 10
    case november = 11
    case december = 12
}

/// A map of timezone abbreviations to their offset in minutes
@MainActor public let TIMEZONE_ABBR_MAP: TimezoneAbbrMap = [
    "ACDT": 630,
    "ACST": 570,
    "ADT": -180,
    "AEDT": 660,
    "AEST": 600,
    "AFT": 270,
    "AKDT": -480,
    "AKST": -540,
    "ALMT": 360,
    "AMST": -180,
    "AMT": -240,
    "ANAST": 720,
    "ANAT": 720,
    "AQTT": 300,
    "ART": -180,
    "AST": -240,
    "AWDT": 540,
    "AWST": 480,
    "AZOST": 0,
    "AZOT": -60,
    "AZST": 300,
    "AZT": 240,
    "BNT": 480,
    "BOT": -240,
    "BRST": -120,
    "BRT": -180,
    "BST": 60,
    "BTT": 360,
    "CAST": 480,
    "CAT": 120,
    "CCT": 390,
    "CDT": -300,
    "CEST": 120,
    "CET": AmbiguousTimezone(
        timezoneOffsetDuringDst: 2 * 60,
        timezoneOffsetNonDst: 60,
        dstStart: { year in getLastWeekdayOfMonth(year: year, month: .march, weekday: .sunday, hour: 2) },
        dstEnd: { year in getLastWeekdayOfMonth(year: year, month: .october, weekday: .sunday, hour: 3) }
    ),
    "CHADT": 825,
    "CHAST": 765,
    "CKT": -600,
    "CLST": -180,
    "CLT": -240,
    "COT": -300,
    "CST": -360,
    "CT": AmbiguousTimezone(
        timezoneOffsetDuringDst: -5 * 60,
        timezoneOffsetNonDst: -6 * 60,
        dstStart: { year in getNthWeekdayOfMonth(year: year, month: .march, weekday: .sunday, n: 2, hour: 2) },
        dstEnd: { year in getNthWeekdayOfMonth(year: year, month: .november, weekday: .sunday, n: 1, hour: 2) }
    ),
    "CVT": -60,
    "CXT": 420,
    "ChST": 600,
    "DAVT": 420,
    "EASST": -300,
    "EAST": -360,
    "EAT": 180,
    "ECT": -300,
    "EDT": -240,
    "EEST": 180,
    "EET": 120,
    "EGST": 0,
    "EGT": -60,
    "EST": -300,
    "ET": AmbiguousTimezone(
        timezoneOffsetDuringDst: -4 * 60,
        timezoneOffsetNonDst: -5 * 60,
        dstStart: { year in getNthWeekdayOfMonth(year: year, month: .march, weekday: .sunday, n: 2, hour: 2) },
        dstEnd: { year in getNthWeekdayOfMonth(year: year, month: .november, weekday: .sunday, n: 1, hour: 2) }
    ),
    "UTC": 0,
    "GMT": 0
    // Additional timezone entries would be added here
]

/**
 Get the date which is the nth occurrence of a given weekday in a given month and year.
 
 - Parameters:
   - year: The year for which to find the date
   - month: The month in which the date occurs
   - weekday: The weekday on which the date occurs
   - n: The nth occurrence of the given weekday in the month to return
   - hour: The hour of day which should be set on the returned date
 - Returns: The date which is the nth occurrence of a given weekday in a given month and year, at the given hour of day
 */
public func getNthWeekdayOfMonth(year: Int, month: Month, weekday: Weekday, n: Int, hour: Int = 0) -> Date {
    var dayOfMonth = 0
    var i = 0
    
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    
    while i < n {
        dayOfMonth += 1
        let components = DateComponents(year: year, month: month.rawValue, day: dayOfMonth, hour: hour)
        guard let date = calendar.date(from: components) else { continue }
        
        if calendar.component(.weekday, from: date) - 1 == weekday.rawValue {
            i += 1
        }
    }
    
    let components = DateComponents(year: year, month: month.rawValue, day: dayOfMonth, hour: hour)
    return calendar.date(from: components)!
}

/**
 Get the date which is the last occurrence of a given weekday in a given month and year.
 
 - Parameters:
   - year: The year for which to find the date
   - month: The month in which the date occurs
   - weekday: The weekday on which the date occurs
   - hour: The hour of day which should be set on the returned date
 - Returns: The date which is the last occurrence of a given weekday in a given month and year, at the given hour of day
 */
public func getLastWeekdayOfMonth(year: Int, month: Month, weekday: Weekday, hour: Int = 0) -> Date {
    // Procedure: Find the first weekday of the next month, compare with the given weekday,
    // and use the difference to determine how many days to subtract from the first of the next month.
    let oneIndexedWeekday = weekday == .sunday ? 7 : weekday.rawValue
    
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    
    // Get the first day of the next month
    var components = DateComponents(year: year, month: month.rawValue + 1, day: 1, hour: 12)
    if month == .december {
        components = DateComponents(year: year + 1, month: 1, day: 1, hour: 12)
    }
    
    guard let date = calendar.date(from: components) else {
        return Date()
    }
    
    // Get the weekday of the first day of the next month
    let firstWeekdayNextMonth = calendar.component(.weekday, from: date) == 1 ? 7 : calendar.component(.weekday, from: date) - 1
    
    // Calculate the day difference
    var dayDiff: Int
    if firstWeekdayNextMonth == oneIndexedWeekday {
        dayDiff = 7
    } else if firstWeekdayNextMonth < oneIndexedWeekday {
        dayDiff = 7 + firstWeekdayNextMonth - oneIndexedWeekday
    } else {
        dayDiff = firstWeekdayNextMonth - oneIndexedWeekday
    }
    
    // Get the final date
    guard let finalDate = calendar.date(byAdding: .day, value: -dayDiff, to: date) else {
        return Date()
    }
    
    // Set the correct hour
    components = calendar.dateComponents([.year, .month, .day], from: finalDate)
    components.hour = hour
    return calendar.date(from: components)!
}

/// Converts a timezone identifier to an offset in minutes
/// - Parameters:
///   - timezone: The timezone (string identifier or minutes offset)
///   - date: The date for which to calculate the offset
///   - timezoneOverrides: Overrides for timezone abbreviations
/// - Returns: The timezone offset in minutes or nil
@MainActor public func toTimezoneOffset(
    timezone: Any?,
    date: Date,
    timezoneOverrides: TimezoneAbbrMap = [:]
) -> Int? {
    guard let timezone = timezone else { return nil }
    
    // If it's already a numeric offset, return it directly
    if let offset = timezone as? Int {
        return offset
    }
    
    // If it's a string, try to resolve it as a timezone
    if let identifier = timezone as? String {
        guard !identifier.isEmpty else { return nil }
        
        // First try to find it in the overrides
        if let matchedTimezone = timezoneOverrides[identifier] ?? TIMEZONE_ABBR_MAP[identifier] {
            // If it's a simple numeric offset, return it
            if let offset = matchedTimezone as? Int {
                return offset
            }
            
            // If it's an ambiguous timezone, we need date context to determine the offset
            if let ambiguousTimezone = matchedTimezone as? AmbiguousTimezone {
                let calendar = Calendar.current
                let year = calendar.component(.year, from: date)
                
                // Check if the date is within DST period
                let dstStart = ambiguousTimezone.dstStart(year)
                let dstEnd = ambiguousTimezone.dstEnd(year)
                
                if date >= dstStart && date < dstEnd {
                    return ambiguousTimezone.timezoneOffsetDuringDst
                } else {
                    return ambiguousTimezone.timezoneOffsetNonDst
                }
            }
        }
        
        // Try as a standard timezone identifier
        if let timeZone = TimeZone(identifier: identifier) {
            return timeZone.secondsFromGMT(for: date) / 60
        }
    }
    
    return nil
}

/// Reference date with timezone information
public final class ReferenceWithTimezone: @unchecked Sendable {
    /// The reference date
    let instant: Date
    
    /// The timezone offset in minutes
    let timezoneOffset: Int?
    
    /// Creates a new reference with timezone
    /// - Parameter input: The reference or date
    init(_ input: ParsingReference? = nil) {
        if let reference = input {
            self.instant = reference.instant
            
            // Set timezone offset
            if let timezone = reference.timezone {
                // This is a workaround because toTimezoneOffset is @MainActor
                // but we can't use await in an init
                if let offset = timezone as? Int {
                    self.timezoneOffset = offset
                } else if let identifier = timezone as? String {
                    if let timeZone = TimeZone(identifier: identifier) {
                        self.timezoneOffset = timeZone.secondsFromGMT(for: reference.instant) / 60
                    } else {
                        // We'll have to assume a nil offset since we can't
                        // access TIMEZONE_ABBR_MAP which is @MainActor
                        self.timezoneOffset = nil
                    }
                } else {
                    self.timezoneOffset = nil
                }
            } else {
                self.timezoneOffset = nil
            }
        } else {
            self.instant = Date()
            self.timezoneOffset = nil
        }
    }
    
    /// Creates a new reference with timezone from a Date
    /// - Parameter date: The reference date
    init(instant: Date) {
        self.instant = instant
        self.timezoneOffset = nil
    }
    
    /// Returns a date with adjusted timezone
    /// - Returns: A date with the correct timezone
    func getDateWithAdjustedTimezone() -> Date {
        return Date(timeIntervalSince1970: instant.timeIntervalSince1970 + 
                  Double(getSystemTimezoneAdjustmentMinute(date: instant)) * 60.0)
    }
    
    /// Gets the adjustment minutes between system timezone and reference timezone
    /// - Parameters:
    ///   - date: The date to use
    ///   - overrideTimezoneOffset: Optional override offset
    /// - Returns: The number of minutes to adjust
    func getSystemTimezoneAdjustmentMinute(date: Date? = nil, overrideTimezoneOffset: Int? = nil) -> Int {
        let useDate = date ?? Date()
        
        let currentTimezoneOffset = -TimeZone.current.secondsFromGMT(for: useDate) / 60
        let targetTimezoneOffset = overrideTimezoneOffset ?? timezoneOffset ?? currentTimezoneOffset
        
        return currentTimezoneOffset - targetTimezoneOffset
    }
}