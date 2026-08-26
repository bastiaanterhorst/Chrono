// Chrono - A natural language date parser
// Port of the JavaScript library: https://github.com/wanasit/chrono

import Foundation

/**
 The main entry point for Chrono date parsing.
 
 Chrono is a natural language date parser that can extract dates and times from text.
 It provides multiple parsing options and supports different locales.
 
 Example:
 ```swift
 let parser = Chrono.casual
 let results = parser.parse("Let's meet tomorrow at 2pm")
 ```
 */
public struct Chrono: Sendable {
    /// The parsers used for extracting dates from text
    private var parsers: [Parser]
    
    /// The refiners used for post-processing parsed results
    private var refiners: [Refiner]
    
    /// Creates a new Chrono instance with the specified parsers and refiners
    /// - Parameters:
    ///   - parsers: An array of parsers to extract dates from text
    ///   - refiners: An array of refiners to post-process parsed results
    public init(parsers: [Parser], refiners: [Refiner]) {
        self.parsers = parsers
        self.refiners = refiners
    }
    
    /// Creates a copy of the Chrono instance with the same parsers and refiners
    /// - Returns: A new Chrono instance
    public func clone() -> Chrono {
        return Chrono(parsers: self.parsers, refiners: self.refiners)
    }
    
    /// Adds a custom parser to the Chrono instance
    /// - Parameter parser: The parser to add
    /// - Returns: Self for chaining
    @discardableResult
    public mutating func addParser(_ parser: Parser) -> Self {
        parsers.append(parser)
        return self
    }
    
    /// Adds a custom refiner to the Chrono instance
    /// - Parameter refiner: The refiner to add
    /// - Returns: Self for chaining
    @discardableResult
    public mutating func addRefiner(_ refiner: Refiner) -> Self {
        refiners.append(refiner)
        return self
    }
    
    /// Parses the text and returns all found date/time occurrences
    /// - Parameters:
    ///   - text: The text to parse
    ///   - referenceDate: The reference date (defaults to current date/time). Can be a Date or ParsingReference.
    ///   - options: Parsing options
    /// - Returns: An array of parsing results
    public func parse(
        text: String,
        referenceDate: Any? = nil,
        options: ParsingOptions? = nil
    ) -> [ParsedResult] {
        let reference: ReferenceWithTimezone
        
        // Handle different types of reference date
        if let refDate = referenceDate as? Date {
            reference = ReferenceWithTimezone(instant: refDate)
        } else if let refDate = referenceDate as? ParsingReference {
            reference = ReferenceWithTimezone(refDate)
        } else if referenceDate == nil {
            reference = ReferenceWithTimezone()
        } else {
            // Unknown type, use current date
            reference = ReferenceWithTimezone()
        }
        
        let resolvedOptions = options ?? ParsingOptions()
        // Hand the week convention to the reference so it reaches every component built from it.
        reference.weekRules = resolvedOptions.weekRules

        let context = ParsingContext(
            text: text,
            reference: reference,
            options: resolvedOptions
        )
        
        var results: [ParsingResult] = []
        
        // Execute each parser
        for parser in parsers {
            let parsedResults = Chrono.executeParser(context: context, parser: parser)
            results.append(contentsOf: parsedResults)
        }
        
        // Sort results by index
        results.sort { $0.index < $1.index }
        
        // Apply refiners
        for refiner in refiners {
            results = refiner.refine(context: context, results: results)
        }

        // Re-sort by text index after refiners. Some refiners (merge/overlap) reorder results via
        // sets keyed on reference identity, so their output order is process-dependent. Restoring a
        // stable index order here makes parse() deterministic for every locale and consumer.
        results.sort { $0.index < $1.index }

        // Convert to public results with additional safety
        return results.compactMap {
            // toPublicResult now returns an optional, so this will filter out nils
            return $0.toPublicResult()
        }
    }
    
    /// A shortcut to parse text and get the first date
    /// - Parameters:
    ///   - text: The text to parse
    ///   - referenceDate: The reference date (defaults to current date/time). Can be a Date or ParsingReference.
    ///   - options: Parsing options
    /// - Returns: The first parsed date or nil if no date was found
    public func parseDate(
        text: String,
        referenceDate: Any? = nil,
        options: ParsingOptions? = nil
    ) -> Date? {
        let results = parse(text: text, referenceDate: referenceDate, options: options)
        return results.first?.start.date
    }
    
