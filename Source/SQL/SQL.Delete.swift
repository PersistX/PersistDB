import Foundation

extension SQL {
    internal struct Delete: Hashable {
        internal var table: Table
        internal var predicate: SQL.Expression?
    }
}

extension SQL.Delete {
    internal var sql: SQL {
        let predicate = self.predicate.map { SQL(" WHERE ") + $0.sql }
            ?? SQL("")

        return SQL("DELETE FROM \"\(table.name)\"") + predicate
    }
}
