import PersistDB
import ReactiveSwift
import Result
import Schemata
import XCTest

private let fixtures: [AnyModel.Type] = [Author.self, Book.self]

extension Insert where Model == Author {
    fileprivate init(_ data: Author.Data) {
        let assignments: [Assignment<Author>] = [
            \Author.id == data.id,
            \Author.name == data.name,
            \Author.givenName == data.givenName,
            \Author.born == data.born,
            \Author.died == data.died,
        ]
        self.init(ValueSet(assignments))
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
    
    fileprivate func update(_ id: Author.ID, _ valueSet: ValueSet<Author>) {
        store.update(Update(predicate: \Author.id == id, valueSet: valueSet))
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
        insert(.jrrTolkien)
        
        update(.jrrTolkien, [ \.born == 100, \.died == 200 ])
        
        XCTAssertEqual(fetch()!, [ AuthorInfo(.jrrTolkien, born: 100, died: 200) ])
    }
}
