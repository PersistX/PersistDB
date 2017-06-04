import Foundation
import Schemata

/// A value representing a query of a model type.
public struct Query<Model: RecordModel> {
    /// The predicate used to filter results, or `nil` if the query isn't
    /// filtered.
    public var predicate: Predicate<Model>?
    
    /// Creates a query that returns all instances of `Model` in the store.
    public init() {
    }
}

extension Query: Hashable {
    public var hashValue: Int {
        return predicate?.hashValue ?? 0
    }
    
    public static func ==(lhs: Query, rhs: Query) -> Bool {
        return lhs.predicate == rhs.predicate
    }
}

extension Query {
    /// Return the results of the query as executed against the given models.
    public func evaluate<C: Collection>(_ models: C) -> [Model] where C.Element == Model {
        var result = Array(models)
        if let predicate = predicate {
            result = result.filter(predicate.evaluate)
        }
        return result
    }
}

extension Query {
    /// Returns a query that is filtered by the given predicate.
    public func filter(_ predicate: Predicate<Model>) -> Query {
        var result = self
        result.predicate = result.predicate.map { $0 && predicate } ?? predicate
        return result
    }
}
