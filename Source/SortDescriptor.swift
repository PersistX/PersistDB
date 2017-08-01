/// A sort order that can be applied to a list of models.
public struct SortDescriptor<Model: PersistDB.Model> {
    public let keyPath: PartialKeyPath<Model>
    public let ascending: Bool
    
    public init(keyPath: PartialKeyPath<Model>, ascending: Bool) {
        self.keyPath = keyPath
        self.ascending = ascending
    }
}

extension SortDescriptor: Hashable {
    public var hashValue: Int {
        return keyPath.hashValue
    }
    
    public static func ==(lhs: SortDescriptor, rhs: SortDescriptor) -> Bool {
        return lhs.keyPath == rhs.keyPath && lhs.ascending == rhs.ascending
    }
}
