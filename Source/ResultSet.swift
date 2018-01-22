import Differ
import Schemata

/// An ordered set of results from a query.
///
/// Result sets that haven't been grouped use `None` as `Key`.
public struct ResultSet<Key: ModelValue, Projection: PersistDB.ModelProjection> {
    /// The groups in the result set.
    public private(set) var groups: [Group<Key, Projection>]

    /// All the values from all the groups in the set.
    fileprivate var values: [Projection]

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

extension ResultSet {
    /// All the keys from all the groups.
    public var keys: [Key] {
        return groups.map { $0.key }
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

private func diff<K, P>(
    from old: ResultSet<K, P>,
    to new: ResultSet<K, P>
) -> ResultSet<K, P>.Diff {
    var diff = ResultSet<K, P>.Diff()

    func indicesByID(in resultSet: ResultSet<K, P>) -> [P.Model.ID: (Int, Int)] {
        var result: [P.Model.ID: (Int, Int)] = [:]
        for (g, group) in resultSet.groups.enumerated() {
            for (v, value) in group.values.enumerated() {
                result[value.id] = (g, v)
            }
        }
        return result
    }

    let oldIndicesByID = indicesByID(in: old)
    let newIndicesByID = indicesByID(in: new)

    // 1. Diff the group keys by themselves.
    //
    // This generates all `deleteGroup`, `insertGroup`, and `moveGroup`s.
    let groupsDiff = old.keys.extendedDiff(new.keys)
    let groupDeltas = groupsDiff
        .elements
        .map { element -> ResultSet<K, P>.Diff.Delta in
            switch element {
            case let .insert(index):
                return .insertGroup(index)
            case let .delete(index):
                return .deleteGroup(index)
            case let .move(from, to):
                return .moveGroup(from, to)
            }
        }
    diff.deltas.formUnion(groupDeltas)
    dump(groupDeltas)

    // 2. Diff the values by themselves.
    var oldGroups = old.groups
    for case let .move(from, to) in groupsDiff.patch(from: old.keys, to: new.keys) {
        let group = oldGroups.remove(at: from)
        oldGroups.insert(group, at: to)
    }
    let oldValues = oldGroups.flatMap { $0.values }
    let newValues = new.values
    let valueElements = oldValues.extendedDiff(newValues).elements
    let moveDeltas = valueElements.flatMap { element -> ResultSet<K, P>.Diff.Delta? in
        guard case let .move(from, _) = element else { return nil }
        let id = old[from].id
        let old = oldIndicesByID[id]!
        let new = newIndicesByID[id]!
        return .updateValue(old.0, old.1, new.0, new.1)
    }
    diff.deltas.formUnion(moveDeltas)
    dump(moveDeltas)

    // 3. Find all inserted, deleted, and changed values by ID
    let addedIDs = Set(valueElements.flatMap { element -> P.Model.ID? in
        guard case let .insert(index) = element else { return nil }
        return new[index].id
    })
    let removedIDs = Set(valueElements.flatMap { element -> P.Model.ID? in
        guard case let .delete(index) = element else { return nil }
        return old[index].id
    })
    let updatedIDs = addedIDs.intersection(removedIDs)
    let insertedIDs = addedIDs.subtracting(updatedIDs)
    let deletedIDs = removedIDs.subtracting(updatedIDs)
    let inserted = insertedIDs
        .map { newIndicesByID[$0]! }
        .map(ResultSet<K, P>.Diff.Delta.insertValue)
    let deleted = deletedIDs
        .map { oldIndicesByID[$0]! }
        .map(ResultSet<K, P>.Diff.Delta.deleteValue)
    let updated = updatedIDs.map { id -> ResultSet<K, P>.Diff.Delta in
        let old = oldIndicesByID[id]!
        let new = newIndicesByID[id]!
        return ResultSet<K, P>.Diff.Delta.updateValue(old.0, old.1, new.0, new.1)
    }
    diff.deltas.formUnion(inserted)
    diff.deltas.formUnion(deleted)
    diff.deltas.formUnion(updated)

    // 4. Check the group boundaries to find additional moves
    let shifted = Set(new.map { $0.id })
        .subtracting(insertedIDs)
        .subtracting(updatedIDs)
        .flatMap { id -> ResultSet<K, P>.Diff.Delta? in
            let oldIndex = oldIndicesByID[id]!
            let newIndex = newIndicesByID[id]!
            let oldKey = old.groups[oldIndex.0].key
            let newKey = new.groups[newIndex.0].key
            if oldKey == newKey { return nil }
            return .updateValue(oldIndex.0, oldIndex.1, newIndex.0, newIndex.1)
        }
    diff.deltas.formUnion(shifted)

    return diff
}

extension ResultSet {
    /// The difference between two result sets.
    public struct Diff {
        /// A change within a diff.
        public enum Delta {
            /// The group at the given index in the old set was deleted.
            ///
            /// Values within the group are assumed to be deleted unless in a `.updateValue`.
            case deleteGroup(Int)
            /// The group at the given index in the new set was inserted.
            case insertGroup(Int)
            /// The group was moved from the given index in the old set to the given index in the
            /// new set.
            case moveGroup(Int, Int)
            /// The value at the given group and value indices in the old set was deleted.
            case deleteValue(Int, Int)
            /// The value at the given group and value indices in the new set was inserted.
            case insertValue(Int, Int)
            /// The values was moved from the given group and value indices in the old set to the
            /// given group and value indices in the new set.
            case updateValue(Int, Int, Int, Int)
        }

        /// The changes that make up the diff.
        public var deltas: Set<Delta>

        /// Create an empty diff.
        public init() {
            deltas = []
        }

        /// Create a diff with the given deltas.
        public init(_ deltas: Set<Delta>) {
            self.deltas = deltas
        }
    }

    /// Calculate the diff from `resultSet` to `self`.
    public func diff(from resultSet: ResultSet) -> Diff {
        return PersistDB.diff(from: resultSet, to: self)
    }
}

extension ResultSet.Diff.Delta: Hashable {
    public var hashValue: Int {
        switch self {
        case let .deleteGroup(i),
             let .insertGroup(i):
            return i
        case let .moveGroup(g1, g2):
            return g1 ^ g2
        case let .deleteValue(g, v),
             let .insertValue(g, v):
            return g ^ v
        case let .updateValue(g1, v1, g2, v2):
            return g1 ^ v1 ^ g2 ^ v2
        }
    }

    public static func == (lhs: ResultSet.Diff.Delta, rhs: ResultSet.Diff.Delta) -> Bool {
        switch (lhs, rhs) {
        case let (.deleteGroup(lhs), .deleteGroup(rhs)),
             let (.insertGroup(lhs), .insertGroup(rhs)):
            return lhs == rhs
        case let (.moveGroup(lhs), .moveGroup(rhs)):
            return lhs == rhs
        case let (.deleteValue(lhs), .deleteValue(rhs)),
             let (.insertValue(lhs), .insertValue(rhs)):
            return lhs == rhs
        case let (.updateValue(lhs), .updateValue(rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}

extension ResultSet.Diff: Hashable {
    public var hashValue: Int {
        return deltas.map { $0.hashValue }.reduce(0, ^)
    }

    public static func == (lhs: ResultSet.Diff, rhs: ResultSet.Diff) -> Bool {
        return lhs.deltas == rhs.deltas
    }
}
