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
    internal var sql: SQL.Update {
        let table = SQL.Table(Model.schema.name)
        let values = valueSet
            .assignments
            .map { assignment -> (String, SQL.Expression) in
                let path = Model.schema.properties[assignment.keyPath]!.path
                return (path, assignment.sql)
        }
        return SQL.Update(
            table: table,
            values: Dictionary(uniqueKeysWithValues: values),
            predicate: predicate?.sql
        )
    }
}

