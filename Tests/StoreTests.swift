import PersistDB
import Schemata
import XCTest

private let fixtures: [AnyModel.Type] = [Author.self, Book.self]

private struct AuthorInfo {
    let id: Author.ID
    let name: String
    let born: Int
    let died: Int?
}

extension AuthorInfo: ModelProjection {
    static let projection = Projection<Author, AuthorInfo>(
        AuthorInfo.init,
        \.id,
        \.name,
        \.born,
        \.died
    )
}

class StoreTests: XCTestCase {
    func testInsertFetch() {
        let store = Store(for: fixtures)
        
        let author = Author.jrrTolkien
        let insert: Insert<Author> = [
            \Author.id == author.id,
            \Author.name == author.name,
            \Author.born == author.born,
            \Author.died == author.died,
        ]
        
        store.insert(insert)
        let info: AuthorInfo = store
            .fetch(Author.all)
            .first()!
            .value!
        
        XCTAssertEqual(info.id, author.id)
        XCTAssertEqual(info.name, author.name)
        XCTAssertEqual(info.born, author.born)
        XCTAssertEqual(info.died, author.died)
    }
}
