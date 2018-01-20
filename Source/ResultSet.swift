import Schemata

/// An ordered set of results from a query.
///
/// Result sets that haven't been grouped use `None` as `Key`.
public struct ResultSet<Key: ModelValue, Projection: PersistDB.ModelProjection> {
    /// The groups in the result set.
    public private(set) var groups: [Group<Key, Projection>]

    /// All the values from all the groups in the set.
    private var values: [Projection]

    /// Create an empty result set.
    public init() {
        self.init([])
    }

    /// Create a result set with the given groups.
    public init(_ groups: [Group<Key, Projection>]) {
        self.groups = groups
        values = groups.flatMap { $0.values }
        precondition(Set(groups.map { $0.key }).count == groups.count)
        precondition(Set(values).count == values.count)
    }
}

extension ResultSet where Key == None {
    /// Create a ungrouped result set with the given projections.
    public init(_ projections: [Projection]) {
        self.init([ Group(key: .none, values: projections) ])
    }
}

extension ResultSet: Hashable {
    public var hashValue: Int {
        return groups.map { $0.hashValue }.reduce(0, ^)
    }

    public static func == (lhs: ResultSet, rhs: ResultSet) -> Bool {
        return lhs.groups == rhs.groups
    }
}

extension ResultSet: Collection {
    public var startIndex: Int {
        return values.startIndex
    }

    public var endIndex: Int {
        return values.endIndex
    }

    public subscript(_ i: Int) -> Projection {
        return values[i]
    }

    public func index(after i: Index) -> Index {
        return values.index(after: i)
    }
}
