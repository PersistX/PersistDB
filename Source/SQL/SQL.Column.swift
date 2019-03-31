import Foundation

extension SQL {
    /// A column in a SQL table
    internal struct Column: Hashable {
        /// The table that the column is a part of.
        internal var table: SQL.Table

        /// The name of the column in the table.
        internal var name: String

        /// Initialize the column with the given table and name.
        internal init(table: SQL.Table, name: String) {
            self.table = table
            self.name = name
        }
    }
}

extension SQL.Column {
    internal var sql: SQL {
        return SQL("\"\(table.name)\".\"\(name)\"")
    }
}
