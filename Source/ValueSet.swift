import ReactiveSwift
import Schemata

/// An assignment of a value or expression to a model entity's property.
///
/// This is meant to be used in conjunction with `ValueSet`.
public struct Assignment<Model: PersistDB.Model> {
    internal let keyPath: PartialKeyPath<Model>
    internal let sql: SQL.Expression
}

extension Assignment: Hashable {
    public var hashValue: Int {
        return keyPath.hashValue
    }
    
    public static func ==(lhs: Assignment, rhs: Assignment) -> Bool {
        return lhs.keyPath == rhs.keyPath && lhs.sql == rhs.sql
    }
}

public func == <Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value>,
    rhs: Value
) -> Assignment<Model> {
    return Assignment<Model>(keyPath: lhs, sql: rhs.sql)
}

public func == <Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value?>,
    rhs: Value?
) -> Assignment<Model> {
    return Assignment<Model>(keyPath: lhs, sql: rhs.sql)
}

public func == <Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value?>,
    rhs: Value
) -> Assignment<Model> {
    return Assignment<Model>(keyPath: lhs, sql: rhs.sql)
}

public func == <Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value>,
    rhs: Expression<Model, Value>
) -> Assignment<Model> {
    return Assignment<Model>(keyPath: lhs, sql: rhs.sql)
}

public func == <Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value?>,
    rhs: Expression<Model, Value?>
) -> Assignment<Model> {
    return Assignment<Model>(keyPath: lhs, sql: rhs.sql)
}

public func == <Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value?>,
    rhs: Expression<Model, Value>
) -> Assignment<Model> {
    return Assignment<Model>(keyPath: lhs, sql: rhs.sql)
}

/// A set of values that can be used to insert or update a model entity.
public struct ValueSet<Model: PersistDB.Model> {
    public var assignments: [Assignment<Model>]
    
    /// Create a value set from a list of assignments.
    public init(_ assignments: [Assignment<Model>]) {
        self.assignments = assignments
    }
}

extension ValueSet: Hashable {
    public var hashValue: Int {
        return assignments.map { $0.hashValue }.reduce(0, ^)
    }
    
    public static func ==(lhs: ValueSet, rhs: ValueSet) -> Bool {
        return lhs.assignments == rhs.assignments
    }
}

extension ValueSet: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Assignment<Model>...) {
        assignments = elements
    }
}

extension ValueSet {
    /// Test whether the value set can be used for insertion.
    ///
    /// In order to be sufficient, every required property must have a value.
    internal var sufficientForInsert: Bool {
        let assigned = Set(assignments.map { $0.keyPath })
        for property in Model.schema.properties.values {
            switch property.type {
            case .value(_, false), .toOne(_, false):
                guard assigned.contains(property.keyPath)
                    else { return false }
            case .value(_, true), .toOne(_, true), .toMany:
                break
            }
        }
        return true
    }
}
