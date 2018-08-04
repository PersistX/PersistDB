import Foundation
import Schemata

/// An aggregate value, such as a sum or average.
public struct Aggregate<Model: PersistDB.Model, Value: ModelValue> {
    fileprivate let expression: AnyExpression

    public var predicates: [Predicate<Model>]

    internal init(expression: AnyExpression, predicates: [Predicate<Model>]) {
        self.expression = expression
        self.predicates = predicates
    }
}

extension Aggregate {
    internal var sql: SQL.Query {
        let query = SQL.Query.select([ SQL.Result(expression.sql, alias: "count") ])
        return predicates.reduce(query) { $0.where($1.expression.sql) }
    }

    internal func result(for rows: [SQL.Row]) -> Value {
        precondition(rows.count == 1)
        return Value.decode(rows[0].dictionary["count"]!)
            as! Value // swiftlint:disable:this force_cast
    }
}
