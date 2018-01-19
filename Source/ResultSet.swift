import Schemata

/// An ordered set of results from a query.
///
/// Result sets that haven't been grouped use `None` as `Key`.
public struct ResultSet<Key: ModelValue, Projection: PersistDB.ModelProjection> {
    /// The groups in the result set.
    public private(set) var groups: [Group<Key, Projection>]

    /// Create an empty result set.
    public init() {
        self.init([])
    }

    /// Create a result set with the given groups.
    public init(_ groups: [Group<Key, Projection>]) {
        let allValues = groups.flatMap { $0.values }
        precondition(Set(groups.map { $0.key }).count == groups.count)
        precondition(Set(allValues).count == allValues.count)
        self.groups = groups
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
    public struct Index {
        fileprivate var group: Int
        fileprivate var value: Int
    }

    public var startIndex: Index {
        return Index(group: 0, value: 0)
    }

    public var endIndex: Index {
        return Index(group: groups.count, value: 0)
    }

    public subscript(_ i: Index) -> Projection {
        return groups[i.group].values[i.value]
    }

    public func index(after i: Index) -> Index {
        let group = groups[i.group]
        if i.value + 1 < group.values.count {
            return Index(group: i.group, value: i.value + 1)
        } else {
            return Index(group: i.group + 1, value: 0)
        }
    }
}

extension ResultSet.Index: Hashable {
    public var hashValue: Int {
        return group ^ value
    }

    public static func == (lhs: ResultSet.Index, rhs: ResultSet.Index) -> Bool {
        return lhs.group == rhs.group && lhs.value == rhs.value
    }
}

extension ResultSet.Index: Comparable {
    public static func < (lhs: ResultSet.Index, rhs: ResultSet.Index) -> Bool {
        return lhs.group < rhs.group || (lhs.group == rhs.group && lhs.value < rhs.value)
    }
}
