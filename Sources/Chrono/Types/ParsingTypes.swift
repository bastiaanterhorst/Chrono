// ParsingTypes.swift - Internal types for parsing
import Foundation

/// A match from a regular expression, representing the result of a pattern match
/// This struct helps bridge the gap between Swift's NSRegularExpression and JavaScript's RegExp
public struct TextMatch {
    /// The NSTextCheckingResult from regex matching
    let match: NSTextCheckingResult
    
    /// The text that was matched against
    let text: String
    
    /// Gets the matched string at a specific index
    /// - Parameter index: The capture group index (0 = full match)
    /// - Returns: The captured text
    public func string(at index: Int) -> String? {
        // Basic validation first
        guard index >= 0, index < match.numberOfRanges else { 
            // Out of bounds index - silent failure in production
            return nil 
        }
        
        // Get the range safely
        let range = match.range(at: index)
        
        // Additional validation
        guard range.location != NSNotFound else {
            // This range wasn't captured - silent failure in production
            return nil
        }
        
        // Handle potential range issues with additional guards
        let nsText = text as NSString
        
        // Ensure the range is valid within the text bounds
        guard range.location >= 0 && 
              range.length >= 0 && 
              range.location < nsText.length &&
              range.location + range.length <= nsText.length else {
            // Range is out of bounds - silent failure
            return nil
        }
        
        // Now it's safe to extract the substring
        return nsText.substring(with: range)
    }
    
    /// The full matched string (index 0)
    public var matchedText: String {
        // Use a safer approach that catches potential errors
        if let matchText = string(at: 0) {
            return matchText
        } else {
            // Handle the case where index 0 is somehow invalid
            let nsString = text as NSString
            // Validate the match range more carefully
            let range = match.range
            if range.location != NSNotFound && 
               range.location >= 0 && 
               range.length >= 0 &&
               range.location < nsString.length {
                
                // Get the safe length
                let safeLength = min(range.length, nsString.length - range.location)
                if safeLength > 0 {
                    let safeRange = NSRange(location: range.location, length: safeLength)
                    return nsString.substring(with: safeRange)
                }
            }
            return ""
        }
    }
    
    /// Returns the range in the original string for a capture group
    /// - Parameter index: The capture group index (0 = full match)
    /// - Returns: The range in the original string, or nil if invalid
    public func range(at index: Int) -> NSRange? {
        guard index >= 0, index < match.numberOfRanges else { return nil }
        let range = match.range(at: index)
        guard range.location != NSNotFound else { return nil }
        
        // Additional safety checks and clamping
        let nsString = text as NSString
        guard range.location >= 0 && range.length >= 0 else { return nil }
        guard range.location < nsString.length else { return nil }
        
        // Clamp the length to avoid going beyond string bounds
        let safeLength = min(range.length, nsString.length - range.location)
        if safeLength <= 0 { return nil }
        
        return NSRange(location: range.location, length: safeLength)
    }
    
    /// Returns the starting index in the original string for a capture group
    /// - Parameter index: The capture group index (0 = full match)
    /// - Returns: The start index, or nil if invalid
    public func startIndex(at index: Int) -> Int? {
        guard let range = range(at: index) else { return nil }
        return range.location
    }
    
    /// Returns the ending index in the original string for a capture group
    /// - Parameter index: The capture group index (0 = full match)
    /// - Returns: The end index, or nil if invalid
    public func endIndex(at index: Int) -> Int? {
        guard let range = range(at: index) else { return nil }
        return range.location + range.length
    }
    
    /// Returns the length of a capture group
    /// - Parameter index: The capture group index (0 = full match)
    /// - Returns: The length, or nil if invalid
    public func length(at index: Int) -> Int? {
        guard let range = range(at: index) else { return nil }
        return range.length
    }
    
    /// Checks if a capture group exists and contains a value
    /// - Parameter index: The capture group index
    /// - Returns: True if the group exists and contains a non-empty value
    public func hasValue(at index: Int) -> Bool {
        guard let str = string(at: index), !str.isEmpty else {
            return false
        }
        return true
    }
    
    /// Returns all capture groups as strings
    /// - Returns: An array of strings, one per capture group (including the full match at index 0)
    public func allCaptures() -> [String] {
        var results: [String] = []
        // Safer implementation that skips problematic groups instead of failing
        for i in 0..<match.numberOfRanges {
            if let str = string(at: i) {
                results.append(str)
            }
        }
        return results
    }
    
    /// The full matched string (index 0)
    public var fullMatch: String {
        return matchedText
    }
    
    /// The start index of the full match in the original string
    public var index: Int {
        return match.range.location
    }
    
    /// The number of capture groups (including the full match)
    public var captureCount: Int {
        return match.numberOfRanges
    }
}

/// Protocol for date parsers
public protocol Parser: Sendable {
    /// Returns the regex pattern for this parser
    /// - Parameter context: The parsing context
    /// - Returns: A regular expression pattern string
    func pattern(context: ParsingContext) -> String
    
