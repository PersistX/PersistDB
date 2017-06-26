import Foundation

extension SQL {
    internal enum UnaryOperator: String {
        case not = "NOT"
    }

    internal enum BinaryOperator: String {
        case and = "AND"
        case equal = "=="
        case greaterThan = ">"
        case `is` = "IS"
        case isNot = "IS NOT"
        case lessThan = "<"
        case notEqual = "!="
        case or = "OR"
    }

    internal enum Function: String {
        case max = "MAX"
        case min = "MIN"
    }

    /// A type-erased SQL expression.
    internal indirect enum AnyExpression {
        case binary(BinaryOperator, AnyExpression, AnyExpression)
        case column(Table, String)
        case exists(Query)
        case function(Function, [AnyExpression])
        case inList(AnyExpression, [Value])
        case unary(UnaryOperator, AnyExpression)
        case value(Value)
    }
}

extension SQL.AnyExpression {
    var sql: SQL {
        switch self {
        case let .binary(op, lhs, rhs):
            return (lhs.sql + " " + SQL(op.rawValue) + " " + rhs.sql).parenthesized
        case let .column(table, name):
            return SQL("\"\(table.name)\".\"\(name)\"")
        case let .exists(query):
            return "EXISTS" + query.sql.parenthesized
        case let .function(function, arguments):
            let args = arguments.map { $0.sql }.joined(separator: ",")
            return SQL(function.rawValue) + args.parenthesized
        case let .inList(expr, values):
            let vs = values.map { $0.sql }.joined(separator: ",")
            return "(" + expr.sql + " IN (" + vs + "))"
        case let .unary(op, expr):
            return (SQL(op.rawValue) + " " + expr.sql).parenthesized
        case let .value(value):
            return value.sql
        }
    }
    
    var tables: Set<SQL.Table> {
        switch self {
        case let .binary(_, lhs, rhs):
            return lhs.tables.union(rhs.tables)
        case let .column(table, _):
            return [table]
        case let .function(_, exprs):
            return exprs.reduce(Set()) { $0.union($1.tables) }
        case let .inList(expr, _), let .unary(_, expr):
            return expr.tables
        case .exists, .value:
            return []
        }
    }
}

extension SQL.AnyExpression: Hashable {
    var hashValue: Int {
        switch self {
        case let .binary(op, lhs, rhs):
            return op.hashValue ^ lhs.hashValue ^ rhs.hashValue
        case let .column(table, name):
            return table.hashValue ^ name.hashValue
        case let .exists(query):
            return query.hashValue
        case let .function(function, arguments):
            return function.hashValue + arguments.reduce(0) { $0 ^ $1.hashValue }
        case let .inList(expr, values):
            return expr.hashValue ^ values.reduce(0) { $0 ^ $1.hashValue }
        case let .unary(op, expr):
            return op.hashValue ^ expr.hashValue
        case let .value(value):
            return value.hashValue
        }
    }
    
    static func == (lhs: SQL.AnyExpression, rhs: SQL.AnyExpression) -> Bool {
        switch (lhs, rhs) {
        case let (.binary(op1, lhs1, rhs1), .binary(op2, lhs2, rhs2)):
            return op1 == op2 && lhs1 == lhs2 && rhs1 == rhs2
        case let (.column(table1, name1), .column(table2, name2)):
            return table1 == table2 && name1 == name2
        case let (.exists(query1), .exists(query2)):
            return query1 == query2
        case let (.function(function1, args1), .function(function2, args2)):
            return function1 == function2 && args1 == args2
        case let (.inList(expr1, values1), .inList(expr2, values2)):
            return expr1 == expr2 && values1 == values2
        case let (.unary(op1, expr1), .unary(op2, expr2)):
            return op1 == op2 && expr1 == expr2
        case let (.value(value1), .value(value2)):
            return value1 == value2
        default:
            return false
        }
    }
}

extension SQL {
    /// An opaque SQL expression.
    public struct Expression<Value>: Hashable {
        internal let expression: AnyExpression
        
        init(_ expression: AnyExpression) {
            self.expression = expression
        }
        
        public var sql: SQL {
            return expression.sql
        }
        
        internal var tables: Set<Table> {
            return expression.tables
        }
        
        public var hashValue: Int {
            return expression.hashValue
        }
        
        public static func == <V>(lhs: Expression<V>, rhs: Expression<V>) -> Bool {
            return lhs.expression == rhs.expression
        }
    }
}

extension SQL.Expression: InsertValueConvertible {
    public var insertValue: SQL.Insert.Value {
        return SQL.Insert.Value(expression)
    }
}

extension SQL.Expression {
    /// A typecasted expression that has an optional value.
    public var optional: SQL.Expression<Value?> {
        return SQL.Expression<Value?>(expression)
    }
}

extension SQL.Expression {
    /// An ascending sort descriptor.
    public var ascending: SQL.SortDescriptor {
        return SQL.SortDescriptor(self, .ascending)
    }
    
    /// A descending sort descriptor.
    public var descending: SQL.SortDescriptor {
        return SQL.SortDescriptor(self, .descending)
    }
}

// MARK: - Generic Operators

public func ==<Value>(lhs: SQL.Expression<Value>, rhs: SQL.Expression<Value>) -> SQL.Expression<Bool> {
    return SQL.Expression(.binary(.equal, lhs.expression, rhs.expression))
}

