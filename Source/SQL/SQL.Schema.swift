import Foundation

extension SQL {
    /// A description of a table in a database.
    internal struct Schema {
        /// The type of data in a column.
        internal enum DataType {
            case text
            case numeric
            case integer
            case real
            case blob
        }
        
        /// A description of a column in a database.
        internal struct Column {
            var name: String
            var type: DataType
            var nullable: Bool
            var unique: Bool
            var primaryKey: Bool
            
            internal init(
                name: String,
                type: DataType,
                nullable: Bool = false,
                unique: Bool = false,
                primaryKey: Bool = false
            ) {
                self.name = name
                self.type = type
                self.nullable = nullable
                self.unique = unique
                self.primaryKey = primaryKey
            }
        }
        
        /// The table that the schema describes.
        internal var table: Table
        
        /// The columns in the table.
        internal var columns: [Column]
        
        internal init(table: Table, columns: [Column]) {
            self.table = table
            self.columns = columns
        }
    }
}

extension SQL.Schema.Column: Hashable {
    internal var hashValue: Int {
        return name.hashValue
    }
    
    internal static func ==(lhs: SQL.Schema.Column, rhs: SQL.Schema.Column) -> Bool {
        return lhs.name == rhs.name
            && lhs.type == rhs.type
            && lhs.nullable == rhs.nullable
            && lhs.unique == rhs.unique
            && lhs.primaryKey == rhs.primaryKey
    }
}

extension SQL.Schema: Hashable {
    internal var hashValue: Int {
        return table.hashValue
    }
    
    internal static func ==(lhs: SQL.Schema, rhs: SQL.Schema) -> Bool {
        return lhs.table == rhs.table && lhs.columns == rhs.columns
    }
}

extension SQL.Schema.DataType {
    fileprivate var sql: SQL {
        switch self {
        case .blob:
            return SQL("BLOB")
        case .integer:
            return SQL("INTEGER")
        case .numeric:
            return SQL("NUMERIC")
        case .real:
            return SQL("REAL")
        case .text:
            return SQL("TEXT")
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
        if unique {
            sql += " UNIQUE"
        }
        return sql
    }
}

extension SQL.Schema {
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
