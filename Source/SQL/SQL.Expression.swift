import Foundation

extension SQL {
    internal enum UnaryOperator: String {
        case not = "NOT"
    }

    internal enum BinaryOperator: String {
        case add = "+"
        case and = "AND"
        case concatenate = "||"
        case equal = "=="
        case greaterThan = ">"
        case greaterThanOrEqual = ">="
        case `is` = "IS"
        case isNot = "IS NOT"
        case lessThan = "<"
        case lessThanOrEqual = "<="
        case notEqual = "!="
        case or = "OR"
        case subtract = "-"
    }

    internal enum Function: String {
        case coalesce = "COALESCE"
        case count = "COUNT"
        case length = "LENGTH"
        case max = "MAX"
        case min = "MIN"
        case strftime = "STRFTIME"
        case substr = "SUBSTR"
    }

    /// A SQL expression.
    internal indirect enum Expression: Hashable {
        case binary(BinaryOperator, Expression, Expression)
        case cast(Expression, DataType)
        case column(Column)
        case exists(Query)
        case function(Function, [Expression])
        case inList(Expression, Set<Expression>)
        case join(Column, Column, Expression)
        case unary(UnaryOperator, Expression)
        case value(Value)
    }
}

extension SQL.Expression {
    var sql: SQL {
        switch self {
        case let .binary(op, lhs, rhs):
            return (lhs.sql + " " + SQL(op.rawValue) + " " + rhs.sql).parenthesized
        case let .cast(expr, type):
            return "CAST" + (expr.sql + " AS " + type.sql).parenthesized
        case let .column(column):
            return column.sql
        case let .exists(query):
            return "EXISTS" + query.sql.parenthesized
        case let .function(function, arguments):
            let args = arguments.map { $0.sql }.joined(separator: ",")
            return SQL(function.rawValue) + args.parenthesized
        case let .inList(expr, list):
            let vs = list.map { $0.sql }.joined(separator: ",")
            return "(" + expr.sql + " IN (" + vs + "))"
        case let .join(_, _, expr):
            return expr.sql
        case let .unary(op, expr):
            return (SQL(op.rawValue) + " " + expr.sql).parenthesized
        case let .value(value):
            return value.sql
        }
    }

    private var expressions: Set<SQL.Expression> {
        switch self {
        case let .binary(_, lhs, rhs):
            return lhs.expressions
                .union(rhs.expressions)
                .union([self])
        case .column,
             .exists,
             .value:
            return [self]
        case let .function(_, exprs):
            return exprs.reduce([self]) { $0.union($1.expressions) }
        case let .inList(expr, list):
            return list.reduce([self, expr]) { $0.union($1.expressions) }
        case let .unary(_, expr),
             let .join(_, _, expr),
             let .cast(expr, _):
            return expr.expressions.union([self])
        }
    }

    var joins: Set<SQL.Expression> {
        var result: Set<SQL.Expression> = []
        for case let .join(a, b, _) in expressions {
            result.insert(.binary(.equal, .column(a), .column(b)))
        }
        return result
    }

    var columns: Set<SQL.Column> {
        var result: Set<SQL.Column> = []
        for case let .column(column) in expressions {
            result.insert(column)
        }
        return result
    }

    var tables: Set<SQL.Table> {
        var result: Set<SQL.Table> = []
        for expr in expressions {
            switch expr {
            case let .column(column):
                result.insert(column.table)
            case let .join(a, b, _):
                result.insert(a.table)
                result.insert(b.table)
            case .binary, .cast, .exists, .function, .inList, .unary, .value:
                break
            }
        }
        return result
    }
}

extension SQL.Expression {
    /// An ascending ordering.
    internal var ascending: SQL.Ordering {
        return SQL.Ordering(self, .ascending)
    }

    /// A descending ordering.
    internal var descending: SQL.Ordering {
        return SQL.Ordering(self, .descending)
    }
}
