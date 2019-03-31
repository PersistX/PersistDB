import Foundation
import PersistDB
import Schemata

// MARK: - Book

struct Book: Hashable {
    struct ISBN: Hashable {
        let string: String

        init(_ string: String) {
            self.string = string
        }
    }

    let id: ISBN
    let title: String
    let author: Author
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

    static let defaultOrder = [
        Ordering(\Book.title),
    ]
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
    struct Data {
        let id: Book.ISBN
        let title: String
        let author: Author.ID
    }
}

extension Book.Data {
    static let theHobbit = Book.Data(
        id: .theHobbit,
        title: "The Hobbit",
        author: .jrrTolkien
    )
    static let theLordOfTheRings = Book.Data(
        id: .theLordOfTheRings,
        title: "The Lord of the Rings",
        author: .jrrTolkien
    )

    static let endersGame = Book.Data(
        id: .endersGame,
        title: "Ender's Game",
        author: .orsonScottCard
    )
    static let speakerForTheDead = Book.Data(
        id: .speakerForTheDead,
        title: "Speaker for the Dead",
        author: .orsonScottCard
    )
    static let xenocide = Book.Data(
        id: .xenocide,
        title: "Xenocide",
        author: .orsonScottCard
    )
    static let childrenOfTheMind = Book.Data(
        id: .childrenOfTheMind,
        title: "Children of the Mind",
        author: .orsonScottCard
    )
}

// MARK: - Author

struct Author: Hashable {
    struct ID: Hashable {
        let int: Int

        init(_ int: Int) {
            self.int = int
        }
    }

    let id: ID
    let name: String
    let givenName: String
    let born: Int
    let died: Int?
    let books: Set<Book>
}

extension Author.ID: CustomDebugStringConvertible {
    var debugDescription: String {
        return int.description
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
        \.givenName ~ "givenName",
        \.born ~ "born",
        \.died ~ "died",
        \.books ~ \Book.author
    )

    static let defaultOrder = [
        Ordering(\Author.name),
        Ordering(\Author.born),
        Ordering(\Author.died),
    ]
}

extension Author.ID {
    static let orsonScottCard = Author.ID(1)
    static let jrrTolkien = Author.ID(2)
    static let isaacAsimov = Author.ID(3)
    static let rayBradbury = Author.ID(4)
    static let liuCixin = Author.ID(5)
}

extension Author {
    internal struct Data {
        let id: Author.ID
        let name: String
        let givenName: String
        let born: Int
        let died: Int?
    }
}

extension Author.Data {
    static let orsonScottCard = Author.Data(
        id: .orsonScottCard,
        name: "Orson Scott Card",
        givenName: "Orson Scott Card",
        born: 1951,
        died: nil
    )
    static let jrrTolkien = Author.Data(
        id: .jrrTolkien,
        name: "J.R.R. Tolkien",
        givenName: "John Ronald Reuel Tolkien",
        born: 1892,
        died: 1973
    )
    static let isaacAsimov = Author.Data(
        id: .isaacAsimov,
        name: "Isaac Asimov",
        givenName: "Isaak Ozimov",
        born: 1920,
        died: 1992
    )
    static let rayBradbury = Author.Data(
        id: .rayBradbury,
        name: "Ray Bradbury",
        givenName: "Ray Bradbury",
        born: 1920,
        died: 2012
    )
    static let liuCixin = Author.Data(
        id: .liuCixin,
        name: "Liu Cixin",
        givenName: "Lix Cixin",
        born: 1963,
        died: nil
    )
}

// MARK: - AuthorInfo

struct AuthorInfo: Hashable {
    var id: Author.ID
    var name: String
    var born: Int
    var died: Int?
}

extension AuthorInfo: PersistDB.ModelProjection {
    static let projection = Projection<Author, AuthorInfo>(
        AuthorInfo.init,
        \.id,
        \.name,
        \.born,
        \.died
    )
}

extension AuthorInfo {
    init(
        _ data: Author.Data,
        name: String? = nil,
        born: Int? = nil,
        died: Int?? = nil
    ) {
        id = data.id
        self.name = name ?? data.name
        self.born = born ?? data.born
        self.died = died ?? data.died
    }
}

// MARK: - AuthorName

struct AuthorName: Hashable {
    var id: Author.ID
    var name: String
}

extension AuthorName: PersistDB.ModelProjection {
    static let projection = Projection<Author, AuthorName>(
        AuthorName.init,
        \.id,
        \.name
    )
}

extension AuthorName {
    init(_ data: Author.Data, name: String? = nil) {
        id = data.id
        self.name = name ?? data.name
    }
}

extension AuthorName: CustomDebugStringConvertible {
    var debugDescription: String {
        return "(\(id): \(name))"
    }
}

// MARK: - Widget

struct Widget: Hashable {
    let id: Int
    let date: Date
    let double: Double
    let uuid: UUID
}

extension Widget: PersistDB.Model {
    static let schema = Schema(
        Widget.init,
        \.id ~ "id",
        \.date ~ "date",
        \.double ~ "double",
        \.uuid ~ "uuid"
    )

    static let defaultOrder = [
        Ordering(\Widget.date),
    ]
}

extension Widget: PersistDB.ModelProjection {
    typealias Model = Widget
    static let projection = Projection<Widget, Widget>(
        Widget.init,
        \Widget.id,
        \Widget.date,
        \Widget.double,
        \Widget.uuid
    )
}
