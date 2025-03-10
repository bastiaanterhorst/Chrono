import Foundation

/// Functions to include common configuration for all locales
public enum CommonConfiguration {
    
    /// Includes common parsers and refiners for any language configuration
    /// - Parameters:
    ///   - configuration: A Configuration with parsers and refiners to augment
    ///   - strictMode: Whether to use strict mode (default: false)
    /// - Returns: A new Configuration with common parsers and refiners included
    public static func includeCommonConfiguration(parsers: [Parser], refiners: [Refiner], strictMode: Bool = false) -> (parsers: [Parser], refiners: [Refiner]) {
        var updatedParsers = parsers
        var updatedRefiners = refiners
        
        // Add common parsers
        updatedParsers.insert(ISOFormatParser(), at: 0)
        
        // Add common refiners
        updatedRefiners.insert(OverlapRemovalRefiner(), at: 0)
        updatedRefiners.append(ForwardDateRefiner())
        
        // Add additional refiners for timezone handling
        if strictMode {
            updatedRefiners.append(UnlikelyFormatFilter())
        }
        
        return (updatedParsers, updatedRefiners)
    }
}