public func !=<Value>(lhs: SQL.Expression<Value>, rhs: SQL.Expression<Value>) -> SQL.Expression<Bool> {
    return SQL.Expression(.binary(.notEqual, lhs.expression, rhs.expression))
}

// MARK: - Bool Operators

public func &&(lhs: SQL.Expression<Bool>, rhs: SQL.Expression<Bool>) -> SQL.Expression<Bool> {
    return SQL.Expression(.binary(.and, lhs.expression, rhs.expression))
}

public func ||(lhs: SQL.Expression<Bool>, rhs: SQL.Expression<Bool>) -> SQL.Expression<Bool> {
    return SQL.Expression(.binary(.or, lhs.expression, rhs.expression))
}

public prefix func !(expression: SQL.Expression<Bool>) -> SQL.Expression<Bool> {
    return SQL.Expression(.unary(.not, expression.expression))
}

// MARK: - Int Operators

public func ==(lhs: SQL.Expression<Int>, rhs: Int) -> SQL.Expression<Bool> {
    return SQL.Expression(.binary(.equal, lhs.expression, .value(.integer(rhs))))
}

public func ==(lhs: Int, rhs: SQL.Expression<Int>) -> SQL.Expression<Bool> {
    return rhs == lhs
}

public func !=(lhs: SQL.Expression<Int>, rhs: Int) -> SQL.Expression<Bool> {
    return SQL.Expression(.binary(.notEqual, lhs.expression, .value(.integer(rhs))))
}

public func !=(lhs: Int, rhs: SQL.Expression<Int>) -> SQL.Expression<Bool> {
    return rhs != lhs
}

public func <(lhs: SQL.Expression<Int>, rhs: Int) -> SQL.Expression<Bool> {
    return SQL.Expression(.binary(.lessThan, lhs.expression, .value(.integer(rhs))))
}

public func <(lhs: Int, rhs: SQL.Expression<Int>) -> SQL.Expression<Bool> {
    return rhs > lhs
}

public func >(lhs: SQL.Expression<Int>, rhs: Int) -> SQL.Expression<Bool> {
    return SQL.Expression(.binary(.greaterThan, lhs.expression, .value(.integer(rhs))))
}

public func >(lhs: Int, rhs: SQL.Expression<Int>) -> SQL.Expression<Bool> {
    return rhs < lhs
}

// MARK: - Int? Operators

public func ==(lhs: SQL.Expression<Int?>, rhs: Int?) -> SQL.Expression<Bool> {
    let value = rhs.map(SQL.Value.integer) ?? .null
    return SQL.Expression(.binary(.is, lhs.expression, .value(value)))
}

public func ==(lhs: Int?, rhs: SQL.Expression<Int?>) -> SQL.Expression<Bool> {
    return rhs == lhs
}

public func !=(lhs: SQL.Expression<Int?>, rhs: Int?) -> SQL.Expression<Bool> {
    let value = rhs.map(SQL.Value.integer) ?? .null
    return SQL.Expression(.binary(.isNot, lhs.expression, .value(value)))
}

public func !=(lhs: Int?, rhs: SQL.Expression<Int?>) -> SQL.Expression<Bool> {
    return rhs != lhs
}

// MARK: - String Operators

public func ==(lhs: SQL.Expression<String>, rhs: String) -> SQL.Expression<Bool> {
    return SQL.Expression(.binary(.equal, lhs.expression, .value(.string(rhs))))
}

public func ==(lhs: String, rhs: SQL.Expression<String>) -> SQL.Expression<Bool> {
    return rhs == lhs
}

public func !=(lhs: SQL.Expression<String>, rhs: String) -> SQL.Expression<Bool> {
    return SQL.Expression(.binary(.notEqual, lhs.expression, .value(.string(rhs))))
}

public func !=(lhs: String, rhs: SQL.Expression<String>) -> SQL.Expression<Bool> {
    return rhs != lhs
}

// MARK: - Aggregates

public func max(_ expressions: [SQL.Expression<Int>]) -> SQL.Expression<Int> {
    return SQL.Expression(.function(.max, expressions.map { $0.expression }))
}

public func max(_ expressions: SQL.Expression<Int>...) -> SQL.Expression<Int> {
    return max(expressions)
}

public func max(_ expressions: [SQL.Expression<Int?>]) -> SQL.Expression<Int?> {
    return SQL.Expression(.function(.max, expressions.map { $0.expression }))
}

public func max(_ expressions: SQL.Expression<Int?>...) -> SQL.Expression<Int?> {
    return max(expressions)
}

public func min(_ expressions: [SQL.Expression<Int>]) -> SQL.Expression<Int> {
    return SQL.Expression(.function(.min, expressions.map { $0.expression }))
}

public func min(_ expressions: SQL.Expression<Int>...) -> SQL.Expression<Int> {
    return min(expressions)
}

public func min(_ expressions: [SQL.Expression<Int?>]) -> SQL.Expression<Int?> {
    return SQL.Expression(.function(.min, expressions.map { $0.expression }))
}

public func min(_ expressions: SQL.Expression<Int?>...) -> SQL.Expression<Int?> {
    return min(expressions)
}

// MARK: - Collections

extension Collection where Iterator.Element == String {
    /// An expression that tests whether the list contains the value of an
    /// expression.
    public func contains(_ expression: SQL.Expression<String>) -> SQL.Expression<Bool> {
        return SQL.Expression(.inList(expression.expression, map(SQL.Value.string)))
    }
}
