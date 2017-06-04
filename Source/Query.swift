import Foundation
import Schemata

/// A value representing a query of a model type.
public struct Query<Model: RecordModel> {
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
    /// Return the results of the query as executed against the given models.
    public func evaluate<C: Collection>(_ models: C) -> [Model] where C.Element == Model {
        var result = Array(models)
        for predicate in predicates {
            result = result.filter(predicate.evaluate)
        }
        return result
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
