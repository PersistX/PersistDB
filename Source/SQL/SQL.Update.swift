import Foundation

extension SQL {
    internal struct Update: Hashable {
        internal var table: Table
        internal var values: [String: SQL.Expression]
        internal var predicate: SQL.Expression?
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
