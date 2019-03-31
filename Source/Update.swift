import Schemata

/// A type-erased update action
internal struct AnyUpdate: Hashable {
    internal var schema: AnySchema
    internal var predicate: AnyExpression?
    internal var valueSet: AnyValueSet
}

extension AnyUpdate {
    internal func makeSQL() -> SQL.Update {
        return SQL.Update(
            table: SQL.Table(schema.name),
            values: valueSet.makeSQL(),
            predicate: predicate?.sql
        )
    }
}

/// An action that updates model entities.
public struct Update<Model: PersistDB.Model>: Hashable {
    public var predicate: Predicate<Model>?
    public let valueSet: ValueSet<Model>

    public init(predicate: Predicate<Model>?, valueSet: ValueSet<Model>) {
        self.predicate = predicate
        self.valueSet = valueSet
    }
}

extension Update {
    internal var update: AnyUpdate {
        return AnyUpdate(
            schema: Model.anySchema,
            predicate: predicate?.expression,
            valueSet: valueSet.valueSet
        )
    }
}

extension Update {
    internal func makeSQL() -> SQL.Update {
        return update.makeSQL()
    }
}
