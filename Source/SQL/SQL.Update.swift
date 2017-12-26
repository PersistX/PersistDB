import Foundation

extension SQL {
    internal struct Update {
        internal var table: Table
        internal var values: [String: SQL.Expression]
        internal var predicate: SQL.Expression?
    }
}

extension SQL.Update: Hashable {
    internal var hashValue: Int {
        return table.hashValue
            ^ values.map { $0.key.hashValue ^ $0.value.hashValue }.reduce(0, ^)
            ^ (predicate?.hashValue ?? 0)
    }
    
    internal static func ==(lhs: SQL.Update, rhs: SQL.Update) -> Bool {
        return lhs.table == rhs.table
            && lhs.values == rhs.values
            && lhs.predicate == rhs.predicate
    }
}

extension SQL.Update {
    internal var columns: Set<SQL.Column> {
        return Set(values.keys.map { table[$0] })
    }
    
    internal var sql: SQL {
        let kvs = values.map { SQL("\($0.key) = ") + $0.value.sql }
        let predicate = self.predicate.map { SQL(" WHERE ") + $0.sql }
            ?? SQL("")
        
        return SQL("UPDATE \"\(table.name)\" SET ")
            + kvs.joined(separator: ", ")
            + predicate
    }
}

