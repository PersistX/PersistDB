import Foundation
import ReactiveSwift
import Schemata

/// An expression that can be used in `Predicate`s, `Ordering`s, etc.
public struct Expression<Model: PersistDB.Model, Value> {
    internal let sql: SQL.Expression
    
    fileprivate init(_ sql: SQL.Expression) {
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

extension Expression where Value == Date {
    /// An expression that evaluates to the current datetime.
    public static var now: Expression {
        return Expression(.function(.strftime, [
            .value(.text("%s")),
            .value(.text("now")),
        ]))
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

/// Evaluates to the first non-NULL argument, or NULL if all argumnets are NULL.
public func coalesce<Model: PersistDB.Model, Value>(
    _ a: KeyPath<Model, Value?>,
    _ b: KeyPath<Model, Value?>,
    _ rest: KeyPath<Model, Value?>...
) -> Expression<Model, Value?> {
    let args = ([a, b] + rest).map { $0.sql }
    return Expression(.function(.coalesce, args))
}
