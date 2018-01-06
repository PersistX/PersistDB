@testable import PersistDB


extension Author.Data {
    fileprivate var insert: SQL.Insert {
        return Author.table.insert([
            "id": .value(.integer(id.int)),
            "name": .value(.text(name)),
            "givenName": .value(.text(givenName)),
            "born": .value(.integer(born)),
            "died": .value(died.map(SQL.Value.integer) ?? SQL.Value.null)
        ])
    }
    
    var row: Row {
        return [
            "id": .integer(id.int),
            "name": .text(name),
            "givenName": .text(givenName),
            "born": .integer(born),
            "died": died.map(SQL.Value.integer) ?? .null,
        ]
    }
}

extension Author {
    enum Table {
        static let allColumns = [
            SQL.Result(id),
            SQL.Result(name),
            SQL.Result(givenName),
            SQL.Result(born),
            SQL.Result(died),
        ]
        
        static let id = SQL.Expression.column(Author.table["id"])
        static let name = SQL.Expression.column(Author.table["name"])
        static let givenName = SQL.Expression.column(Author.table["givenName"])
        static let born = SQL.Expression.column(Author.table["born"])
        static let died = SQL.Expression.column(Author.table["died"])
    }
    
    static let table = SQL.Table("Author")
    
    static let sqlSchema = SQL.Schema(table: table, columns: [
        SQL.Schema.Column(name: "id", type: .integer, primaryKey: true),
        SQL.Schema.Column(name: "name", type: .text),
        SQL.Schema.Column(name: "givenName", type: .text),
        SQL.Schema.Column(name: "born", type: .integer),
        SQL.Schema.Column(name: "died", type: .integer, nullable: true),
    ])
}

extension Book.Data {
    fileprivate var insert: SQL.Insert {
        return Book.table.insert([
            "id": .value(.text(id.string)),
            "author": .value(.integer(author.int)),
            "title": .value(.text(title)),
        ])
    }
    
    var row: Row {
        return [
            "id": .text(id.string),
            "author": .integer(author.int),
            "title": .text(title),
        ]
    }
    
    
    static let byJRRTolkien = [ theHobbit, theLordOfTheRings ].map { $0.row }
    static let byOrsonScottCard = [ endersGame, speakerForTheDead, xenocide, childrenOfTheMind ].map { $0.row }
}

extension Book {
    enum Table {
        static let allColumns = [
            SQL.Result(id),
            SQL.Result(author),
            SQL.Result(title),
        ]
        
        static let id = SQL.Expression.column(Book.table["id"])
        static let author = SQL.Expression.column(Book.table["author"])
        static let title = SQL.Expression.column(Book.table["title"])
    }
    
    static let table = SQL.Table("Book")
    
    static let sqlSchema = SQL.Schema(table: table, columns: [
        SQL.Schema.Column(name: "id", type: .text, primaryKey: true),
        SQL.Schema.Column(name: "author", type: .integer),
        SQL.Schema.Column(name: "title", type: .text),
    ])
}

class TestDB {
    private let db: Database
    
    init() {
        let fixtures: [SQL] = [
            Author.sqlSchema.sql,
            Author.Data.orsonScottCard.insert.sql,
            Author.Data.jrrTolkien.insert.sql,
            Book.sqlSchema.sql,
            Book.Data.theHobbit.insert.sql,
            Book.Data.theLordOfTheRings.insert.sql,
            Book.Data.endersGame.insert.sql,
            Book.Data.speakerForTheDead.insert.sql,
            Book.Data.xenocide.insert.sql,
            Book.Data.childrenOfTheMind.insert.sql,
        ]
        
        db = Database()
        
        fixtures.forEach { db.execute($0) }
    }
    
    func delete(_ delete: SQL.Delete) {
        db.delete(delete)
    }
    
    func query(_ query: SQL.Query) -> [Row] {
        return db.query(query)
    }
    
    func update(_ update: SQL.Update) {
        db.update(update)
    }
}

