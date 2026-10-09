import Foundation

/// Result of reading a persisted value.
enum StoredValue<Value: Equatable>: Equatable {
    /// Nothing has ever been saved.
    case notSaved
    case loaded(Value)
    /// Something is saved but cannot be decoded.
    case unreadable
}
