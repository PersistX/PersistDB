import Foundation

extension SQL {
    /// Something that can be used as a result in a SQL query.
    internal struct Result: Hashable {
        internal let expression: Expression
        private let alias: String?

        internal init(_ expression: Expression, alias: String? = nil) {
            self.expression = expression
            self.alias = alias
        }

        var sql: SQL {
            if let alias = alias {
                return expression.sql + " AS '\(alias)'"
            }
            return expression.sql
        }

        var tables: Set<Table> {
            return expression.tables
        }

        internal var hashValue: Int {
            return expression.hashValue
        }

        internal static func == (lhs: Result, rhs: Result) -> Bool {
            return lhs.expression == rhs.expression && lhs.alias == rhs.alias
        }

        func `as`(_ alias: String) -> Result {
            return Result(expression, alias: alias)
        }
    }
}

extension SQL {
    /// A SQL query.
    internal struct Query {
        internal var results: [Result]
        internal var predicates: [Expression]
        internal var order: [Ordering]

        internal init(
            results: [Result] = [],
            predicates: [Expression] = [],
            order: [Ordering] = []
        ) {
            self.results = results
            self.predicates = predicates
            self.order = order
        }
    }
}

extension SQL.Query {
    /// Create a new query by selecting results.
    internal static func select(_ results: [SQL.Result]) -> SQL.Query {
        return SQL.Query(results: results)
    }

    /// Add another result to the query.
    internal func select(_ result: SQL.Result) -> SQL.Query {
        var query = self
        query.results.append(result)
        return query
    }

    /// Filter the query by adding a predicate that limits results.
    internal func `where`(_ predicate: SQL.Expression) -> SQL.Query {
        var query = self
        query.predicates.append(predicate)
        return query
    }

    /// Sort the results of the query.
    ///
    /// The first ordering in the list will be the primary ordering. This
    /// supercedes previous sorting.
    internal func sorted(by orderings: [SQL.Ordering]) -> SQL.Query {
        var query = self
        query.order = orderings + query.order
        return query
    }

    /// Sort the results of the query.
    ///
    /// The first ordering in the list will be the primary ordering. This
    /// supercedes previous sorting.
    internal func sorted(by descriptors: SQL.Ordering...) -> SQL.Query {
        return sorted(by: descriptors)
    }

    /// The tables that are a part of this query.
    fileprivate var tables: Set<SQL.Table> {
        let results = self.results.map { $0.tables }
        let predicates = self.predicates.map { $0.tables }
        let order = self.order.map { $0.expression.tables }
        return (results + predicates + order).reduce(Set()) { $0.union($1) }
    }

    /// The SQL for this query.
    internal var sql: SQL {
        let results = self.results.map { $0.sql }.joined(separator: ", ")

        let fromSQL: SQL
        let tables = self.tables
            .map { "\"\($0.name)\"" }
            .joined(separator: ", ")
        if tables.isEmpty {
            fromSQL = SQL()
        } else {
            fromSQL = SQL(" FROM ") + tables
        }

        let whereSQL: SQL
        let predicates
            = self.predicates
            + self.results.flatMap { $0.expression.joins }
            + self.predicates.flatMap { $0.joins }
            + order.flatMap { $0.expression.joins }
        if predicates.isEmpty {
            whereSQL = SQL()
        } else {
            whereSQL = " WHERE " + predicates.map { $0.sql }.joined(separator: " AND ")
        }

        let orderBySQL: SQL
        if order.isEmpty {
            orderBySQL = SQL()
        } else {
            orderBySQL = " ORDER BY " + order.map { $0.sql }.joined(separator: ",")
        }

        return "SELECT " + results
            + fromSQL
            + whereSQL
            + orderBySQL
    }

    /// An expression that tests whether `self` has any results.
    internal var exists: SQL.Expression {
        return .exists(self)
    }
}

extension SQL.Query: Hashable {
    internal var hashValue: Int {
        return results.reduce(0) { $0 ^ $1.hashValue }
            + predicates.reduce(0) { $0 ^ $1.hashValue }
    }

    internal static func == (lhs: SQL.Query, rhs: SQL.Query) -> Bool {
        return lhs.results == rhs.results
            && lhs.predicates == rhs.predicates
            && lhs.order == rhs.order
    }
}

extension SQL.Query {
    private var columns: Set<SQL.Column> {
        let results = self.results.map { $0.expression.columns }
        let predicates = self.predicates.map { $0.columns }
        let order = self.order.map { $0.expression.columns }
        return (results + predicates + order).reduce(Set()) { $0.union($1) }
    }

    internal func invalidated(by action: SQL.Effect) -> Bool {
        switch action {
        case let .inserted(insert, _):
            return !columns.isDisjoint(with: insert.columns)
        case let .deleted(delete):
            return tables.contains(delete.table)
        case let .updated(update):
            return !columns.isDisjoint(with: update.columns)
        }
    }
}
