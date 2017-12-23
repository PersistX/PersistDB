import PersistDB
import ReactiveSwift
import Result
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

extension AuthorInfo {
    init(_ data: Author.Data) {
        id = data.id
        name = data.name
        born = data.born
        died = data.died
    }
}

extension AuthorInfo: Hashable {
    var hashValue: Int {
        return id.hashValue
    }
    
    static func == (lhs: AuthorInfo, rhs: AuthorInfo) -> Bool {
        return lhs.id == rhs.id
            && lhs.name == rhs.name
            && lhs.born == rhs.born
            && lhs.died == rhs.died
    }
}

extension SignalProducer {
    var firstValue: Value? {
        return first()?.value
    }
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
}

class StoreFetchTests: StoreTests {
    func testSingleResult() {
        let author = Author.jrrTolkien
        let insert = Insert<Author>(author)
        
        store.insert(insert)
        let info: AuthorInfo = store
            .fetch(Author.all)
            .firstValue!
        
        XCTAssertEqual(info, AuthorInfo(author))
    }
    
    func testPerformWorkOnSubscription() {
        let author = Author.jrrTolkien
        let insert = Insert<Author>(author)
        let producer: SignalProducer<AuthorInfo, NoError> = store.fetch(Author.all)
        
        store.insert(insert)
        
        XCTAssertEqual(producer.firstValue, AuthorInfo(author))
    }
}

class StoreDeleteTests: StoreTests {
    func testWithPredicate() {
        let author = Author.jrrTolkien
        let insert = Insert<Author>(author)
        let delete = Delete<Author>(\Author.id == author.id)
        
        store.insert(insert)
        store.delete(delete)
        let info: AuthorInfo? = store
            .fetch(Author.all)
            .firstValue
        
        XCTAssertNil(info)
    }
}

class StoreUpdateTests: StoreTests {
    func testUpdateValues() {
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
            .firstValue!
        
        XCTAssertEqual(info.id, author.id)
        XCTAssertEqual(info.name, author.name)
        XCTAssertEqual(info.born, 100)
        XCTAssertEqual(info.died, 200)
    }
}
