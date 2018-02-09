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
        return SQL.Insert(
            table: SQL.Table(Model.schema.name),
            values: valueSet.makeSQL()
        )
    }
}
