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
        let seconds = SQL.Expression.function(.strftime, [
            .value(.text("%s")),
            .value(.text("now")),
        ])
        let subseconds = SQL.Expression.function(.substr, [
            .function(.strftime, [
                .value(.text("%f")),
                .value(.text("now")),
            ]),
            .value(.integer(4)),
        ])
        return Expression(
            .cast(
                .binary(
                    .concatenate,
                    .binary(
                        .subtract,
                        seconds,
                        .value(.integer(Int(Date.timeIntervalBetween1970AndReferenceDate)))
                    ),
                    .binary(
                        .concatenate,
                        .value(.text(".")),
                        subseconds
                    )
                ),
                .real
            )
        )
    }
}

extension Expression where Value == UUID {
    /// An expression that evaluates to a new UUID.
    public static func uuid() -> Expression {
        return Expression(.generator(.uuid))
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
