import Foundation

/// The current version of Chrono.swift
public enum ChronoVersion {
    /// The current semantic version of the Chrono.swift package
    #if CHRONO_VERSION_STRING
    public static let current = CHRONO_VERSION_STRING
    #else
    public static let current = "0.1.0"
    #endif
}