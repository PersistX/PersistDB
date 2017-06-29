import Foundation

extension SQL {
    /// A table in a SQL database
    internal struct Table {
        /// The name of the table in the database.
        internal var name: String
        
        /// Initialize the table with a given name
        internal init(_ name: String) {
            self.name = name
        }
        
        internal subscript(_ name: String) -> AnyExpression {
            return .column(self, name)
        }
    }
}

extension SQL.Table: Hashable {
    internal var hashValue: Int {
        return name.hashValue
    }
    
    internal static func == (lhs: SQL.Table, rhs: SQL.Table) -> Bool {
        return lhs.name == rhs.name
    }
}

extension SQL.Table {
    internal func insert(_ values: [String: InsertValueConvertible]) -> SQL.Insert {
        return SQL.Insert(table: self, values: values.mapValues { $0.insertValue })
    }
}
