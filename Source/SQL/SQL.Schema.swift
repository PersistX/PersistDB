import Foundation

extension SQL {
    /// A description of a table in a database.
    internal struct Schema: Hashable {
        /// A description of a column in a database.
        internal struct Column: Hashable {
            var name: String
            var type: DataType
            var nullable: Bool
            var primaryKey: Bool

            internal init(
                name: String,
                type: DataType,
                nullable: Bool = false,
                primaryKey: Bool = false
            ) {
                self.name = name
                self.type = type
                self.nullable = nullable
                self.primaryKey = primaryKey
            }
        }

        /// The table that the schema describes.
        internal var table: Table

        /// The columns in the table.
        internal var columns: Set<Column>

        internal init(table: Table, columns: Set<Column>) {
            self.table = table
            self.columns = columns
        }
    }
}

extension SQL.Schema.Column {
    fileprivate var sql: SQL {
        var sql: SQL = SQL(name) + " " + type.sql
        if primaryKey {
            sql += " PRIMARY KEY"
        }
        if !nullable {
            sql += " NOT NULL"
        }
        return sql
    }
}

extension SQL.Schema {
    internal var primaryKey: SQL.Column {
        return columns
            .first { $0.primaryKey }
            .map { self.table[$0.name] }!
    }

    /// SQL to create the table with the given schema.
    internal var sql: SQL {
        return SQL("CREATE TABLE \"\(table.name)\" (")
            + columns.map { $0.sql }.joined(separator: ", ")
            + ")"
    }
}

extension SQL.Schema: CustomStringConvertible {
    var description: String {
        return sql.debugDescription
    }
}
