public struct Insert<Model: PersistDB.Model> {
    internal let valueSet: ValueSet<Model>
    
    public init(_ valueSet: ValueSet<Model>) {
        precondition(valueSet.sufficientForInsert)
        self.valueSet = valueSet
    }
    
    internal init(unvalidated valueSet: ValueSet<Model>) {
        self.valueSet = valueSet
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
    internal var sql: SQL.Insert {
        let table = SQL.Table(Model.schema.name)
        let values = valueSet
            .values
            .map { (keyPath, sql) -> (String, SQL.Expression) in
                let path = Model.schema.properties[keyPath]!.path
                return (path, sql)
            }
        return SQL.Insert(
            table: table,
            values: Dictionary(uniqueKeysWithValues: values)
        )
    }
}
