import Schemata

/// A expression that will be used to group a query.
public struct Grouping<Model: PersistDB.Model, Key: ModelValue>: Hashable {
    /// The underlying expression.
    public var expression: Expression<Model, Key>

    /// Whether the groups should be sorted ascending or descending.
    public var ascending: Bool

    public init(_ expression: Expression<Model, Key>, ascending: Bool = true) {
        self.expression = expression
        self.ascending = ascending
    }
}

extension Grouping where Key == None {
    static var none: Grouping {
        return Grouping(Expression(.value(.null)))
    }
}

extension Grouping {
    var sql: SQL.Ordering {
        return Ordering<Model>(expression.expression, ascending: ascending).sql
    }
}
