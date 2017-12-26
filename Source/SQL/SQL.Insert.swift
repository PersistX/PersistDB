import Foundation

extension SQL {
    internal struct Insert {
        internal var table: Table
        
        internal var values: [String: SQL.Expression]
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
    internal var columns: Set<SQL.Column> {
        return Set(values.keys.map { table[$0] })
    }
    
    internal var sql: SQL {
        let kvs = Array(values)
        return SQL("INSERT INTO \"\(table.name)\" ")
            + kvs.map { SQL($0.key) }.joined(separator: ", ").parenthesized
            + SQL(" VALUES ")
            + kvs.map { $0.value.sql }.joined(separator: ", ").parenthesized
    }
}