    /// Execute a single parser on the text
    /// - Parameters:
    ///   - context: The parsing context
    ///   - parser: The parser to execute
    /// - Returns: An array of parsing results
    private static func executeParser(context: ParsingContext, parser: Parser) -> [ParsingResult] {
        var results: [ParsingResult] = []
        
        // Get the pattern to search for
        let pattern = parser.pattern(context: context)
        
        // Original text to search in
        let originalText = context.text
        
        // Guard against empty text or pattern
        guard !originalText.isEmpty, !pattern.isEmpty else {
            return []
        }
        
        // Create regex (memoized — see `RegexCache`)
        guard let regex = RegexCache.regex(for: pattern, debug: context.debug) else {
            return []
        }
        
        // Initial search range
        var searchRange = NSRange(location: 0, length: originalText.utf16.count)
        
        // Loop to find all matches
        while searchRange.location < originalText.utf16.count && searchRange.length > 0 {
            // Find next match in the current search range
            // `.withoutAnchoringBounds` keeps `^` and `$` tied to the whole string rather than to
            // this search range. Without it, every time the loop stepped past a rejected match the
            // range start became a fresh `^`, so a pattern guarding its left edge with `(\W|^)`
            // silently stopped guarding: "22.4" was rejected as month 22, retried one digit in, and
            // matched "2.4" — 4 February. Whole-string anchoring is what those guards assume.
            guard let match = regex.firstMatch(in: originalText, options: [.withoutAnchoringBounds],
                                               range: searchRange) else {
                break
            }
            
            // Get the matched text safely
            let nsString = originalText as NSString
            let range = match.range
            
            // Validate range is within bounds
            guard range.location >= 0, range.length >= 0, 
                  range.location < nsString.length,
                  range.location + range.length <= nsString.length,
                  range.length > 0 else {
                // Skip invalid matches by moving forward one character
                searchRange.location += 1
                searchRange.length = originalText.utf16.count - searchRange.location
                continue
            }
            
            guard let matchedText = nsString.substring(with: range).nilIfEmpty() else {
                // Skip empty matches by moving forward one character
                searchRange.location += 1
                searchRange.length = originalText.utf16.count - searchRange.location
                continue
            }
            
            // The match index in the original text
            let index = match.range.location
            
            // Create TextMatch object with sanitized match object
            // This ensures any access to the match's ranges will be safe
            let textMatch = TextMatch(match: match, text: originalText)
            
            // Try to extract date components from the match
            if let extractResult = parser.extract(context: context, match: textMatch) {
                var parsedResult: ParsingResult
                
                // Handle different return types from parser
                if let components = extractResult as? ParsingComponents {
                    parsedResult = context.createParsingResult(
                        index: index,
                        text: textMatch.string(at: 0) ?? matchedText, // Use capture group 0 if available
                        start: components
                    )
                } else if let dict = extractResult as? [Component: Int] {
                    parsedResult = context.createParsingResult(
                        index: index,
                        text: textMatch.string(at: 0) ?? matchedText,
                        start: dict
                    )
                } else if let directResult = extractResult as? ParsingResult {
                    parsedResult = directResult
                } else if let publicResult = extractResult as? ParsedResult {
                    // Some parsers return public ParsedResult directly.
                    // Convert it back to internal ParsingResult for the refiner pipeline.
                    let startComponents = context.createParsingComponents(components: publicResult.start.knownValues)
                    for (component, value) in publicResult.start.impliedValues {
                        startComponents.imply(component, value: value)
                    }
                    
                    let endComponents: ParsingComponents?
                    if let end = publicResult.end {
                        let internalEnd = context.createParsingComponents(components: end.knownValues)
                        for (component, value) in end.impliedValues {
                            internalEnd.imply(component, value: value)
                        }
                        endComponents = internalEnd
                    } else {
                        endComponents = nil
                    }
                    
                    parsedResult = context.createParsingResult(
                        index: publicResult.index,
                        text: publicResult.text,
                        start: startComponents,
                        end: endComponents
                    )
                    
                    // Preserve week-priority behavior for English week parsers.
                    if parser is ENISOWeekNumberParser {
                        parsedResult.addTag("ENISOWeekParser")
                    } else if parser is ENRelativeWeekParser {
                        parsedResult.addTag("ENRelativeWeekParser")
                    }
                } else {
                    // Extraction failed, move search range forward
                    searchRange.location = match.range.location + 1
                    searchRange.length = originalText.utf16.count - searchRange.location
                    continue
                }
                
                // Debug output
                context.debug("Parser \(type(of: parser)) extracted (at index=\(index)) '\(parsedResult.text)'")
                
                // Add result
                results.append(parsedResult)
                
                // Move search range past the current match
                searchRange.location = match.range.location + match.range.length
                searchRange.length = originalText.utf16.count - searchRange.location
            } else {
                // Extraction failed, move search range forward
                searchRange.location = match.range.location + 1
                searchRange.length = originalText.utf16.count - searchRange.location
            }
        }
        
        return results
    }
}

