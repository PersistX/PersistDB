public struct Update<Model: PersistDB.Model> {
    public var predicate: Predicate<Model>?
    public let valueSet: ValueSet<Model>

    public init(predicate: Predicate<Model>?, valueSet: ValueSet<Model>) {
        self.predicate = predicate
        self.valueSet = valueSet
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
        return SQL.Update(
            table: SQL.Table(Model.schema.name),
            values: valueSet.makeSQL(),
            predicate: predicate?.expression.makeSQL()
        )
    }
}
