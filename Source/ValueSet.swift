import ReactiveSwift
import Schemata

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

public struct ValueSet<Model: PersistDB.Model> {
    public var assignments: [Assignment<Model>]
    
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
    internal var sufficientForInsert: Bool {
        let assigned = Set(assignments.map { $0.keyPath })
        for property in Model.schema.properties.values {
            if case .value(_, true) = property.type { continue }
            guard assigned.contains(property.keyPath) else { return false }
        }
        return true
    }
}
