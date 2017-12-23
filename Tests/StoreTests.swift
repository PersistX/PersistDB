import PersistDB
import Schemata
import XCTest

private let fixtures: [AnyModel.Type] = [Author.self, Book.self]

extension Insert where Model == Author {
    fileprivate init(_ data: Author.Data) {
        self.init([
            \Author.id == data.id,
            \Author.name == data.name,
            \Author.born == data.born,
            \Author.died == data.died,
        ])
    }
}

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
    var store: Store!
    
    override func setUp() {
        super.setUp()
        store = Store(for: [Author.self, Book.self])
    }
    
    override func tearDown() {
        super.tearDown()
        store = nil
    }
    
    func testInsertFetch() {
        let author = Author.jrrTolkien
        let insert = Insert<Author>(author)
        
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
    
    func testInsertDeleteFetch() {
        let author = Author.jrrTolkien
        let insert = Insert<Author>(author)
        let delete = Delete<Author>(\Author.id == author.id)
        
        store.insert(insert)
        store.delete(delete)
        let info: AuthorInfo? = store
            .fetch(Author.all)
            .first()?
            .value
        
        XCTAssertNil(info)
    }
    
    func testInsertUpdateFetch() {
        let author = Author.jrrTolkien
        let insert = Insert<Author>(author)
        let update = Update<Author>(
            predicate: \Author.id == author.id,
            valueSet: [ \Author.born == 100, \Author.died == 200 ]
        )
        
        store.insert(insert)
        store.update(update)
        let info: AuthorInfo = store
            .fetch(Author.all)
            .first()!
            .value!
        
        XCTAssertEqual(info.id, author.id)
        XCTAssertEqual(info.name, author.name)
        XCTAssertEqual(info.born, 100)
        XCTAssertEqual(info.died, 200)
    }
}
