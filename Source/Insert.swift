import Schemata

/// A type-erased insert action
internal struct AnyInsert: Hashable {
    internal var schema: AnySchema
    internal var valueSet: AnyValueSet
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
public struct Insert<Model: PersistDB.Model>: Hashable {
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
