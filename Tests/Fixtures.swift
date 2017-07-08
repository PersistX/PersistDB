import PersistDB
import Schemata

// MARK: - Book

struct Book {
    struct ISBN {
        let string: String
        
        init(_ string: String) {
            self.string = string
        }
    }
    
    let id: ISBN
    let title: String
    let author: Author
}

extension Book.ISBN: Hashable {
    var hashValue: Int {
        return string.hashValue
    }
    
    static func == (lhs: Book.ISBN, rhs: Book.ISBN) -> Bool {
        return lhs.string == rhs.string
    }
}

extension Book.ISBN: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self.init(value)
    }
    
    init(unicodeScalarLiteral value: String) {
        self.init(value)
    }
    
    init(extendedGraphemeClusterLiteral value: String) {
        self.init(value)
    }
}

extension Book: Hashable {
    var hashValue: Int {
        return id.hashValue ^ title.hashValue ^ author.hashValue
    }
    
    static func == (lhs: Book, rhs: Book) -> Bool {
        return lhs.id == rhs.id && lhs.title == rhs.title && lhs.author == rhs.author
    }
}

extension Book.ISBN: ModelValue {
    static let value = String.value.bimap(
        decode: Book.ISBN.init(_:),
        encode: { $0.string }
    )
}

extension Book: PersistDB.Model {
    static let schema = Schema(
        Book.init,
        \.id ~ "id",
        \.title ~ "title",
        \.author ~ "author"
    )
}


// MARK: - Author

struct Author {
    struct ID {
        let int: Int
        
        init(_ int: Int) {
            self.int = int
        }
    }
    
    let id: ID
    let name: String
    let born: Int
    let died: Int?
    let books: Set<Book>
}

extension Author.ID: Hashable {
    var hashValue: Int {
        return int.hashValue
    }
    
    static func == (lhs: Author.ID, rhs: Author.ID) -> Bool {
        return lhs.int == rhs.int
    }
}

extension Author: Hashable {
    var hashValue: Int {
        return id.hashValue ^ name.hashValue ^ books.hashValue
    }
    
    static func == (lhs: Author, rhs: Author) -> Bool {
        return lhs.id == rhs.id
            && lhs.name == rhs.name
            && lhs.born == rhs.born
            && lhs.died == rhs.died
            && lhs.books == rhs.books
    }
}

extension Author.ID: ModelValue {
    static let value = Int.value.bimap(
        decode: Author.ID.init,
        encode: { $0.int }
    )
}

extension Author: PersistDB.Model {
    static let schema = Schema(
        Author.init,
        \.id ~ "id",
        \.name ~ "name",
        \.born ~ "born",
        \.died ~ "died",
        \.books ~ \Book.author
    )
}

