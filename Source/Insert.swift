import Schemata

/// A type-erased insert action
internal struct AnyInsert {
    internal var schema: AnySchema
    internal var valueSet: AnyValueSet
}

extension AnyInsert: Hashable {
    var hashValue: Int {
        return valueSet.hashValue
    }

    static func == (lhs: AnyInsert, rhs: AnyInsert) -> Bool {
        return lhs.schema == rhs.schema
            && lhs.valueSet == rhs.valueSet
    }
}

extension AnyInsert {
    internal func makeSQL() -> SQL.Insert {
        return SQL.Insert(
            table: SQL.Table(schema.name),
            values: valueSet.makeSQL()
        )
    }
}

/// An action that inserts a model entity.
public struct Insert<Model: PersistDB.Model> {
    public let valueSet: ValueSet<Model>

    public init(_ valueSet: ValueSet<Model>) {
        precondition(valueSet.sufficientForInsert)
        self.valueSet = valueSet
    }

    internal init(unvalidated valueSet: ValueSet<Model>) {
        self.valueSet = valueSet
    }
}

extension Insert {
    internal var insert: AnyInsert {
        return AnyInsert(schema: Model.anySchema, valueSet: valueSet.valueSet)
    }
}

extension Insert: Hashable {
    public var hashValue: Int {
        return valueSet.hashValue
    }

    public static func == (lhs: Insert, rhs: Insert) -> Bool {
        return lhs.valueSet == rhs.valueSet
    }
}

extension Insert: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Assignment<Model>...) {
        valueSet = ValueSet(elements)
    }
}

extension Insert {
    internal func makeSQL() -> SQL.Insert {
        return insert.makeSQL()
    }
}
