/// A collection of items that have been keyed by some value.
public struct Group<Key: Hashable, Value: Hashable> {
    /// The key that identifies this group.
    public let key: Key

    /// The values in this group.
    public let values: [Value]

    public init(key: Key, values: [Value]) {
        self.key = key
        self.values = values
    }
}

extension Group: Hashable {
    public var hashValue: Int {
        return key.hashValue
    }

    public static func == (lhs: Group, rhs: Group) -> Bool {
        return lhs.key == rhs.key && lhs.values == rhs.values
    }
}
