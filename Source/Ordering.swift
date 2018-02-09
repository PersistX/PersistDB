/// An ordering that can be applied to a list of models.
public struct Ordering<Model: PersistDB.Model> {
    internal let expression: AnyExpression
    internal let ascending: Bool

    public init<Value>(_ keyPath: KeyPath<Model, Value>, ascending: Bool = true) {
        expression = AnyExpression(keyPath)
        self.ascending = ascending
    }

    internal init(_ expression: AnyExpression, ascending: Bool = true) {
        self.expression = expression
        self.ascending = ascending
    }
}

extension Ordering: Hashable {
    public var hashValue: Int {
        return expression.hashValue
    }

    public static func == (lhs: Ordering, rhs: Ordering) -> Bool {
        return lhs.expression == rhs.expression && lhs.ascending == rhs.ascending
    }
}

extension Ordering {
    internal var sql: SQL.Ordering {
        return SQL.Ordering(expression.sql, ascending ? .ascending : .descending)
    }
}
