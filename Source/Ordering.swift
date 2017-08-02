/// An ordering that can be applied to a list of models.
public struct Ordering<Model: PersistDB.Model> {
    public let keyPath: PartialKeyPath<Model>
    public let ascending: Bool
    
    public init(_ keyPath: PartialKeyPath<Model>, ascending: Bool = true) {
        self.keyPath = keyPath
        self.ascending = ascending
    }
}

extension Ordering: Hashable {
    public var hashValue: Int {
        return keyPath.hashValue
    }
    
    public static func ==(lhs: Ordering, rhs: Ordering) -> Bool {
        return lhs.keyPath == rhs.keyPath && lhs.ascending == rhs.ascending
    }
}
