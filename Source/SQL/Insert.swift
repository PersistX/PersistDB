import Foundation

public protocol InsertValueConvertible {
    var insertValue: SQL.Insert.Value { get }
}

extension SQL {
    public struct Insert {
        public struct Value {
            internal let expression: AnyExpression
            
            internal init(_ expression: AnyExpression) {
                self.expression = expression
            }
        }
        
        public var table: Table
        
        public var values: [String: Value]
    }
}

extension SQL.Insert.Value: Hashable {
    public var hashValue: Int {
        return expression.hashValue
    }
    
    public static func ==(lhs: SQL.Insert.Value, rhs: SQL.Insert.Value) -> Bool {
        return lhs.expression == rhs.expression
    }
}

extension SQL.Insert: Hashable {
    public var hashValue: Int {
        return table.hashValue
            ^ values.map { $0.key.hashValue ^ $0.value.hashValue }.reduce(0, ^)
    }
    
    public static func ==(lhs: SQL.Insert, rhs: SQL.Insert) -> Bool {
        return lhs.table == rhs.table
            && lhs.values == rhs.values
    }
}

extension SQL.Insert {
    public var sql: SQL {
        let kvs = Array(values)
        return SQL("INSERT INTO \"\(table.name)\" ")
            + kvs.map { SQL($0.key) }.joined(separator: ", ").parenthesized
            + SQL(" VALUES ")
            + kvs.map { $0.value.expression.sql }.joined(separator: ", ").parenthesized
    }
}