/// Convenience static properties and methods for Chrono
public extension Chrono {
    /// A shortcut for English strict parsing (following formal formats only)
    static var strict: Chrono { EN.strict }
    
    /// A shortcut for English casual parsing (including informal expressions like "tomorrow", "next week", etc.)
    static var casual: Chrono { EN.casual }
    
    /// Namespace for German parsers
    struct de {
        /// German casual parser (including informal expressions)
        public static var casual: Chrono { DE.casual }
        
        /// German strict parser (formal expressions only)
        public static var strict: Chrono { DE.strict }
    }
    
    /// Namespace for Japanese parsers
    struct ja {
        /// Japanese casual parser (including informal expressions)
        public static var casual: Chrono { JA.casual }
        
        /// Japanese strict parser (formal expressions only)
        public static var strict: Chrono { JA.strict }
    }
    
    /// Namespace for French parsers
    struct fr {
        /// French casual parser (including informal expressions)
        public static var casual: Chrono { FR.casual }
        
        /// French strict parser (formal expressions only)
        public static var strict: Chrono { FR.strict }
    }
    
    /// Namespace for Spanish parsers
    struct es {
        /// Spanish casual parser (including informal expressions)
        public static var casual: Chrono { ES.casual }
        
        /// Spanish strict parser (formal expressions only)
        public static var strict: Chrono { ES.strict }
    }
    
    /// Namespace for Portuguese parsers
    struct pt {
        /// Portuguese casual parser (including informal expressions)
        public static var casual: Chrono { PT.casual }
        
        /// Portuguese strict parser (formal expressions only)
        public static var strict: Chrono { PT.strict }
    }
    
    /// Namespace for Chinese parsers
    struct zh {
        /// Chinese casual parser (including informal expressions)
        public static var casual: Chrono { ZH.casual }

        /// Chinese strict parser (formal expressions only)
        public static var strict: Chrono { ZH.strict }
    }

    /// Namespace for Dutch parsers
    struct nl {
        /// Dutch casual parser (including informal expressions)
        public static var casual: Chrono { NL.casual }
        
        /// Dutch strict parser (formal expressions only)
        public static var strict: Chrono { NL.strict }
    }
    
    /// A shortcut for casual.parse()
    static func parse(
        text: String,
        referenceDate: Any? = nil,
        options: ParsingOptions? = nil
    ) -> [ParsedResult] {
        return casual.parse(text: text, referenceDate: referenceDate, options: options)
    }
    
    /// A shortcut for casual.parseDate()
    static func parseDate(
        text: String,
        referenceDate: Any? = nil,
        options: ParsingOptions? = nil
    ) -> Date? {
        return casual.parseDate(text: text, referenceDate: referenceDate, options: options)
    }
}

/// Compiled-pattern memo for `Chrono.executeParser`.
///
/// Every parse used to recompile an `NSRegularExpression` for each of the ~20
/// parsers in a configuration, on every call — so a single keystroke in a text
/// field backed by Chrono paid ~20 regex compilations, and several of those
/// patterns are large alternations built from the month/weekday dictionaries.
///
/// The memo is keyed on the exact pattern string and the options are always
/// `[]`, so a hit is by construction the same regex the old code would have
/// built: parsers are free to vary their pattern by context, because a different
/// pattern is simply a different key. `NSRegularExpression` is documented as
/// thread-safe for matching, and only the dictionary needs guarding. The key
/// space is bounded by the distinct patterns the configurations can emit, so
/// this does not grow without limit.
private enum RegexCache {
    nonisolated(unsafe) private static var cache: [String: NSRegularExpression] = [:]
    private static let lock = NSLock()

    static func regex(for pattern: String, debug: (String) -> Void) -> NSRegularExpression? {
        lock.lock()
        if let hit = cache[pattern] {
            lock.unlock()
            return hit
        }
        lock.unlock()

        let compiled: NSRegularExpression
        do {
            compiled = try NSRegularExpression(pattern: pattern, options: [])
        } catch {
            // Not cached: a pattern that fails to compile is a programming error
            // in the parser, and re-reporting it on every parse is more useful
            // than silently swallowing it after the first.
            debug("Error compiling pattern: \(pattern). Error: \(error)")
            return nil
        }

        lock.lock()
        cache[pattern] = compiled
        lock.unlock()
        return compiled
    }
}
