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

/// Test whether a property of the model matches a value.
public func ==<Model, Value: ModelValue>(lhs: KeyPath<Model, Value>, rhs: Value) -> Predicate<Model> {
    let sql = Model.schema
        .properties(for: lhs)
        .map { property -> SQL.Expression in
            let lhsTable = SQL.Table(String(describing: property.model))
            switch property.type {
            case .toMany:
                fatalError()
            case let .toOne(model):
                return lhsTable[property.path] == SQL.Table(String(describing: model))["id"]
            case .value:
                return lhsTable[property.path] == .value(Value.anyValue.encode(rhs).sql)
            }
        }
        .reduce(nil) { result, expression -> SQL.Expression in
            return result.map { $0 && expression } ?? expression
        }!
    
    return Predicate<Model>(sql: sql)
}

/// Test whether a property of the model matches an optional value.
public func ==<Model, Value: ModelValue>(lhs: KeyPath<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    let sql = Model.schema
        .properties(for: lhs)
        .map { property -> SQL.Expression in
            let lhsTable = SQL.Table(String(describing: property.model))
            switch property.type {
            case .toMany:
                fatalError()
            case let .toOne(model):
                return lhsTable[property.path] == SQL.Table(String(describing: model))["id"]
            case .value:
                return lhsTable[property.path] == .value(rhs.map(Value.anyValue.encode)?.sql ?? .null)
            }
        }
        .reduce(nil) { result, expression -> SQL.Expression in
            return result.map { $0 && expression } ?? expression
        }!
    
    return Predicate<Model>(sql: sql)
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
