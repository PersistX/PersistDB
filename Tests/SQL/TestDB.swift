@testable import PersistDB
import SQLite3

struct Row: Hashable, ExpressibleByDictionaryLiteral {
    private var dictionary: [String: Value]
    
    init(_ dictionary: [String: Value]) {
        self.dictionary = dictionary
    }
    
    var hashValue: Int {
        return dictionary.reduce(0) { $0 ^ $1.key.hashValue ^ $1.value.hashValue }
    }
    
    static func == (lhs: Row, rhs: Row) -> Bool {
        return lhs.dictionary == rhs.dictionary
    }
    
    init(dictionaryLiteral elements: (String, SQL.Value)...) {
        var dictionary: [String: SQL.Value] = [:]
        for (key, value) in elements {
            dictionary[key] = value
        }
        self.init(dictionary)
    }
}

extension Author {
    enum Table {
        static let id = Author.table["id"]
        static let name = Author.table["name"]
        static let born = Author.table["born"]
        static let died = Author.table["died"]
    }
    
    static let table = SQL.Table("authors")
    
    static let orsonScottCard = Author(id: Author.ID(1), name: "Orson Scott Card", born: 1951, died: nil, books: [])
    static let jrrTolkien = Author(id: Author.ID(2), name: "J.R.R. Tolkien", born: 1892, died: 1973, books: [])
    
    fileprivate static let sqlSchema = SQL.Schema(table: table, columns: [
        SQL.Schema.Column(name: "id", type: .integer, primaryKey: true),
        SQL.Schema.Column(name: "name", type: .text),
        SQL.Schema.Column(name: "born", type: .integer),
        SQL.Schema.Column(name: "died", type: .integer, nullable: true),
    ])
    
    fileprivate var insert: SQL.Insert {
        return Author.table.insert([
            "id": SQL.Value.integer(id.int),
            "name": SQL.Value.string(name),
            "born": SQL.Value.integer(born),
            "died": died.map(SQL.Value.integer) ?? SQL.Value.null
        ])
    }
    
    var row: Row {
        return [
            "id": .integer(id.int),
            "name": .string(name),
            "born": .integer(born),
            "died": died.map(SQL.Value.integer) ?? .null,
        ]
    }
}

extension Book {
    enum Table {
        static let id = Book.table["id"]
        static let author = Book.table["author"]
        static let title = Book.table["title"]
    }
    
    static let table = SQL.Table("books")
    
    static let theHobbit = Book(id: "978-0547928227", title: "The Hobbit", author: .jrrTolkien)
    static let theLordOfTheRings = Book(id: "978-0544003415", title: "The Lord of the Rings", author: .jrrTolkien)
    static let byJRRTolkien = [ theHobbit, theLordOfTheRings ].map { $0.row }
    
    static let endersGame = Book(id: "978-0312853235", title: "Ender's Game", author: .orsonScottCard)
    static let speakerForTheDead = Book(id: "978-0312853259", title: "Speaker for the Dead", author: .orsonScottCard)
    static let xenocide = Book(id: "978-0812509250", title: "Xenocide", author: .orsonScottCard)
    static let childrenOfTheMind = Book(id: "978-0812522396", title: "Children of the Mind", author: .orsonScottCard)
    static let byOrsonScottCard = [ endersGame, speakerForTheDead, xenocide, childrenOfTheMind ].map { $0.row }
    
    fileprivate static let sqlSchema = SQL.Schema(table: table, columns: [
        SQL.Schema.Column(name: "id", type: .text, primaryKey: true),
        SQL.Schema.Column(name: "author", type: .integer),
        SQL.Schema.Column(name: "title", type: .text),
    ])
    
    fileprivate var insert: SQL.Insert {
        return Book.table.insert([
            "id": SQL.Value.string(id.string),
            "author": SQL.Value.integer(author.id.int),
            "title": SQL.Value.string(title)
        ])
    }
    
    var row: Row {
        return [
            "id": .string(id.string),
            "author": .integer(author.id.int),
            "title": .string(title),
        ]
    }
}

class TestDB {
    private var db: OpaquePointer
    
    init() {
        let fixtures: [SQL] = [
            Author.sqlSchema.sql,
            Author.orsonScottCard.insert.sql,
            Author.jrrTolkien.insert.sql,
            Book.sqlSchema.sql,
            Book.theHobbit.insert.sql,
            Book.theLordOfTheRings.insert.sql,
            Book.endersGame.insert.sql,
            Book.speakerForTheDead.insert.sql,
            Book.xenocide.insert.sql,
            Book.childrenOfTheMind.insert.sql,
        ]
        
        var local: OpaquePointer?
        guard sqlite3_open(":memory:", &local) == SQLITE_OK else {
            fatalError("Couldn't open in-memory database")
        }
        db = local!
        
        fixtures.forEach { execute($0) }
    }
    
    @discardableResult private func execute(_ sql: SQL) -> [Row] {
        var stmt: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql.sql, Int32(sql.sql.count), &stmt, nil) == SQLITE_OK else {
            fatalError("Couldn't prepare statement")
        }
        
        for idx in sql.parameters.indices {
            let p = sql.parameters[idx]
            switch p {
            case .null:
                sqlite3_bind_null(stmt, Int32(idx + 1))
            case let .integer(value):
                sqlite3_bind_int(stmt, Int32(idx + 1), Int32(value))
            case let .string(value):
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
                sleep(1)
                
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
                        value = .string(String(validatingUTF8: cchars)!)
                        
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
    
    func query(_ query: SQL.Query) -> [Row] {
        return execute(query.sql)
    }
}

