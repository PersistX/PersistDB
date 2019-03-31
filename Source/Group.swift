/// A collection of items that have been keyed by some value.
public struct Group<Key: Hashable, Value: Hashable>: Hashable {
    /// The key that identifies this group.
    public let key: Key

    /// The values in this group.
    public var values: [Value]

    public init(key: Key, values: [Value]) {
        self.key = key
        self.values = values
    }
}
