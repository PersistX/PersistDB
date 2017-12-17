import Foundation

extension SQL {
    internal struct Delete {
        internal var table: Table
        internal var predicate: SQL.Expression?
    }
}

extension SQL.Delete: Hashable {
    internal var hashValue: Int {
        return table.hashValue ^ (predicate?.hashValue ?? 0)
    }
    
    internal static func ==(lhs: SQL.Delete, rhs: SQL.Delete) -> Bool {
        return lhs.table == rhs.table
            && lhs.predicate == rhs.predicate
    }
}

extension SQL.Delete {
    internal var sql: SQL {
        let predicate = self.predicate.map { SQL(" WHERE ") + $0.sql }
            ?? SQL("")
        
        return SQL("DELETE FROM \"\(table.name)\"") + predicate
    }
}
