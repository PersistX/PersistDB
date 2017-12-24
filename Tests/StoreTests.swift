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
    
    fileprivate func insert(_ data: Author.Data...) {
        for d in data {
            store.insert(Insert(d))
        }
    }
    
    fileprivate func delete(_ ids: Author.ID...) {
        for id in ids {
            store.delete(Delete(\Author.id == id))
        }
    }
    
    fileprivate func fetch(_ query: Query<Author> = Author.all) -> [AuthorInfo]? {
        return store.fetch(query).collect().firstValue
    }
}

class StoreFetchTests: StoreTests {
    func testSingleResult() {
        insert(.jrrTolkien)
        
        XCTAssertEqual(fetch()!, [ AuthorInfo(.jrrTolkien) ])
    }
    
    func testNilValue() {
        insert(.orsonScottCard)
        
        XCTAssertEqual(fetch()!, [ AuthorInfo(.orsonScottCard) ])
    }
    
    func testPerformWorkOnSubscription() {
        let producer: SignalProducer<AuthorInfo, NoError> = store.fetch(Author.all)
        
        insert(.jrrTolkien)
        
        XCTAssertEqual(producer.firstValue, AuthorInfo(.jrrTolkien))
    }
}

class StoreDeleteTests: StoreTests {
    func testWithPredicate() {
        insert(.jrrTolkien)
        XCTAssert(!fetch()!.isEmpty)
        
        delete(.jrrTolkien)
        
        XCTAssert(fetch()!.isEmpty)
    }
}

class StoreUpdateTests: StoreTests {
    func testUpdateValues() {
        let update = Update<Author>(
            predicate: \Author.id == Author.ID.jrrTolkien,
            valueSet: [ \Author.born == 100, \Author.died == 200 ]
        )
        
        insert(.jrrTolkien)
        store.update(update)
        let info = fetch()![0]
        
        XCTAssertEqual(info.id, Author.ID.jrrTolkien)
        XCTAssertEqual(info.name, Author.Data.jrrTolkien.name)
        XCTAssertEqual(info.born, 100)
        XCTAssertEqual(info.died, 200)
    }
}
