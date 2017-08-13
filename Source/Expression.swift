import Foundation
import ReactiveSwift
import Schemata

/// An expression that can be used in `Predicate`s, `Ordering`s, etc.
public struct Expression<Model: PersistDB.Model, Value> {
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

extension Expression where Value: ModelValue {
    public init(_ value: Value) {
        sql = .value(Value.anyValue.encode(value).sql)
    }
}

extension Expression where Value: OptionalProtocol, Value.Wrapped: ModelValue {
    public init(_ value: Value?) {
        sql = .value(value.map(Value.Wrapped.anyValue.encode)?.sql ?? .null)
    }
}
