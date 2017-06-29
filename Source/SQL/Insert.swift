import Foundation

internal protocol InsertValueConvertible {
    var insertValue: SQL.Insert.Value { get }
}

extension SQL {
    internal struct Insert {
        internal struct Value {
            internal let expression: AnyExpression
            
            internal init(_ expression: AnyExpression) {
                self.expression = expression
            }
        }
        
        internal var table: Table
        
        internal var values: [String: Value]
    }
}

extension SQL.Insert.Value: Hashable {
    internal var hashValue: Int {
        return expression.hashValue
    }
    
    internal static func ==(lhs: SQL.Insert.Value, rhs: SQL.Insert.Value) -> Bool {
        return lhs.expression == rhs.expression
    }
}

extension SQL.Insert: Hashable {
    internal var hashValue: Int {
        return table.hashValue
            ^ values.map { $0.key.hashValue ^ $0.value.hashValue }.reduce(0, ^)
    }
    
    internal static func ==(lhs: SQL.Insert, rhs: SQL.Insert) -> Bool {
        return lhs.table == rhs.table
            && lhs.values == rhs.values
    }
}

extension SQL.Insert {
    internal var sql: SQL {
        let kvs = Array(values)
        return SQL("INSERT INTO \"\(table.name)\" ")
            + kvs.map { SQL($0.key) }.joined(separator: ", ").parenthesized
            + SQL(" VALUES ")
            + kvs.map { $0.value.expression.sql }.joined(separator: ", ").parenthesized
    }
}
