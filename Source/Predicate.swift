import Foundation
import Schemata

/// A logical condition used for filtering.
public struct Predicate<Model: PersistDB.Model> {
    internal let sql: SQL.Expression
    
    fileprivate init(sql: SQL.Expression) {
        self.sql = sql
    }
}

extension Predicate: Hashable {
    public var hashValue: Int {
        return sql.hashValue
    }
    
    public static func == (lhs: Predicate, rhs: Predicate) -> Bool {
        return lhs.sql == rhs.sql
    }
}

extension Predicate {
    fileprivate init<Model: PersistDB.Model, Value>(
        keyPath: KeyPath<Model, Value>,
        test: (SQL.Expression) -> SQL.Expression
    ) {
        self.sql = Model.schema
            .properties(for: keyPath)
            .map { property -> SQL.Expression in
                let lhsTable = SQL.Table(String(describing: property.model))
                switch property.type {
                case .toMany:
                    fatalError()
                case let .toOne(model):
                    return lhsTable[property.path] == SQL.Table(String(describing: model))["id"]
                case .value:
                    return test(lhsTable[property.path])
                }
            }
            .reduce(nil) { result, expression -> SQL.Expression in
                return result.map { $0 && expression } ?? expression
            }!
    }
}

/// Test that a property of the model matches a value.
public func ==<Model, Value: ModelValue>(lhs: KeyPath<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(keyPath: lhs) {
        return $0 == .value(Value.anyValue.encode(rhs).sql)
    }
}

/// Test that a property of the model matches an optional value.
public func ==<Model, Value: ModelValue>(lhs: KeyPath<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(keyPath: lhs) {
        return $0 == .value(rhs.map(Value.anyValue.encode)?.sql ?? .null)
    }
}

/// Test that a property of the model doesn't matches a value.
public func !=<Model, Value: ModelValue>(lhs: KeyPath<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(keyPath: lhs) {
        return $0 != .value(Value.anyValue.encode(rhs).sql)
    }
}

/// Test that a property of the model doesn't matches an optional value.
public func !=<Model, Value: ModelValue>(lhs: KeyPath<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(keyPath: lhs) {
        return $0 != .value(rhs.map(Value.anyValue.encode)?.sql ?? .null)
    }
}

extension Predicate {
    /// Creates a predicate that's true when both predicates are true.
    public static func &&(lhs: Predicate, rhs: Predicate) -> Predicate {
        fatalError()
    }
    
    /// Creates a predicate that's true when either predicates is true.
    public static func ||(lhs: Predicate, rhs: Predicate) -> Predicate {
        fatalError()
    }
    
    /// Creates a predicate that's true when the given predicate is false.
    public static prefix func !(predicate: Predicate) -> Predicate {
        fatalError()
    }
}
