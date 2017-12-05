/// An ordering that can be applied to a list of models.
public struct Ordering<Model: PersistDB.Model> {
    internal let sql: SQL.Ordering
    
    public init<Value>(_ keyPath: KeyPath<Model, Value>, ascending: Bool = true) {
        sql = SQL.Ordering(keyPath.sql, ascending ? .ascending : .descending)
    }
    
    internal init(_ sql: SQL.Ordering) {
        self.sql = sql
    }
}

extension Ordering: Hashable {
    public var hashValue: Int {
        return sql.hashValue
    }
    
    public static func ==(lhs: Ordering, rhs: Ordering) -> Bool {
        return lhs.sql == rhs.sql
    }
}
