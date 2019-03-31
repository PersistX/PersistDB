import Foundation

extension SQL {
    /// A table in a SQL database
    internal struct Table: Hashable {
        /// The name of the table in the database.
        internal var name: String

        /// Initialize the table with a given name
        internal init(_ name: String) {
            self.name = name
        }

        internal subscript(_ name: String) -> SQL.Column {
            return SQL.Column(table: self, name: name)
        }
    }
}

extension SQL.Table {
    internal func insert(_ values: [String: SQL.Expression]) -> SQL.Insert {
        return SQL.Insert(table: self, values: values)
    }
}
