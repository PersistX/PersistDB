import Foundation
import Schemata

// MARK: - Book

struct Book {
    struct ID {
        let string: String
        
        init(_ string: String) {
            self.string = string
        }
    }
    
    let id: ID
    var title: String
    var author: Author
}

extension Book.ID: Equatable {
    static func == (lhs: Book.ID, rhs: Book.ID) -> Bool {
        return lhs.string == rhs.string
    }
}

extension Book: Equatable {
    static func == (lhs: Book, rhs: Book) -> Bool {
        return lhs.id == rhs.id && lhs.title == rhs.title && lhs.author == rhs.author
    }
}

extension Book.ID: KeyPathCompliant {
    func value<Leaf>(of keyPath: KeyPath<Book.ID, Leaf>) -> Leaf {
        fatalError()
    }
}

extension KeyPath where Root == Book {
    var id: KeyPath<Root, Book.ID> { return KeyPath<Root, Book.ID>(keys: keys + ["id"]) }
    var author: KeyPath<Root, Author> { return KeyPath<Root, Author>(keys: keys + ["author"]) }
    var title: KeyPath<Root, String> { return KeyPath<Root, String>(keys: keys + ["title"]) }
}

extension Book: KeyPathCompliant {
    private static let root = KeyPath<Book, Book>(keys: [])
    static let id = root.id
    static let author = root.author
    static let title = root.title
    
    func value<Leaf>(of keyPath: KeyPath<Book, Leaf>) -> Leaf {
        switch keyPath.keys.first {
        case "id"?:
            return id as! Leaf
        case "title"?:
            return title as! Leaf
        case "author"?:
            let rest = Array(keyPath.keys.dropFirst())
            return author.value(of: KeyPath<Author, Leaf>(keys: rest))
        default:
            fatalError()
        }
    }
}

// MARK: - Author

struct Author {
    struct ID {
        let string: String
        
        init(_ string: String) {
            self.string = string
        }
    }
    
    let id: ID
    var name: String
}

extension Author.ID: Equatable {
    static func == (lhs: Author.ID, rhs: Author.ID) -> Bool {
        return lhs.string == rhs.string
    }
}

extension Author: Equatable {
    static func == (lhs: Author, rhs: Author) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
}

extension Author.ID: KeyPathCompliant {
    func value<Leaf>(of keyPath: KeyPath<Author.ID, Leaf>) -> Leaf {
        fatalError()
    }
}

extension KeyPath where Root == Author {
    var id: KeyPath<Root, Author.ID> { return KeyPath<Root, Author.ID>(keys: keys + ["id"]) }
    var name: KeyPath<Root, String> { return KeyPath<Root, String>(keys: keys + ["name"]) }
}

extension Author: KeyPathCompliant {
    static private let root = KeyPath<Author, Author>(keys: [])
    static let id = root.id
    static let name = root.name
    
    func value<Value>(of keyPath: KeyPath<Author, Value>) -> Value {
        switch keyPath.keys.first {
        case "id"?:
            return id as! Value
        case "name"?:
            return name as! Value
        default:
            fatalError()
        }
    }
}
