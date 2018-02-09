import Schemata

/// A type-erased delete action.
internal struct AnyDelete {
    internal var schema: AnySchema
    internal var predicate: AnyExpression?

    internal init(_ schema: AnySchema, _ predicate: AnyExpression?) {
        self.schema = schema
        self.predicate = predicate
    }
}

extension AnyDelete: Hashable {
    var hashValue: Int {
        return (predicate?.hashValue ?? 0)
    }

    static func == (lhs: AnyDelete, rhs: AnyDelete) -> Bool {
        return lhs.schema == rhs.schema && lhs.predicate == rhs.predicate
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
public struct Delete<Model: PersistDB.Model> {
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

extension Delete: Hashable {
    public var hashValue: Int {
        return delete.hashValue
    }

    public static func == (lhs: Delete, rhs: Delete) -> Bool {
        return lhs.delete == rhs.delete
    }
}

extension Delete {
    internal func makeSQL() -> SQL.Delete {
        return delete.makeSQL()
    }
}
