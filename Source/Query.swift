import Foundation
import Schemata

/// A value representing a query of a model type.
public struct Query<Model: PersistDB.Model> {
    /// The predicates used to filter results.
    public var predicates: [Predicate<Model>]

    /// The orderings used to order results.
    ///
    /// - note: Results are sorted by the first ordering first. Subsequent ordering are used
    ///         to break ties.
    public var order: [Ordering<Model>]

    /// Creates a query that returns all instances of `Model` in the store.
    public init() {
        predicates = []
        order = []
    }
}

extension Query: Hashable {
    public var hashValue: Int {
        return predicates.map { $0.hashValue }.reduce(0, ^)
            ^ order.map { $0.hashValue }.reduce(0, ^)
    }

    public static func == (lhs: Query, rhs: Query) -> Bool {
        return lhs.predicates == rhs.predicates
            && lhs.order == rhs.order
    }
}

extension Query {
    internal func makeSQL() -> SQL.Query {
        return SQL.Query(
            predicates: predicates.map { $0.expression.makeSQL() },
            order: order.map { $0.makeSQL() }
        )
    }
}

extension Query {
    /// Returns a query that is filtered by the given predicate.
    public func filter(_ predicate: Predicate<Model>) -> Query {
        var result = self
        result.predicates.append(predicate)
        return result
    }

    /// Returns a query that is sorted by the given keypath.
    ///
    /// - important: Orderings are inserted into the beginning of the array.
    ///              `.sort(by: \.a, ascending: true).sort(by: \.b, ascending: true)` will sort by
    ///              `b` and use `a` to break ties.
    public func sort<Value>(by keyPath: KeyPath<Model, Value>, ascending: Bool = true) -> Query {
        var result = self
        let descriptor = Ordering(keyPath, ascending: ascending)
        result.order.insert(descriptor, at: 0)
        return result
    }

    /// Returns a query that is sorted by the given expression.
    ///
    /// - important: Orderings are inserted into the beginning of the array.
    ///              `.sort(by: \.a, ascending: true).sort(by: \.b, ascending: true)` will sort by
    ///              `b` and use `a` to break ties.
    public func sort<Value>(
        by expression: Expression<Model, Value>,
        ascending: Bool = true
    ) -> Query {
        var result = self
        let descriptor = Ordering<Model>(expression.expression, ascending: ascending)
        result.order.insert(descriptor, at: 0)
        return result
    }
}
