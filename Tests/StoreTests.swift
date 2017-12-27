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
    var store: Store?
    
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
            store?.insert(Insert(d))
        }
    }
    
    fileprivate func delete(_ ids: Author.ID...) {
        for id in ids {
            store?.delete(Delete(\Author.id == id))
        }
    }
    
    fileprivate func update(_ id: Author.ID, _ valueSet: ValueSet<Author>) {
        store?.update(Update(predicate: \Author.id == id, valueSet: valueSet))
    }
    
    fileprivate func fetch(_ query: Query<Author> = Author.all) -> [AuthorInfo]? {
        return store?.fetch(query).collect().firstValue
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
        let producer: SignalProducer<AuthorInfo, NoError> = store!.fetch(Author.all)
        
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

class StoreObserveTests: StoreTests {
    private let query = Author
        .all
        .filter(\.born >= 1900)
        .sort(by: \.name)
    private var observation: SignalProducer<[AuthorInfo], NoError>!
    private var observed: [AuthorInfo]?
    
    override func setUp() {
        super.setUp()
        
        observation = store!
            .observe(query)
            .skip(first: 1)
            .take(first: 1)
            .replayLazily(upTo: 1)
    }
    
    override func tearDown() {
        super.tearDown()
        
        observation = nil
        observed = nil
    }
    
    private func observe(_ block: () -> ()) {
        observation.startWithValues {
            self.observed = $0
        }
        
        block()
        
        _ = observation
            .timeout(after: 0.01, raising: NSError(), on: QueueScheduler())
            .wait()
    }
    
    func testSendsInitialResultsWhenEmpty() {
        insert(.jrrTolkien)
        XCTAssertEqual(store!.observe(query).firstValue!, fetch(query)!)
    }
    
    func testSendsInitialResultsWhenNotEmpty() {
        insert(.jrrTolkien, .isaacAsimov, .orsonScottCard)

        XCTAssertEqual(store!.observe(query).firstValue!, fetch(query)!)
    }
    
    func testSendsAfterMatchingInsert() {
        observe {
            insert(.isaacAsimov)
        }
        
        XCTAssertEqual(observed!, [AuthorInfo(.isaacAsimov)])
    }
    
    func testDoesNotSendAfterNonMatchingInsert() {
        observe {
            insert(.jrrTolkien)
        }
        
        XCTAssertNil(observed)
    }
    
    func testSendsAfterMatchingDelete() {
        insert(.jrrTolkien, .isaacAsimov, .orsonScottCard)
        
        observe {
            delete(.isaacAsimov)
        }
        
        XCTAssertEqual(observed!, [AuthorInfo(.orsonScottCard)])
    }
    
    func testDoesNotSendAfterNonMatchingDelete() {
        insert(.jrrTolkien, .isaacAsimov, .orsonScottCard)
        
        observe {
            delete(.jrrTolkien)
        }
        
        XCTAssertNil(observed)
    }
    
    func testSendsAfterUpdateThatChangesProjectedValue() {
        insert(.jrrTolkien, .isaacAsimov, .orsonScottCard)
        
        observe {
            update(.orsonScottCard, [ \.died == 3002 ])
        }
        
        XCTAssertEqual(
            observed!,
            [
                AuthorInfo(.isaacAsimov),
                AuthorInfo(.orsonScottCard, died: 3002),
            ]
        )
    }
    
    func testSendsAfterUpdateThatChangesSorting() {
        insert(.jrrTolkien, .isaacAsimov, .orsonScottCard)
        
        let name = "An Orson Scott Card"
        observe {
            update(.orsonScottCard, [ \.name == name ])
        }
        
        XCTAssertEqual(
            observed!,
            [
                AuthorInfo(.orsonScottCard, name: name),
                AuthorInfo(.isaacAsimov),
            ]
        )
    }
    
    func testSendsAfterUpdateThatAddsObject() {
        insert(.jrrTolkien, .isaacAsimov, .orsonScottCard)
        
        observe {
            update(.jrrTolkien, [ \.born == 1900 ])
        }
        
        XCTAssertEqual(
            observed!,
            [
                AuthorInfo(.isaacAsimov),
                AuthorInfo(.jrrTolkien, born: 1900),
                AuthorInfo(.orsonScottCard),
            ]
        )
    }
    
    func testSendsAfterUpdateThatRemovesObject() {
        insert(.jrrTolkien, .isaacAsimov, .orsonScottCard)
        
        observe {
            update(.orsonScottCard, [ \.born == 2 ])
        }
        
        XCTAssertEqual(
            observed!,
            [
                AuthorInfo(.isaacAsimov),
            ]
        )
    }
    
    func testDoesNotSendAfterUpdateToMatchingEntityThatDoesNotAffectResult() {
        insert(.isaacAsimov)
        
        observe {
            update(.isaacAsimov, [ \.givenName == "Isaac Asimov" ])
        }
        
        XCTAssertNil(observed)
    }
    
    func testDoesNotSendAfterUpdateToNonMatchingEntity() {
        insert(.jrrTolkien, .isaacAsimov, .orsonScottCard)
        
        observe {
            update(.jrrTolkien, [ \.name == Author.Data.jrrTolkien.givenName ])
        }
        
        XCTAssertNil(observed)
    }
}

class StoreOpenTests: StoreTests {
    var url: URL!
    
    override func setUp() {
        super.setUp()
        
        url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("store.sqlite3")
        store = Store
            .open(at: url, for: [Author.self, Book.self])
            .first()?
            .value
        XCTAssertNotNil(store)
    }
    
    override func tearDown() {
        super.tearDown()
        url = nil
    }
    
    func testCreatedAtCorrectURL() {
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }
    
    func testCreatesSchemas() {
        insert(.jrrTolkien)
        
        XCTAssertEqual(fetch()!, [ AuthorInfo(.jrrTolkien) ])
    }
}
