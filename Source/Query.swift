import Foundation
import Schemata

/// A value representing a query of a model type.
public struct Query<Model: Schemata.Model> {
    /// The predicates used to filter results.
    public var predicates: [Predicate<Model>]
    
    /// Creates a query that returns all instances of `Model` in the store.
    public init() {
        predicates = []
    }
}

extension Query: Hashable {
    public var hashValue: Int {
        return predicates.map { $0.hashValue }.reduce(0, ^)
    }
    
    public static func ==(lhs: Query, rhs: Query) -> Bool {
        return lhs.predicates == rhs.predicates
    }
}

extension Query {
    /// Returns a query that is filtered by the given predicate.
    public func filter(_ predicate: Predicate<Model>) -> Query {
        var result = self
        result.predicates.append(predicate)
        return result
    }
}
