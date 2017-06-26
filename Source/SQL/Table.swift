import Foundation

extension SQL {
    /// A table in a SQL database
    public struct Table {
        /// The name of the table in the database.
        public var name: String
        
        /// Initialize the table with a given name
        public init(_ name: String) {
            self.name = name
        }
        
        public subscript<Value>(_ name: String) -> Expression<Value> {
            return Expression(.column(self, name))
        }
    }
}

extension SQL.Table: Hashable {
    public var hashValue: Int {
        return name.hashValue
    }
    
    public static func == (lhs: SQL.Table, rhs: SQL.Table) -> Bool {
        return lhs.name == rhs.name
    }
}

extension SQL.Table {
    public func insert(_ values: [String: InsertValueConvertible]) -> SQL.Insert {
        return SQL.Insert(table: self, values: values.mapValues { $0.insertValue })
    }
}
