import Schemata

/// A view model for a table of results.
public struct Table<Key: ModelValue, Projection: PersistDB.ModelProjection> {
    /// The result set backing the table.
    public var resultSet: ResultSet<Key, Projection> {
        didSet {
            let ids = Set(resultSet.map { $0.id })
            selectedIDs = selectedIDs.filter(ids.contains)
        }
    }

    /// The IDs of the selected values.
    public var selectedIDs: Set<Projection.Model.ID>

    /// Create an empty table.
    public init() {
        self.init(ResultSet())
    }

    /// Create a table with the given result set and selection.
    public init(
        _ resultSet: ResultSet<Key, Projection>,
        selectedIDs: Set<Projection.Model.ID> = []
    ) {
        self.resultSet = resultSet
        self.selectedIDs = selectedIDs
    }

    /// Create a table with the given groups.
    public init(_ groups: [Group<Key, Projection>]) {
        self.init(ResultSet(groups))
    }
}

extension Table {
    /// A predicate that matches the selected projections' models.
    public var selected: Predicate<Projection.Model>? {
        if selectedIDs.isEmpty { return nil }
        return selectedIDs.contains(Projection.Model.idKeyPath)
    }
}

extension Table where Key == None {
    /// Create a ungrouped table with the given projections.
    public init(_ projections: [Projection]) {
        self.init(ResultSet(projections))
    }
}

extension Table {
    internal func indexPath(forRow row: Int) -> IndexPath {
        if Key.self == None.self {
            return [0, row]
        }

        var index = 0
        for (i, group) in resultSet.groups.enumerated() {
            if index == row {
                return [i]
            }
            index += 1

            let offset = row - index
            let count = group.values.count
            if offset < count {
                return [i, offset]
            }
            index += count
        }
        fatalError("Row \(row) out of bounds")
    }

    internal func row(for indexPath: IndexPath) -> Int {
        let group = indexPath[0]

        var row = 0
        for g in 0..<group {
            row += 1 + resultSet.groups[g].values.count
        }

        if indexPath.count == 2 {
            row += 1 + indexPath[1]
        }

        if Key.self == None.self {
            row -= 1
        }

        return row
    }
}

extension Table {
    /// A row in a `Table`, which is either a `Key` for the group or a `Projection` within it.
    public enum Row {
        case group(Key)
        case value(Projection)
    }

    /// The number of rows in the table.
    ///
    /// - important: This treats the result set as being a flat list. i.e., this count includes both
    ///              the keys and the values from the groups. If this is an _ungrouped_ result set,
    ///              then there are no keys and this will equal `resultSet.count`.
    public var rowCount: Int {
        if Key.self == None.self {
            return resultSet.count
        }
        return resultSet.groups.count + resultSet.values.count
    }

    /// Return the row at the given index.
    ///
    /// - important: Errors if the index is beyond the end of `rowCount`.
    public subscript(_ index: Int) -> Row {
        let path = indexPath(forRow: index)
        let group = resultSet.groups[path[0]]
        if path.count == 2 {
            return .value(group.values[path[1]])
        } else {
            return .group(group.key)
        }
    }

    /// The rows for the selected values.
    public var selectedRows: IndexSet {
        return IndexSet(integersIn: 0..<rowCount)
            .filteredIndexSet { row in
                guard case let .value(projection) = self[row] else { return false }
                return selectedIDs.contains(projection.id)
            }
    }
}

extension Table.Row: Hashable {
    public var hashValue: Int {
        switch self {
        case let .group(key):
            return key.hashValue
        case let .value(projection):
            return projection.hashValue
        }
    }

