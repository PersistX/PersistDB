import Foundation

extension SQL {
    /// A SQL `INSERT` statement.
    internal struct Insert: Hashable {
        /// The table that the row should be inserted into.
        internal var table: Table

        /// The values that make up the row, keyed by column name.
        internal var values: [String: SQL.Expression]
    }
}

extension SQL.Insert {
    /// The set of columns that are to be inserted.
    internal var columns: Set<SQL.Column> {
        return Set(values.keys.map { table[$0] })
    }

    /// The SQL string representation of this `Insert`.
    internal var sql: SQL {
        let kvs = Array(values)
        return SQL("INSERT INTO \"\(table.name)\" ")
            + kvs.map { SQL($0.key) }.joined(separator: ", ").parenthesized
            + SQL(" VALUES ")
            + kvs.map { $0.value.sql }.joined(separator: ", ").parenthesized
    }
}
