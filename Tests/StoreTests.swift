import PersistDB
import ReactiveSwift
import Result
import Schemata
import XCTest

private let fixtures: [AnyModel.Type] = [Author.self, Book.self, Widget.self]

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
        store = Store(for: fixtures)
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
    
    fileprivate func insert(_ widgets: Insert<Widget>...) {
        for w in widgets {
            store?.insert(w)
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
    
    fileprivate func fetch(_ query: Query<Author> = Author.all) -> [AuthorInfo]! {
        return store!.fetch(query).collect().firstValue
    }
    
    fileprivate func fetch(_ query: Query<Widget> = Widget.all) -> [Widget]! {
        return store!.fetch(query).collect().firstValue
    }
}

class StoreFetchTests: StoreTests {
    func testSingleResult() {
        insert(.jrrTolkien)
        
        XCTAssertEqual(fetch(), [ AuthorInfo(.jrrTolkien) ])
    }
    
    func testNilValue() {
        insert(.orsonScottCard)
        
        XCTAssertEqual(fetch(), [ AuthorInfo(.orsonScottCard) ])
    }
    
    func testPerformWorkOnSubscription() {
        let producer: SignalProducer<AuthorInfo, NoError> = store!.fetch(Author.all)
        
        insert(.jrrTolkien)
        
        XCTAssertEqual(producer.firstValue, AuthorInfo(.jrrTolkien))
    }
}

class StoreInsertTests: StoreTests {
    func testWidget() {
        let widget = Widget(id: 1, date: Date(), double: 3.2)
        
        insert([
            \Widget.id == widget.id,
            \Widget.date == widget.date,
            \Widget.double == widget.double,
        ])
        
        let fetched: Widget = fetch()[0]
        XCTAssertEqual(fetched, widget)
    }
    
    func testDateNow() {
        let insert: Insert<Widget> = [
            \Widget.id == 1,
            \Widget.date == .now,
            \Widget.double == 3.2,
        ]
        
        let before = Date()
        self.insert(insert)
        let after = Date()
        
        let widget: Widget = fetch()[0]
        XCTAssertGreaterThan(widget.date, before)
        XCTAssertLessThan(widget.date, after)
    }
}

class StoreDeleteTests: StoreTests {
    func testWithPredicate() {
        insert(.jrrTolkien)
        
        XCTAssertEqual(fetch(), [AuthorInfo(.jrrTolkien)])
        
        delete(.jrrTolkien)
        
        let authors: [AuthorInfo] = fetch()
        XCTAssert(authors.isEmpty)
    }
}

class StoreUpdateTests: StoreTests {
    func testUpdateValues() {
        insert(.jrrTolkien)
        
        update(.jrrTolkien, [ \.born == 100, \.died == 200 ])
        
        XCTAssertEqual(fetch(), [ AuthorInfo(.jrrTolkien, born: 100, died: 200) ])
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
        XCTAssertEqual(store!.observe(query).firstValue!, fetch(query))
    }
    
    func testSendsInitialResultsWhenNotEmpty() {
        insert(.jrrTolkien, .isaacAsimov, .orsonScottCard)

        XCTAssertEqual(store!.observe(query).firstValue!, fetch(query))
    }
    
    func testSendsAfterMatchingInsert() {
        observe {
            insert(.isaacAsimov)
        }
        
        XCTAssertEqual(observed!, [AuthorInfo(.isaacAsimov)])
    }
    
    func testSendsAfterMatchingDelete() {
        insert(.jrrTolkien, .isaacAsimov, .orsonScottCard)
        
        observe {
            delete(.isaacAsimov)
        }
        
        XCTAssertEqual(observed!, [AuthorInfo(.orsonScottCard)])
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
}

class StoreOpenTests: StoreTests {
    var url: URL!
    
    override func setUp() {
        super.setUp()
        
        url = makeTemporaryURL()
        store = open(at: url)
        XCTAssertNotNil(store)
    }
    
    override func tearDown() {
        super.tearDown()
        url = nil
    }
    
    private func makeTemporaryURL() -> URL {
        return URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("store.sqlite3")
    }
    
    private func open(at url: URL, for types: [AnyModel.Type] = fixtures) -> Store? {
        return Store
            .open(at: url, for: types)
            .first()?
            .value
    }
    
    func testCreatedAtCorrectURL() {
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }
    
    func testCreatesSchemas() {
        insert(.jrrTolkien)
        
        XCTAssertEqual(fetch(), [ AuthorInfo(.jrrTolkien) ])
    }
    
    func testDoesWorkOnSubscription() {
        let url = makeTemporaryURL()
        let producer = Store.open(at: url, for: fixtures)
        let fileManager = FileManager.default
        
        XCTAssertFalse(fileManager.fileExists(atPath: url.path))
        
        _ = producer.wait()
        
        XCTAssertTrue(fileManager.fileExists(atPath: url.path))
    }
    
    func testCanBeReopened() {
        insert(.jrrTolkien)
        
        store = open(at: url)
        
        XCTAssertEqual(fetch(), [ AuthorInfo(.jrrTolkien) ])
    }
    
    func testIncompatibleSchema() {
        var author = Author.anySchema
        author.properties[\Author.born]?.path = "bornOn"
        
        let result = Store
            .open(at: url, for: [author])
            .first()
        
        if case .incompatibleSchema? = result?.error {
            
        } else {
            XCTFail("wrong result: " + String(describing: result))
        }
    }
    
    func testCreatesMissingModels() {
        insert(.jrrTolkien)
        
        store = open(at: url, for: [ Widget.self ])
        
        XCTAssertNotNil(store)
        XCTAssertEqual(fetch(), [ AuthorInfo(.jrrTolkien) ])
    }
}
