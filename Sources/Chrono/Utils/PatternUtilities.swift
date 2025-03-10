// PatternUtilities.swift - Utilities for pattern matching

import Foundation

/// Protocol describing dictionary-like structures that can be converted to pattern
public protocol PatternDictionary {
    /// Returns the terms/keys from the dictionary
    func terms() -> [String]
}

extension Array: PatternDictionary where Element == String {
    /// Return the strings directly
    public func terms() -> [String] {
        return self
    }
}

extension Dictionary: PatternDictionary where Key == String {
    /// Return the keys of the dictionary
    public func terms() -> [String] {
        return Array(keys)
    }
}

/// Utilities for pattern generation
public enum PatternUtils {
    /// Creates a regex pattern for repeated time units
    /// - Parameters:
    ///   - prefix: The prefix for the pattern
    ///   - singleTimeunitPattern: The pattern for a single time unit
    ///   - connectorPattern: The pattern for connecting multiple units
    /// - Returns: A regex pattern string
    public static func repeatedTimeunitPattern(
        prefix: String,
        singleTimeunitPattern: String, 
        connectorPattern: String = "\\s{0,5},?\\s{0,5}"
    ) -> String {
        // Convert capturing groups to non-capturing groups, unless they're already non-capturing
        let singleTimeunitPatternNoCapture = singleTimeunitPattern.replacingOccurrences(
            of: "\\((?!\\?)",
            with: "(?:",
            options: .regularExpression
        )
        
        return "\(prefix)\(singleTimeunitPatternNoCapture)(?:\(connectorPattern)\(singleTimeunitPatternNoCapture)){0,10}"
    }
    
    /// Creates a regex pattern that matches any term in the dictionary
    /// - Parameter dictionary: The dictionary or array of terms
    /// - Returns: A regex pattern string
    public static func matchAnyPattern(_ dictionary: PatternDictionary) -> String {
        // Sort terms by length (longest first) to ensure longer matches take precedence
        let sortedTerms = dictionary.terms()
            .sorted { $0.count > $1.count }
        
        // Join terms with OR operator and escape dots
        let joinedTerms = sortedTerms
            .map { $0.replacingOccurrences(of: ".", with: "\\.") }
            .joined(separator: "|")
        
        return "(?:\(joinedTerms))"
    }
    
    /// Creates a word-bounded regex pattern that matches any term in the dictionary
    /// - Parameter dictionary: The dictionary or array of terms
    /// - Returns: A regex pattern string with word boundaries
    public static func matchAnyPatternWithWordBoundary(_ dictionary: PatternDictionary) -> String {
        return "\\b\(matchAnyPattern(dictionary))\\b"
    }
    
    /// Escapes characters that have special meaning in regex
    /// - Parameter string: The string to escape
    /// - Returns: The escaped string
    public static func escapeRegex(_ string: String) -> String {
        // Characters that need to be escaped in regex
        let specialCharacters = "\\^$.|?*+()[]{}"
        var escapedString = ""
        
        for char in string {
            if specialCharacters.contains(char) {
                escapedString.append("\\")
            }
            escapedString.append(char)
        }
        
        return escapedString
    }
}