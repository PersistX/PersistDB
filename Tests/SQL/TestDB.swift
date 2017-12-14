@testable import PersistDB

extension Author.ID {
    static let orsonScottCard = Author.ID(1)
    static let jrrTolkien = Author.ID(2)
}

extension Author {
    enum Table {
        static let id = SQL.Expression.column(Author.table["id"])
        static let name = SQL.Expression.column(Author.table["name"])
        static let born = SQL.Expression.column(Author.table["born"])
        static let died = SQL.Expression.column(Author.table["died"])
    }
    
    struct Data {
        let id: Author.ID
        let name: String
        let born: Int
        let died: Int?
        
        fileprivate var insert: SQL.Insert {
            return Author.table.insert([
                "id": .value(.integer(id.int)),
                "name": .value(.text(name)),
                "born": .value(.integer(born)),
                "died": .value(died.map(SQL.Value.integer) ?? SQL.Value.null)
            ])
        }
        
        var row: Row {
            return [
                "id": .integer(id.int),
                "name": .text(name),
                "born": .integer(born),
                "died": died.map(SQL.Value.integer) ?? .null,
            ]
        }
    }
    
    static let table = SQL.Table("authors")
    
    static let orsonScottCard = Data(id: .orsonScottCard, name: "Orson Scott Card", born: 1951, died: nil)
    static let jrrTolkien = Data(id: .jrrTolkien, name: "J.R.R. Tolkien", born: 1892, died: 1973)
    
    fileprivate static let sqlSchema = SQL.Schema(table: table, columns: [
        SQL.Schema.Column(name: "id", type: .integer, primaryKey: true),
        SQL.Schema.Column(name: "name", type: .text),
        SQL.Schema.Column(name: "born", type: .integer),
        SQL.Schema.Column(name: "died", type: .integer, nullable: true),
    ])
}

extension Book.ISBN {
    static let theHobbit = Book.ISBN("978-0547928227")
    static let theLordOfTheRings = Book.ISBN("978-0544003415")
    
    static let endersGame = Book.ISBN("978-0312853235")
    static let speakerForTheDead = Book.ISBN("978-0312853259")
    static let xenocide = Book.ISBN("978-0812509250")
    static let childrenOfTheMind = Book.ISBN("978-0812522396")
}

extension Book {
    enum Table {
        static let id = SQL.Expression.column(Book.table["id"])
        static let author = SQL.Expression.column(Book.table["author"])
        static let title = SQL.Expression.column(Book.table["title"])
    }
    
    struct Data {
        let id: Book.ISBN
        let title: String
        let author: Author.ID
        
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
    }
    
    static let table = SQL.Table("books")
    
    static let theHobbit = Data(id: .theHobbit, title: "The Hobbit", author: Author.jrrTolkien.id)
    static let theLordOfTheRings = Data(id: .theLordOfTheRings, title: "The Lord of the Rings", author: Author.jrrTolkien.id)
    static let byJRRTolkien = [ theHobbit, theLordOfTheRings ].map { $0.row }
    
    static let endersGame = Data(id: .endersGame, title: "Ender's Game", author: .orsonScottCard)
    static let speakerForTheDead = Data(id: .speakerForTheDead, title: "Speaker for the Dead", author: .orsonScottCard)
    static let xenocide = Data(id: .xenocide, title: "Xenocide", author: .orsonScottCard)
    static let childrenOfTheMind = Data(id: .childrenOfTheMind, title: "Children of the Mind", author: .orsonScottCard)
    static let byOrsonScottCard = [ endersGame, speakerForTheDead, xenocide, childrenOfTheMind ].map { $0.row }
    
    fileprivate static let sqlSchema = SQL.Schema(table: table, columns: [
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
        
        db = Database()
        
        fixtures.forEach { db.execute($0) }
    }
    
    func query(_ query: SQL.Query) -> [Row] {
        return db.query(query)
    }
}

