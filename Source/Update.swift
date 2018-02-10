import Schemata

/// A type-erased update action
internal struct AnyUpdate {
    internal var schema: AnySchema
    internal var predicate: AnyExpression?
    internal var valueSet: AnyValueSet
}

extension AnyUpdate: Hashable {
    var hashValue: Int {
        return valueSet.hashValue
    }

    static func == (lhs: AnyUpdate, rhs: AnyUpdate) -> Bool {
        return lhs.schema == rhs.schema
            && lhs.predicate == rhs.predicate
            && lhs.valueSet == rhs.valueSet
    }
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
public struct Update<Model: PersistDB.Model> {
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

extension Update: Hashable {
    public var hashValue: Int {
        return (predicate?.hashValue ?? 0)
            ^ valueSet.hashValue
    }

    public static func == (lhs: Update, rhs: Update) -> Bool {
        return lhs.predicate == rhs.predicate
            && lhs.valueSet == rhs.valueSet
    }
}

extension Update {
    internal func makeSQL() -> SQL.Update {
        return update.makeSQL()
    }
}
