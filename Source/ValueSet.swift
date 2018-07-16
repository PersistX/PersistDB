import ReactiveSwift
import Schemata

/// A value that can be used in an assigment in a value set.
private enum AnyValue {
    case expression(AnyExpression)
    case generator(AnyGenerator)
}

extension AnyValue: Hashable {
    fileprivate var hashValue: Int {
        switch self {
        case let .expression(expression):
            return expression.hashValue
        case let .generator(generator):
            return generator.hashValue
        }
    }

    fileprivate static func == (lhs: AnyValue, rhs: AnyValue) -> Bool {
        switch (lhs, rhs) {
        case let (.expression(lhs), .expression(rhs)):
            return lhs == rhs
        case let (.generator(lhs), .generator(rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}

extension AnyValue {
    fileprivate func makeSQL() -> SQL.Expression {
        switch self {
        case let .expression(expression):
            return expression.sql
        case let .generator(generator):
            return .value(generator.makeSQL())
        }
    }
}

/// An assignment of a value or expression to a model entity's property.
///
/// This is meant to be used in conjunction with `ValueSet`.
public struct Assignment<Model: PersistDB.Model> {
    internal let keyPath: PartialKeyPath<Model>
    fileprivate let value: AnyValue
}

extension Assignment: Hashable {
    public var hashValue: Int {
        return keyPath.hashValue
    }

    public static func == (lhs: Assignment, rhs: Assignment) -> Bool {
        return lhs.keyPath == rhs.keyPath && lhs.value == rhs.value
    }
}

public func == <Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value>,
    rhs: Value
) -> Assignment<Model> {
    return Assignment<Model>(keyPath: lhs, value: .expression(AnyExpression(rhs)))
}

public func == <Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value?>,
    rhs: Value?
) -> Assignment<Model> {
    return Assignment<Model>(keyPath: lhs, value: .expression(AnyExpression(rhs)))
}

public func == <Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value?>,
    rhs: Value
) -> Assignment<Model> {
    return Assignment<Model>(keyPath: lhs, value: .expression(AnyExpression(rhs)))
}

public func == <Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value>,
    rhs: Expression<Model, Value>
) -> Assignment<Model> {
    return Assignment<Model>(keyPath: lhs, value: .expression(rhs.expression))
}

public func == <Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value?>,
    rhs: Expression<Model, Value?>
) -> Assignment<Model> {
    return Assignment<Model>(keyPath: lhs, value: .expression(rhs.expression))
}

public func == <Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value?>,
    rhs: Expression<Model, Value>
) -> Assignment<Model> {
    return Assignment<Model>(keyPath: lhs, value: .expression(rhs.expression))
}

public func == <Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value>,
    rhs: Expression<None, Value>
) -> Assignment<Model> {
    return Assignment<Model>(keyPath: lhs, value: .expression(rhs.expression))
}

public func == <Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value?>,
    rhs: Expression<None, Value?>
) -> Assignment<Model> {
    return Assignment<Model>(keyPath: lhs, value: .expression(rhs.expression))
}

public func == <Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value?>,
    rhs: Expression<None, Value>
) -> Assignment<Model> {
    return Assignment<Model>(keyPath: lhs, value: .expression(rhs.expression))
}

public func == <Model, Value>(
    lhs: KeyPath<Model, Value>,
    rhs: Generator<Value>
) -> Assignment<Model> {
    return Assignment<Model>(keyPath: lhs, value: .generator(rhs.generator))
}

public func == <Model, Value>(
    lhs: KeyPath<Model, Value?>,
    rhs: Generator<Value>
) -> Assignment<Model> {
    return Assignment<Model>(keyPath: lhs, value: .generator(rhs.generator))
}

/// A type-erased `ValueSet`.
internal struct AnyValueSet {
    fileprivate var model: AnySchema
    fileprivate var values: [AnyKeyPath: AnyValue]
}

extension AnyValueSet: Hashable {
    internal var hashValue: Int {
        return model.name.hashValue
            ^ values.lazy.map { $0.key.hashValue ^ $0.value.hashValue }.reduce(0, ^)
    }

    internal static func == (lhs: AnyValueSet, rhs: AnyValueSet) -> Bool {
        return lhs.model == rhs.model && lhs.values == rhs.values
    }
}

extension AnyValueSet {
    /// Create a dictionary of column names to SQL expressions from the value set.
    internal func makeSQL() -> [String: SQL.Expression] {
        let values = self.values.map { keyPath, value -> (String, SQL.Expression) in
            let path = model.properties[keyPath]!.path
            return (path, value.makeSQL())
        }
        return Dictionary(uniqueKeysWithValues: values)
    }
}

/// A set of values that can be used to insert or update a model entity.
public struct ValueSet<Model: PersistDB.Model> {
    /// The assignments/values that make up the value set.
    fileprivate var values: [PartialKeyPath<Model>: AnyValue]

    fileprivate init(_ values: [PartialKeyPath<Model>: AnyValue]) {
        self.values = values
    }

    internal var valueSet: AnyValueSet {
        return AnyValueSet(model: Model.anySchema, values: values)
    }
}

extension ValueSet {
    /// Create an empty value set.
    public init() {
        self.init([:])
    }

    /// Create a value set from a list of assignments.
    public init(_ assignments: [Assignment<Model>]) {
        self.init([:])
        for assignment in assignments {
            values[assignment.keyPath] = assignment.value
        }
    }
}

extension ValueSet {
    /// Create a new value set by replacing values in `self` with the values from `valueSet`.
    public func update(with valueSet: ValueSet) -> ValueSet {
        return ValueSet(values.merging(valueSet.values) { $1 })
    }
}

extension ValueSet: Hashable {
    public var hashValue: Int {
        return values
            .map { $0.key.hashValue ^ $0.value.hashValue }
            .reduce(0, ^)
    }

    public static func == (lhs: ValueSet, rhs: ValueSet) -> Bool {
        return lhs.values == rhs.values
    }
}

extension ValueSet: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Assignment<Model>...) {
        self.init(elements)
    }
}

extension ValueSet {
    /// Create a dictionary of column names to SQL expressions from the value set.
    internal func makeSQL() -> [String: SQL.Expression] {
        return valueSet.makeSQL()
    }

    /// Test whether the value set can be used for insertion.
    ///
    /// In order to be sufficient, every required property must have a value.
    internal var sufficientForInsert: Bool {
        let assigned = Set(values.keys)
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
