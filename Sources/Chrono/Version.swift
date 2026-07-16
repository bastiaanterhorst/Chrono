import Foundation

/// The current version of Chrono
public enum ChronoVersion {
    /// The current semantic version of the Chrono package
    #if CHRONO_VERSION_STRING
    public static let current = CHRONO_VERSION_STRING
    #else
    public static let current = "0.2.0"
    #endif
}