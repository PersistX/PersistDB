import SQLite3

/// A row from a SQL database.
internal struct Row {
    internal var dictionary: [String: Value]
    
    init(_ dictionary: [String: Value]) {
        self.dictionary = dictionary
    }
}

extension Row: Hashable {
    var hashValue: Int {
        return dictionary.reduce(0) { $0 ^ $1.key.hashValue ^ $1.value.hashValue }
    }
    
    static func == (lhs: Row, rhs: Row) -> Bool {
        return lhs.dictionary == rhs.dictionary
    }
}

extension Row: ExpressibleByDictionaryLiteral {
    init(dictionaryLiteral elements: (String, SQL.Value)...) {
        var dictionary: [String: SQL.Value] = [:]
        for (key, value) in elements {
            dictionary[key] = value
        }
        self.init(dictionary)
    }
}

/// An untyped SQLite database that can execute SQL queries.
internal class Database {
    private var db: OpaquePointer
    
    /// Create an in-memory database.
    init() {
        var local: OpaquePointer?
        guard sqlite3_open(":memory:", &local) == SQLITE_OK else {
            fatalError("Couldn't open in-memory database")
        }
        db = local!
    }
    
    /// Execute a SQL query.
    @discardableResult func execute(_ sql: SQL) -> [Row] {
        var stmt: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql.sql, Int32(sql.sql.count), &stmt, nil) == SQLITE_OK else {
            fatalError("Couldn't prepare statement")
        }
        
        for idx in sql.parameters.indices {
            let p = sql.parameters[idx]
            switch p {
            case let .integer(value):
                sqlite3_bind_int(stmt, Int32(idx + 1), Int32(value))
            case .null:
                sqlite3_bind_null(stmt, Int32(idx + 1))
            case let .real(value):
                sqlite3_bind_double(stmt, Int32(idx + 1), value)
            case let .text(value):
                sqlite3_bind_text(stmt, Int32(idx + 1), value, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            }
        }
        
        var rows: [Row] = []
        var hasMore = true
        while hasMore {
            let result = sqlite3_step(stmt)
            switch result {
            case SQLITE_OK, SQLITE_DONE:
                hasMore = false
                
            case SQLITE_BUSY:
                continue
                
            case SQLITE_ROW:
                var values: [String: SQL.Value] = [:]
                for idx in 0..<sqlite3_column_count(stmt) {
                    let name = String(validatingUTF8: sqlite3_column_name(stmt, Int32(idx)))!
                    let type = sqlite3_column_type(stmt, Int32(idx))
                    let value: SQL.Value
                    switch type {
                    case 1:
                        value = .integer(numericCast(sqlite3_column_int64(stmt, Int32(idx))))
                        
                    case 3:
                        let pointer = UnsafeRawPointer(sqlite3_column_text(stmt, Int32(idx)))!
                        let cchars = pointer.bindMemory(to: CChar.self, capacity: 0)
                        value = .text(String(validatingUTF8: cchars)!)
                        
                    case 5:
                        value = .null
                        
                    default:
                        fatalError("Unknown column type \(type)")
                    }
                    values[name] = value
                }
                rows.append(Row(values))
                
            default:
                fatalError("Unknown step result \(result)")
            }
        }
        
        sqlite3_finalize(stmt)
        
        return rows
    }
    
    func create(_ schema: SQL.Schema) {
        execute(schema.sql)
    }
    
    func delete(_ delete: SQL.Delete) {
        execute(delete.sql)
    }
    
    func insert(_ insert: SQL.Insert) {
        execute(insert.sql)
    }
    
    func perform(_ action: SQL.Action) {
        switch action {
        case let .insert(sql):
            insert(sql)
        case let .delete(sql):
            delete(sql)
        case let .update(sql):
            update(sql)
        }
    }
    
    func query(_ query: SQL.Query) -> [Row] {
        return execute(query.sql)
    }
    
    func update(_ update: SQL.Update) {
        execute(update.sql)
    }
}
