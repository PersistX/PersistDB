import PersistDB
import Schemata

// MARK: - Book

struct Book {
    struct ID {
        let int: Int
        
        init(_ int: Int) {
            self.int = int
        }
    }
    
    let id: ID
    let title: String
    let author: Author
}

extension Book.ID: Hashable {
    var hashValue: Int {
        return int.hashValue
    }
    
    static func == (lhs: Book.ID, rhs: Book.ID) -> Bool {
        return lhs.int == rhs.int
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

extension Book.ID: ModelValue {
    static let value = Int.value.bimap(
        decode: Book.ID.init,
        encode: { $0.int }
    )
}

extension Book: PersistDB.Model {
    static let schema = Schema<Book>(
        Book.init,
        \Book.id ~ "id",
        \Book.title ~ "title",
        \Book.author ~ "author"
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
    static let schema = Schema<Author>(
        Author.init,
        \Author.id ~ "id",
        \Author.name ~ "name",
        \Author.born ~ "born",
        \Author.died ~ "died",
        \Author.books ~ \Book.author
    )
}

