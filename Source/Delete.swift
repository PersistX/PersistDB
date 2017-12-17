public struct Delete<Model: PersistDB.Model> {
    public var predicate: Predicate<Model>?
    
    public init(_ predicate: Predicate<Model>?) {
        self.predicate = predicate
    }
}

extension Delete: Hashable {
    public var hashValue: Int {
        return (predicate?.hashValue ?? 0)
    }
    
    public static func == (lhs: Delete, rhs: Delete) -> Bool {
        return lhs.predicate == rhs.predicate
    }
}

extension Delete {
    internal var sql: SQL.Delete {
        return SQL.Delete(
            table: SQL.Table(Model.schema.name),
            predicate: predicate?.sql
        )
    }
}


