import Schemata

/// A type-erased delete action.
internal struct AnyDelete: Hashable {
    internal var schema: AnySchema
    internal var predicate: AnyExpression?

    internal init(_ schema: AnySchema, _ predicate: AnyExpression?) {
        self.schema = schema
        self.predicate = predicate
    }
}

extension AnyDelete {
    internal func makeSQL() -> SQL.Delete {
        return SQL.Delete(
            table: SQL.Table(schema.name),
            predicate: predicate?.sql
        )
    }
}

/// An action that deletes model entities.
public struct Delete<Model: PersistDB.Model>: Hashable {
    public var predicate: Predicate<Model>?

    public init(_ predicate: Predicate<Model>?) {
        self.predicate = predicate
    }
}

extension Delete {
    internal var delete: AnyDelete {
        return AnyDelete(Model.anySchema, predicate?.expression)
    }
}

extension Delete {
    internal func makeSQL() -> SQL.Delete {
        return delete.makeSQL()
    }
}
