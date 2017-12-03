import Foundation
import Schemata

/// A logical condition used for filtering.
public struct Predicate<Model: PersistDB.Model> {
    internal let sql: SQL.Expression
    
    fileprivate init(_ sql: SQL.Expression) {
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

extension KeyPath where Root: PersistDB.Model {
    var sql: SQL.Expression {
        func column(for property: AnyProperty) -> SQL.Column {
            return SQL.Table(String(describing: property.model))[property.path]
        }
        
        let properties = Root.schema.properties(for: self)
        var value: SQL.Expression = .column(column(for: properties.last!))
        for property in properties.reversed().dropFirst() {
            switch property.type {
            case .toMany:
                fatalError()
            case let .toOne(model):
                let rhs = SQL.Column(
                    table: SQL.Table(String(describing: model)),
                    name: "id"
                )
                value = .join(column(for: property), rhs, value)
            case .value:
                fatalError()
            }
        }
        return value
    }
}

/// Test that a property of the model matches a value.
public func ==<Model, Value: ModelValue>(lhs: KeyPath<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(lhs.sql == .value(Value.anyValue.encode(rhs).sql))
}

/// Test that a property of the model matches an optional value.
public func ==<Model, Value: ModelValue>(lhs: KeyPath<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(lhs.sql == .value(rhs.map(Value.anyValue.encode)?.sql ?? .null))
}

/// Test that an expression matches a value.
public func ==<Model, Value: ModelValue>(lhs: Expression<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(lhs.sql == .value(Value.anyValue.encode(rhs).sql))
}

/// Test that an expression matches an optional value.
public func ==<Model, Value: ModelValue>(lhs: Expression<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(lhs.sql == .value(rhs.map(Value.anyValue.encode)?.sql ?? .null))
}

/// Test that a property of the model doesn't match a value.
public func !=<Model, Value: ModelValue>(lhs: KeyPath<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(lhs.sql != .value(Value.anyValue.encode(rhs).sql))
}

/// Test that a property of the model doesn't match an optional value.
public func !=<Model, Value: ModelValue>(lhs: KeyPath<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(lhs.sql != .value(rhs.map(Value.anyValue.encode)?.sql ?? .null))
}

/// Test that an expression doesn't matc a value.
public func !=<Model, Value: ModelValue>(lhs: Expression<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(lhs.sql != .value(Value.anyValue.encode(rhs).sql))
}

/// Test that an expression doesn't match an optional value.
public func !=<Model, Value: ModelValue>(lhs: Expression<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(lhs.sql != .value(rhs.map(Value.anyValue.encode)?.sql ?? .null))
}

extension Predicate {
    /// Creates a predicate that's true when both predicates are true.
    public static func &&(lhs: Predicate, rhs: Predicate) -> Predicate {
        return Predicate(lhs.sql && rhs.sql)
    }
    
    /// Creates a predicate that's true when either predicates is true.
    public static func ||(lhs: Predicate, rhs: Predicate) -> Predicate {
        return Predicate(lhs.sql || rhs.sql)
    }
    
    /// Creates a predicate that's true when the given predicate is false.
    public static prefix func !(predicate: Predicate) -> Predicate {
        return Predicate(!predicate.sql)
    }
}
