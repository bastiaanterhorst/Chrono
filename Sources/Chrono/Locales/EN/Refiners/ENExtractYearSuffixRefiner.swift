// ENExtractYearSuffixRefiner.swift
import Foundation

/// A refiner that extracts year information from suffixes like "AD", "BC", etc.
public struct ENExtractYearSuffixRefiner: Refiner {
    public init() {}
    
    public func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        var resultsCopy = results
        
        // Process each result
        for i in 0..<resultsCopy.count {
            let result = resultsCopy[i]
            
            // Skip results without a valid start year or those already having a known year
            let components = result.start
            guard let impliedYear = components.get(.year),
                  !components.isCertain(.year) else {
                continue
            }
            
            // Look for year suffixes after the parsed text
            let text = context.text
            let suffix = extractYearSuffix(text: text, result: result)
            
            // If we found a suffix, adjust the year accordingly
            if let suffix = suffix {
                let newComponents = components.clone()
                
                // Handle BC/AD suffix
                if suffix.lowercased() == "bc" || suffix.lowercased() == "b.c." {
                    // BC years are negative (and offset by 1, as there's no year 0)
                    let bcYear = -(impliedYear - 1)
                    newComponents.assign(.year, value: bcYear)
                } else if suffix.lowercased() == "ad" || suffix.lowercased() == "a.d." {
                    // AD years are already positive, just make it certain
                    newComponents.assign(.year, value: impliedYear)
                }
                
                // Update the result with the new components and include the suffix in the matched text
                let index = result.index
                let newText = result.text + suffix
                
                // Create a new result with updated components
                let newResult = context.createParsingResult(
                    index: index,
                    text: newText,
                    start: newComponents,
                    end: result.end
                )
                
                resultsCopy[i] = newResult
            }
        }
        
        return resultsCopy
    }
    
    /// Extracts a year suffix like "BC", "AD" from the text
    private func extractYearSuffix(text: String, result: ParsingResult) -> String? {
        // Calculate where the result text ends in the original string
        let resultEndIndex = result.index + result.text.count
        guard resultEndIndex < text.count else {
            return nil
        }
        
        // Check for BC/AD suffix after the result
        let textAfterResult = String(text[text.index(text.startIndex, offsetBy: resultEndIndex)...])
        
        // Define regex patterns for year suffixes
        let patterns = [
            "^\\s*(A\\.D\\.|AD|B\\.C\\.|BC)\\b",  // Match AD, A.D., BC, B.C.
        ]
        
        // Try each pattern
        for pattern in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                if let match = regex.firstMatch(in: textAfterResult, options: [], range: NSRange(location: 0, length: textAfterResult.utf16.count)) {
                    // Extract the matched suffix
                    let suffixRange = match.range
                    guard let suffixRangeInString = Range(suffixRange, in: textAfterResult) else {
                        continue
                    }
                    
                    return String(textAfterResult[suffixRangeInString])
                }
            } catch {
                // If regex fails, continue to next pattern
                continue
            }
        }
        
        return nil
    }
}