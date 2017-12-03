/// An ordering that can be applied to a list of models.
public struct Ordering<Model: PersistDB.Model> {
    internal let sql: SQL.Expression
    internal let ascending: Bool
    
    public init<Value>(_ keyPath: KeyPath<Model, Value>, ascending: Bool = true) {
        self.sql = keyPath.sql
        self.ascending = ascending
    }
    
    internal init(_ sql: SQL.Expression, ascending: Bool = true) {
        self.sql = sql
        self.ascending = ascending
    }
}

extension Ordering: Hashable {
    public var hashValue: Int {
        return sql.hashValue
    }
    
    public static func ==(lhs: Ordering, rhs: Ordering) -> Bool {
        return lhs.sql == rhs.sql && lhs.ascending == rhs.ascending
    }
}
