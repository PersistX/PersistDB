import Foundation
import Schemata

/// A value representing a query of a model type.
public struct Query<Model: RecordModel> {
    /// Creates a query that returns all instances of `Model` in the store.
    public init() {
    }
}

extension Query: Hashable {
    public var hashValue: Int {
        return 0
    }
    
    public static func ==(lhs: Query, rhs: Query) -> Bool {
        return true
    }
}
