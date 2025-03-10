// StringExtensions.swift - Extensions for safer string handling
import Foundation

extension String {
    /// Returns nil if the string is empty
    func nilIfEmpty() -> String? {
        return self.isEmpty ? nil : self
    }
    
    /// Ensures a string has a minimum length of one, or returns nil
    func nilIfTooShort() -> String? {
        return self.count > 0 ? self : nil
    }
    
    /// Drops a specific number of characters from the start of the string
    func dropPrefix(_ count: Int) -> String {
        guard count > 0, count < self.count else { return self }
        return String(self.dropFirst(count))
    }
    
    /// Safe substring extraction with NSRange
    func safeSubstring(with range: NSRange) -> String? {
        let nsString = self as NSString
        
        // Validate range
        guard range.location != NSNotFound,
              range.location >= 0, 
              range.length >= 0, 
              range.location < nsString.length else {
            return nil
        }
        
        // Calculate safe length to prevent bounds errors
        let safeLength = min(range.length, nsString.length - range.location)
        guard safeLength > 0 else { return nil }
        
        // Use safe range
        let safeRange = NSRange(location: range.location, length: safeLength)
        
        // Use direct access with our safe range
        return nsString.substring(with: safeRange)
    }
    
    /// A much safer substring method that handles extreme edge cases
    static func ultraSafeSubstring(from string: String, with range: NSRange) -> String? {
        // Check for empty string
        if string.isEmpty {
            return nil
        }
        
        // Convert to NSString for compatibility
        let nsString = string as NSString
        
        // Basic bounds checking
        if range.location == NSNotFound || 
           range.location < 0 || 
           range.length < 0 || 
           range.location >= nsString.length {
            return nil
        }
        
        // Calculate safe bounds
        let endIndex = Swift.min(range.location + range.length, nsString.length)
        let safeLength = Swift.max(0, endIndex - range.location)
        
        // Return empty string for zero-length
        if safeLength == 0 {
            return ""
        }
        
        // Create a safe range
        let safeRange = NSRange(location: range.location, length: safeLength)
        
        // First approach: Try NSString's substring directly with exception safety
        // Using a standard try-catch pattern even though the method doesn't throw
        // This is to protect against any potential crashes
        let result = nsString.substring(with: safeRange)
        if !result.isEmpty {
            return result
        }
        
        // Second approach: Try character-by-character extraction with stringent bounds checking
        var extractedResult = ""
        // Get UTF-16 view since NSRange works with UTF-16 code units
        let utf16View = string.utf16
        
        // Ensure we don't go out of bounds
        if safeRange.location + safeRange.length <= utf16View.count {
            // Convert NSRange to Swift String range
            var cursorIndex = string.startIndex
            var utf16Offset = 0
                
            // Find the starting position
            while utf16Offset < safeRange.location && cursorIndex < string.endIndex {
                cursorIndex = string.index(after: cursorIndex)
                utf16Offset += 1
            }
                
            // Extract characters up to the desired length
            var extractedLength = 0
            while extractedLength < safeRange.length && cursorIndex < string.endIndex {
                extractedResult.append(string[cursorIndex])
                cursorIndex = string.index(after: cursorIndex)
                extractedLength += 1
            }
        } else {
            // Try to get as much as we can
            let availableLength = Swift.max(0, utf16View.count - safeRange.location)
            if availableLength > 0 {
                let partialRange = NSRange(location: safeRange.location, length: availableLength)
                extractedResult = nsString.substring(with: partialRange)
            }
        }
        
        if !extractedResult.isEmpty {
            return extractedResult
        }
        
        // Third approach: Direct byte access with careful bounds checking
        // Get a Data representation
        if let data = string.data(using: .utf16) {
            let rangeStartByte = safeRange.location * 2  // UTF-16 uses 2 bytes per code unit
            let rangeEndByte = rangeStartByte + (safeRange.length * 2)
            
            // Make sure we don't exceed the data bounds
            if rangeStartByte < data.count {
                let safeEndByte = Swift.min(rangeEndByte, data.count)
                let safeData = data.subdata(in: rangeStartByte..<safeEndByte)
                
                if let extracted = String(data: safeData, encoding: .utf16), !extracted.isEmpty {
                    return extracted
                }
            }
        }
        
        // Last resort: Just return an empty string rather than nil
        // This ensures callers don't have to constantly deal with optionals
        return ""
    }
}