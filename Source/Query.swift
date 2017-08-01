import Foundation
import Schemata

/// A value representing a query of a model type.
public struct Query<Model: PersistDB.Model> {
    /// The predicates used to filter results.
    public var predicates: [Predicate<Model>]
    
    /// The sort descriptors used to order results.
    ///
    /// - note: Results are sorted by the first descriptor first. Subsequent descriptors are used
    ///         to break ties.
    public var sortDescriptors: [SortDescriptor<Model>]
    
    /// Creates a query that returns all instances of `Model` in the store.
    public init() {
        predicates = []
        sortDescriptors = []
    }
}

extension Query: Hashable {
    public var hashValue: Int {
        return predicates.map { $0.hashValue }.reduce(0, ^)
            ^ sortDescriptors.map { $0.hashValue }.reduce(0, ^)
    }
    
    public static func ==(lhs: Query, rhs: Query) -> Bool {
        return lhs.predicates == rhs.predicates
            && lhs.sortDescriptors == rhs.sortDescriptors
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
    /// - important: Sort descriptors are inserted into the beginning of the array.
    ///              `.sort(by: \.a, ascending: true).sort(by: \.b, ascending: true)` will sort by
    ///              `b` and use `a` to break ties.
    public func sort(by keyPath: PartialKeyPath<Model>, ascending: Bool) -> Query {
        var result = self
        let descriptor = SortDescriptor(keyPath: keyPath, ascending: ascending)
        result.sortDescriptors.insert(descriptor, at: 0)
        return result
    }
}