    public static func == (lhs: Table.Row, rhs: Table.Row) -> Bool {
        switch (lhs, rhs) {
        case let (.group(lhs), .group(rhs)):
            return lhs == rhs
        case let (.value(lhs), .value(rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}

extension Table {
    /// The number of sections in the result set.
    public var sectionCount: Int {
        return resultSet.groups.count
    }

    /// The number of rows in the given section of the result set.
    public func rowCount(inSection section: Int) -> Int {
        return resultSet.groups[section].values.count
    }

    /// The key for the group in the given section.
    public func key(forSection section: Int) -> Key {
        return resultSet.groups[section].key
    }

    /// Return the row at the given index path.
    public subscript(_ indexPath: IndexPath) -> Projection {
        precondition(indexPath.count == 2)
        return resultSet.groups[indexPath[0]].values[indexPath[1]]
    }

    /// The index paths of the selected values.
    public var selectedIndexPaths: Set<IndexPath> {
        return Set(selectedRows.map(indexPath(forRow:)))
    }
}

extension Table {
    /// An index into a result set, which includes both a flat row and a nested index path.
    public struct Index {
        /// The row of the index if treated as a flat result set.
        public let row: Int

        /// The index path of the index if treated as a nested result set.
        public let indexPath: IndexPath

        /// Create a new index.
        public init(row: Int, indexPath: IndexPath) {
            self.row = row
            self.indexPath = indexPath
        }
    }

    /// The difference between two `Table`s.
    ///
    /// This can be used to implement incremental updates.
    public struct Diff {
        /// One of the changes that makes up a diff.
        public enum Delta {
            /// The item at the given index was deleted.
            case delete(Table.Index)

            /// The item at the given index was inserted.
            case insert(Table.Index)

            /// The item was moved and/or altered. The before and after indexes are both given.
            case update(Table.Index, Table.Index)
        }

        /// The deltas that make up the diff.
        public let deltas: Set<Delta>

        /// Create a diff with the given deltas.
        public init(_ deltas: Set<Delta>) {
            self.deltas = deltas
        }
    }

    private func index(group: Int, value: Int? = nil) -> Index {
        let indexPath: IndexPath
        if let value = value {
            indexPath = [group, value]
        } else {
            indexPath = IndexPath(index: group)
        }
        return Index(row: row(for: indexPath), indexPath: indexPath)
    }

    /// Calculate the difference from `Table` to `self`.
    public func diff(from table: Table) -> Diff {

        let deltas = resultSet
            .diff(from: table.resultSet)
            .deltas
            .flatMap { delta -> Diff.Delta? in
                switch delta {
                case .deleteGroup where Key.self == None.self,
                     .insertGroup where Key.self == None.self,
                     .moveGroup where Key.self == None.self:
                    return nil
                case let .deleteGroup(group):
                    return .delete(table.index(group: group))
                case let .insertGroup(group):
                    return .insert(index(group: group))
                case let .moveGroup(old, new):
                    return .update(table.index(group: old), index(group: new))
                case let .deleteValue(group, value):
                    return .delete(table.index(group: group, value: value))
                case let .insertValue(group, value):
                    return .insert(index(group: group, value: value))
                case let .updateValue(oldGroup, oldValue, newGroup, newValue):
                    return .update(
                        table.index(group: oldGroup, value: oldValue),
                        index(group: newGroup, value: newValue)
                    )
                }
            }
        return Diff(Set(deltas))
    }
}

extension Table.Index: Hashable {
    public var hashValue: Int {
        return row
    }

    public static func == (lhs: Table.Index, rhs: Table.Index) -> Bool {
        return lhs.row == rhs.row && lhs.indexPath == rhs.indexPath
    }
}

extension Table.Diff.Delta: Hashable {
    public var hashValue: Int {
        switch self {
        case let .delete(index), let .insert(index):
            return index.hashValue
        case let .update(a, b):
            return a.hashValue ^ b.hashValue
        }
    }

    public static func == (lhs: Table.Diff.Delta, rhs: Table.Diff.Delta) -> Bool {
        switch (lhs, rhs) {
        case let (.delete(lhs), .delete(rhs)),
             let (.insert(lhs), .insert(rhs)):
            return lhs == rhs
        case let (.update(lhs), .update(rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}

extension Table.Diff: Hashable {
    public var hashValue: Int {
        return deltas.map { $0.hashValue }.reduce(0, ^)
    }

    public static func == (lhs: Table.Diff, rhs: Table.Diff) -> Bool {
        return lhs.deltas == rhs.deltas
    }
}
