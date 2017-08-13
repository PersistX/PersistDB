import Foundation
import Schemata

/// An expression that can be used in `Predicate`s, `Ordering`s, etc.
public struct Expression<Model: PersistDB.Model, Value: ModelValue> {
    internal let sql: SQL.Expression
    
    fileprivate init(sql: SQL.Expression) {
        self.sql = sql
    }
}

extension Expression: Hashable {
    public var hashValue: Int {
        return sql.hashValue
    }
    
    public static func == (lhs: Expression, rhs: Expression) -> Bool {
        return lhs.sql == rhs.sql
    }
}