    /// Extracts date components from a match
    /// - Parameters:
    ///   - context: The parsing context
    ///   - match: The regex match
    /// - Returns: The extracted date components or nil if extraction failed
    func extract(context: ParsingContext, match: TextMatch) -> Any?
}

/// Protocol for result refiners
public protocol Refiner: Sendable {
    /// Refines parsing results
    /// - Parameters:
    ///   - context: The parsing context
    ///   - results: The parsing results to refine
    /// - Returns: The refined parsing results
    func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult]
}

/// Internal result of a parsing operation
public final class ParsingResult: @unchecked Sendable {
    /// The reference date and timezone
    let reference: ReferenceWithTimezone
    
    /// Index in the original text
    let index: Int
    
    /// The text that was matched
    let text: String
    
    /// The start date components
    var start: ParsingComponents
    
    /// The end date components (for ranges)
    var end: ParsingComponents?
    
    /// Tags for this parsing result
    private var tags: Set<String> = []
    
    /// Creates a new parsing result
    /// - Parameters:
    ///   - reference: The reference date/timezone
    ///   - index: The index in the original text
    ///   - text: The matched text
    ///   - start: The start components
    ///   - end: The end components
    init(
        reference: ReferenceWithTimezone,
        index: Int,
        text: String,
        start: ParsingComponents?,
        end: ParsingComponents? = nil
    ) {
        self.reference = reference
        self.index = index
        self.text = text
        self.start = start ?? ParsingComponents(reference: reference)
        self.end = end
    }
    
    /// Adds a tag to this result
    /// - Parameter tag: The tag to add
    func addTag(_ tag: String) {
        tags.insert(tag)
    }
    
    /// Checks if this result has a specific tag
    /// - Parameter tag: The tag to check
    /// - Returns: True if the tag is present
    func hasTag(_ tag: String) -> Bool {
        return tags.contains(tag)
    }
    
    /// Gets all tags
    /// - Returns: Array of all tags
    func getTags() -> [String] {
        return Array(tags)
    }
    
    /// Converts to a public result
    /// - Returns: A public ParsedResult
    func toPublicResult() -> ParsedResult? {
        // Get the start date first to validate it
        guard let startDate = start.date() else { return nil }
        
        // Create public result
        let publicStart = ParsedResultDate(
            date: startDate,
            knownValues: start.knownValuesDictionary,
            impliedValues: start.impliedValuesDictionary
        )
        
        // Handle end date
        let publicEnd: ParsedResultDate?
        if let endComponent = end, let endDate = endComponent.date() {
            publicEnd = ParsedResultDate(
                date: endDate,
                knownValues: endComponent.knownValuesDictionary,
                impliedValues: endComponent.impliedValuesDictionary
            )
        } else {
            publicEnd = nil
        }
        
        return ParsedResult(
            index: index,
            text: text,
            start: publicStart,
            end: publicEnd
        )
    }
}

/// A date/time parsing context
public final class ParsingContext: @unchecked Sendable {
    /// The text being parsed
    let text: String
    
    /// The reference date and timezone
    let reference: ReferenceWithTimezone
    
    /// Parsing options
    let options: ParsingOptions
    
    /// Convenience accessor for the reference date
    var refDate: Date {
        return reference.instant
    }
    
    /// Creates a new parsing context
    /// - Parameters:
    ///   - text: The text to parse
    ///   - reference: The reference date/timezone
    ///   - options: Parsing options
    init(text: String, reference: ReferenceWithTimezone, options: ParsingOptions) {
        self.text = text
        self.reference = reference
        self.options = options
    }
    
    /// Creates a new components object
    /// - Parameter components: Initial components
    /// - Returns: A new parsing components object
    func createParsingComponents(components: [Component: Int]? = nil) -> ParsingComponents {
        return ParsingComponents(reference: reference, knownValues: components ?? [:])
    }
    
    /// Creates a new parsing result
    /// - Parameters:
    ///   - index: Index in the original text
    ///   - text: The matched text
    ///   - start: The start components
    ///   - end: The end components
    /// - Returns: A new parsing result
    func createParsingResult(
        index: Int,
        text: String,
        start: Any? = nil,
        end: Any? = nil
    ) -> ParsingResult {
        let startComponents: ParsingComponents?
        
        if let components = start as? ParsingComponents {
            startComponents = components
        } else if let dict = start as? [Component: Int] {
            startComponents = createParsingComponents(components: dict)
        } else {
            startComponents = nil
        }
        
        let endComponents: ParsingComponents?
        
        if let components = end as? ParsingComponents {
            endComponents = components
        } else if let dict = end as? [Component: Int] {
            endComponents = createParsingComponents(components: dict)
        } else {
            endComponents = nil
        }
        
        return ParsingResult(
            reference: reference,
            index: index,
            text: text,
            start: startComponents,
            end: endComponents
        )
    }
    
    /// Outputs debug information if debugging is enabled
    /// - Parameter message: The debug message
    func debug(_ message: String) {
        if let debugHandler = options.debug as? Bool, debugHandler {
            print("[Chrono] \(message)")
        } else if let debugHandler = options.debug as? (String) -> Void {
            debugHandler(message)
        }
    }
}