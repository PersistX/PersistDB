@testable import PersistDB
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

class StoreTests: XCTestCase {
    var store: Store<ReadWrite>?

    override func setUp() {
        super.setUp()
        store = Store(for: fixtures)
    }

    override func tearDown() {
        super.tearDown()
        store = nil
    }

    fileprivate func insert(_ data: Author.Data...) {
        _ = SignalProducer(data)
            .map(Insert.init)
            .flatMap(.merge, store!.insert)
            .await()
    }

    fileprivate func insert(_ widgets: Insert<Widget>...) {
        _ = SignalProducer(widgets)
            .flatMap(.merge, store!.insert)
            .await()
    }

    fileprivate func delete(_ ids: Author.ID...) {
        _ = SignalProducer(ids)
            .map { Delete(\Author.id == $0) }
            .flatMap(.merge, store!.delete)
            .await()
    }

    fileprivate func update(_ id: Author.ID, _ valueSet: ValueSet<Author>) {
        let update = Update(predicate: \Author.id == id, valueSet: valueSet)
        _ = store!.update(update).await()
    }

    fileprivate func fetch(_ aggregate: Aggregate<Author, Int>) -> Int {
        return store!
            .fetch(aggregate)
            .awaitFirst()!
            .value!
    }

    fileprivate func fetchOne(_ id: Author.ID) -> AuthorInfo? {
        return store!
            .fetch(id)
            .awaitFirst()?
            .value!
    }

    fileprivate func fetchAll(
        _ query: Query<None, Author> = Author.all
    ) -> ResultSet<None, AuthorInfo>! {
        return store!
            .fetch(query)
            .awaitFirst()?
            .value
    }

    fileprivate func fetchGrouped<Key>(
        _ query: Query<Key, Author>
    ) -> ResultSet<Key, AuthorName> {
        return store!
            .fetch(query)
            .awaitFirst()!
            .value!
    }

    fileprivate func fetchWidgets(
        _ query: Query<None, Widget> = Widget.all
    ) -> ResultSet<None, Widget> {
        return store!.fetch(query).awaitFirst()!.value!
    }
}

class StoreFetchTests: StoreTests {
    func testSingleResult() {
        insert(.jrrTolkien)

        XCTAssertEqual(fetchAll(), ResultSet([ AuthorInfo(.jrrTolkien) ]))
    }

    func testNilValue() {
        insert(.orsonScottCard)

        XCTAssertEqual(fetchAll(), ResultSet([ AuthorInfo(.orsonScottCard) ]))
    }

    func testPerformWorkOnSubscription() {
        let producer: SignalProducer<ResultSet<None, AuthorInfo>, NoError>
            = store!.fetch(Author.all)

        insert(.jrrTolkien)

        XCTAssertEqual(producer.awaitFirst()?.value, ResultSet([AuthorInfo(.jrrTolkien)]))
    }

    func testEmptyReturnsEmptyResultSet() {
        XCTAssertTrue(fetchAll().isEmpty)
    }

    func testDefaultSortOrder() {
        insert(.isaacAsimov, .jrrTolkien, .liuCixin, .orsonScottCard, .rayBradbury)

        XCTAssertEqual(
            fetchAll().map { $0.id },
            [ .isaacAsimov, .jrrTolkien, .liuCixin, .orsonScottCard, .rayBradbury ]
        )
    }
}

class StoreFetchAggregateTests: StoreTests {
    func testCountZero() {
        insert(.rayBradbury, .isaacAsimov)

        let aggregate = Author.all.filter(\.born != 1920).count
        XCTAssertEqual(fetch(aggregate), 0)
    }

    func testCountSome() {
        insert(.jrrTolkien, .rayBradbury, .isaacAsimov)

        let aggregate = Author.all.filter(\.born == 1920).count
        XCTAssertEqual(fetch(aggregate), 2)
    }

    func testNoPredicates() {
        insert(.jrrTolkien, .rayBradbury, .isaacAsimov)

        let aggregate = Author.all.count
        XCTAssertEqual(fetch(aggregate), 3)
    }
}

class StoreFetchByIDTests: StoreTests {
    func testDoesNotExist() {
        XCTAssertNil(fetchOne(.jrrTolkien))
    }

    func testExists() {
        insert(.jrrTolkien)

        XCTAssertEqual(fetchOne(.jrrTolkien), AuthorInfo(.jrrTolkien))
    }
}

class StoreFetchGroupedByTests: StoreTests {
    func testNoResults() {
        XCTAssertEqual(fetchGrouped(Author.all.group(by: \.born)), ResultSet())
    }

    func testOneResult() {
        insert(.isaacAsimov)

        let expected = ResultSet<Int, AuthorName>([
            Group(
                key: 1920,
                values: [ AuthorName(.isaacAsimov) ]
            ),
        ])
        let actual = fetchGrouped(Author.all.group(by: \.born))
        XCTAssertEqual(actual, expected)
    }

    func testMultipleResults() {
        insert(.orsonScottCard, .jrrTolkien, .isaacAsimov, .rayBradbury)

        let expected = ResultSet<Int, AuthorName>([
            Group(
                key: 1892,
                values: [ AuthorName(.jrrTolkien) ]
            ),
            Group(
                key: 1920,
                values: [ AuthorName(.isaacAsimov), AuthorName(.rayBradbury) ]
            ),
            Group(
                key: 1951,
                values: [ AuthorName(.orsonScottCard) ]
            ),
        ])
        let actual = fetchGrouped(Author.all.sort(by: \.name).group(by: \.born))
        XCTAssertEqual(actual, expected)
    }

    func testSortsByGroupByFirst() {
        insert(.orsonScottCard, .jrrTolkien, .isaacAsimov, .rayBradbury)

        let expected = ResultSet<Int, AuthorName>([
            Group(
                key: 1892,
                values: [ AuthorName(.jrrTolkien) ]
            ),
            Group(
                key: 1920,
                values: [ AuthorName(.isaacAsimov), AuthorName(.rayBradbury) ]
            ),
            Group(
                key: 1951,
                values: [ AuthorName(.orsonScottCard) ]
            ),
        ])
        let actual = fetchGrouped(Author.all.sort(by: \.name).group(by: \.born))
        XCTAssertEqual(actual, expected)
    }

    func testGroupByExpression() {
        insert(.orsonScottCard, .jrrTolkien, .isaacAsimov, .rayBradbury)

        let expected = ResultSet<Int, AuthorName>([
            Group(
                key: 12,
                values: [ AuthorName(.isaacAsimov), AuthorName(.rayBradbury) ]
            ),
            Group(
                key: 14,
                values: [ AuthorName(.jrrTolkien) ]
            ),
            Group(
                key: 16,
                values: [ AuthorName(.orsonScottCard) ]
            ),
        ])
        let actual = fetchGrouped(Author.all.group(by: Expression(\Author.name).count))
        XCTAssertEqual(actual, expected)
    }

    #if swift(>=4.1)
        func testGroupByOptionalKeyPath() {
            insert(.orsonScottCard, .isaacAsimov)

            let expected = ResultSet<Int?, AuthorName>([
                Group(key: nil, values: [ AuthorName(.orsonScottCard) ]),
                Group(key: 1992, values: [ AuthorName(.isaacAsimov) ]),
            ])
            let actual = fetchGrouped(Author.all.group(by: \.died))
            XCTAssertEqual(actual, expected)
        }
    #endif
}

class StoreInsertTests: StoreTests {
    func testWidget() {
        let widget = Widget(id: 1, date: Date(), double: 3.2, uuid: UUID())

        insert([
            \Widget.id == widget.id,
            \Widget.date == widget.date,
            \Widget.double == widget.double,
            \Widget.uuid == widget.uuid,
        ])

        let fetched = fetchWidgets()[0]
        XCTAssertEqual(fetched, widget)
    }

    func testDateNow() {
        let insert: Insert<Widget> = [
            \Widget.id == 1,
            \Widget.date == .now,
            \Widget.double == 3.2,
            \Widget.uuid == .uuid(),
        ]

        let before = Date()
        self.insert(insert)
        let after = Date()

        let widget = fetchWidgets()[0]
        XCTAssertGreaterThan(widget.date, before)
        XCTAssertLessThan(widget.date, after)
    }

    func testUUID() {
        let insert1: Insert<Widget> = [
            \Widget.id == 1,
            \Widget.date == .now,
            \Widget.double == 3.2,
            \Widget.uuid == .uuid(),
        ]
        let insert2: Insert<Widget> = [
            \Widget.id == 2,
            \Widget.date == .now,
            \Widget.double == 3.3,
            \Widget.uuid == .uuid(),
        ]

        insert(insert1, insert2)

        let widgets = fetchWidgets()
        XCTAssertNotEqual(widgets[0].uuid, widgets[1].uuid)
    }

    func testSendsID() {
        let widget: Insert<Widget> = [
            \Widget.id == 2,
            \Widget.date == .now,
            \Widget.double == 3.3,
            \Widget.uuid == .uuid(),
        ]

        let id = store!
            .insert(widget)
            .awaitFirst()!
            .value!

        XCTAssertEqual(id, 2)
    }
}

class StoreDeleteTests: StoreTests {
    func testWithPredicate() {
        insert(.jrrTolkien)

        XCTAssertEqual(fetchAll(), ResultSet([AuthorInfo(.jrrTolkien)]))

        delete(.jrrTolkien)

        let authors: ResultSet<None, AuthorInfo> = fetchAll()
        XCTAssert(authors.isEmpty)
    }
}

class StoreUpdateTests: StoreTests {
    func testUpdateValues() {
        insert(.jrrTolkien)

        update(.jrrTolkien, [\.born == 100, \.died == 200 ])

        XCTAssertEqual(fetchAll(), ResultSet([ AuthorInfo(.jrrTolkien, born: 100, died: 200) ]))
    }
}

class StoreObserveByIDTests: StoreTests {
    private var observation: SignalProducer<AuthorInfo?, NoError>!
    private var observed: AuthorInfo??

    override func setUp() {
        super.setUp()

        observation = store!
            .observe(Author.ID.jrrTolkien)
            .skip(first: 1)
            .take(first: 1)
            .replayLazily(upTo: 1)
    }

    override func tearDown() {
        super.tearDown()

        observation = nil
        observed = nil
    }

    private func observe(_ block: () -> Void) {
        observation.startWithValues {
            self.observed = $0
        }

        block()

        _ = observation.await()
    }

    func testInitialResultsWhenEmpty() {
        let result: AuthorInfo? = store!.observe(.jrrTolkien).awaitFirst()!.value!
        XCTAssertNil(result)
    }

    func testInitialResultsWhenNotEmpty() {
        insert(.jrrTolkien)

        XCTAssertEqual(
            store!.observe(.jrrTolkien).awaitFirst()!.value!,
            AuthorInfo(.jrrTolkien)
        )
    }

    func testSendsAfterMatchingInsert() {
        observe {
            insert(.jrrTolkien)
        }

        XCTAssertEqual(observed!, AuthorInfo(.jrrTolkien))
    }

    func testSendsAfterMatchingDelete() {
        insert(.jrrTolkien)

        observe {
            delete(.jrrTolkien)
        }

        XCTAssertEqual(observed!, nil)
    }

    func testSendsAfterMatchingUpdate() {
        insert(.jrrTolkien)

        observe {
            update(.jrrTolkien, [\.name == "J.R.R."])
        }

        XCTAssertEqual(observed!, AuthorInfo(.jrrTolkien, name: "J.R.R."))
    }
}

class StoreObserveTests: StoreTests {
    private let query = Author
        .all
        .filter(\.born >= 1900)
        .sort(by: \.name)
    private var observation: SignalProducer<ResultSet<None, AuthorInfo>, NoError>!
    private var observed: ResultSet<None, AuthorInfo>?

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

    private func observe(_ block: () -> Void) {
        observation.startWithValues {
            self.observed = $0
        }

        block()

        _ = observation.await()
    }

    func testSendsInitialResultsWhenEmpty() {
        insert(.jrrTolkien)
        XCTAssertEqual(store!.observe(query).awaitFirst()!.value!, fetchAll(query))
    }

    func testSendsInitialResultsWhenNotEmpty() {
        insert(.jrrTolkien, .isaacAsimov, .orsonScottCard)

        XCTAssertEqual(store!.observe(query).awaitFirst()!.value!, fetchAll(query))
    }

    func testSendsAfterMatchingInsert() {
        observe {
            insert(.isaacAsimov)
        }

        XCTAssertEqual(observed!, ResultSet([AuthorInfo(.isaacAsimov)]))
    }

    func testSendsAfterMatchingDelete() {
        insert(.jrrTolkien, .isaacAsimov, .orsonScottCard)

        observe {
            delete(.isaacAsimov)
        }

        XCTAssertEqual(observed!, ResultSet([AuthorInfo(.orsonScottCard)]))
    }

    func testSendsAfterUpdateThatChangesProjectedValue() {
        insert(.jrrTolkien, .isaacAsimov, .orsonScottCard)

        observe {
            update(.orsonScottCard, [\.died == 3002 ])
        }

        XCTAssertEqual(
            observed!,
            ResultSet([
                AuthorInfo(.isaacAsimov),
                AuthorInfo(.orsonScottCard, died: 3002),
            ])
        )
    }

    func testSendsAfterUpdateThatChangesSorting() {
        insert(.jrrTolkien, .isaacAsimov, .orsonScottCard)

        let name = "An Orson Scott Card"
        observe {
            update(.orsonScottCard, [\.name == name ])
        }

        XCTAssertEqual(
            observed!,
            ResultSet([
                AuthorInfo(.orsonScottCard, name: name),
                AuthorInfo(.isaacAsimov),
            ])
        )
    }

    func testSendsAfterUpdateThatAddsObject() {
        insert(.jrrTolkien, .isaacAsimov, .orsonScottCard)

        observe {
            update(.jrrTolkien, [\.born == 1900 ])
        }

        XCTAssertEqual(
            observed!,
            ResultSet([
                AuthorInfo(.isaacAsimov),
                AuthorInfo(.jrrTolkien, born: 1900),
                AuthorInfo(.orsonScottCard),
            ])
        )
    }

    func testSendsAfterUpdateThatRemovesObject() {
        insert(.jrrTolkien, .isaacAsimov, .orsonScottCard)

        observe {
            update(.orsonScottCard, [\.born == 2 ])
        }

        XCTAssertEqual(
            observed!,
            ResultSet([
                AuthorInfo(.isaacAsimov),
            ])
        )
    }

    func testDoesNotSendAfterUpdateToMatchingEntityThatDoesNotAffectResult() {
        insert(.isaacAsimov)

        observe {
            update(.isaacAsimov, [\.givenName == "Isaac Asimov" ])
        }

        XCTAssertNil(observed)
    }
}

class StoreObserveAggregateTests: StoreTests {
    private let aggregate = Author
        .all
        .filter(\.born == 1920)
        .count
    private var observation: SignalProducer<Int, NoError>!
    private var observed: Int?

    override func setUp() {
        super.setUp()

        observation = store!
            .observe(aggregate)
            .skip(first: 1)
            .take(first: 1)
            .replayLazily(upTo: 1)
    }

    override func tearDown() {
        super.tearDown()

        observation = nil
        observed = nil
    }

    private func observe(_ block: () -> Void) {
        observation.startWithValues {
            self.observed = $0
        }

        block()

        _ = observation.await()
    }

    func testSendsAfterInsert() {
        insert(.jrrTolkien, .isaacAsimov)

        observe {
            insert(.rayBradbury)
        }

        XCTAssertEqual(observed, 2)
    }

    func testSendsAfterDeletee() {
        insert(.jrrTolkien, .rayBradbury, .isaacAsimov)

        observe {
            delete(.isaacAsimov)
        }

        XCTAssertEqual(observed, 1)
    }

    func testSendsAfterUpdate() {
        insert(.jrrTolkien, .rayBradbury, .isaacAsimov)

        observe {
            update(.jrrTolkien, [\.born == 1920])
        }

        XCTAssertEqual(observed, 3)
    }
}

class StoreObserveGroupedByTests: StoreTests {
    private let query = Author
        .all
        .filter(\.name != Author.Data.jrrTolkien.name)
        .sort(by: \.name)
        .group(by: \.born)
    private var observation: SignalProducer<ResultSet<Int, AuthorName>, NoError>!
    private var observed: ResultSet<Int, AuthorName>?

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

    private func observe(_ block: () -> Void) {
        observation.startWithValues {
            self.observed = $0
        }

        block()

        _ = observation.await()
    }

    func testSendsInitialResultsWhenEmpty() {
        insert(.jrrTolkien)
        XCTAssertEqual(
            store!.observe(query).awaitFirst()!.value!,
            fetchGrouped(query)
        )
    }

    func testSendsInitialResultsWhenNotEmpty() {
        insert(.jrrTolkien, .isaacAsimov, .orsonScottCard)

        XCTAssertEqual(
            store!.observe(query).awaitFirst()!.value!,
            fetchGrouped(query)
        )
    }

    func testSendsAfterMatchingInsert() {
        observe {
            insert(.isaacAsimov)
        }

        let expected = ResultSet([
            Group(key: 1920, values: [ AuthorName(.isaacAsimov) ]),
        ])

        XCTAssertEqual(observed!, expected)
    }

    func testSendsAfterMatchingDelete() {
        insert(.jrrTolkien, .isaacAsimov, .orsonScottCard)

        observe {
            delete(.isaacAsimov)
        }

        let expected = ResultSet([
            Group(key: 1951, values: [ AuthorName(.orsonScottCard) ]),
        ])

        XCTAssertEqual(observed!, expected)
    }

    func testSendsAfterUpdateThatChangesProjectedValue() {
        insert(.jrrTolkien, .isaacAsimov, .orsonScottCard)

        observe {
            update(.orsonScottCard, [\.name == "O.S. Card" ])
        }

        let expected = ResultSet([
            Group(key: 1920, values: [ AuthorName(.isaacAsimov) ]),
            Group(key: 1951, values: [ AuthorName(.orsonScottCard, name: "O.S. Card") ]),
        ])

        XCTAssertEqual(observed!, expected)
    }

    func testSendsAfterUpdateThatChangesSorting() {
        insert(.jrrTolkien, .isaacAsimov, .rayBradbury)

        let name = "A Ray Bradbury"
        observe {
            update(.rayBradbury, [\.name == name ])
        }

        let expected = ResultSet([
            Group(key: 1920, values: [
                AuthorName(.rayBradbury, name: name),
                AuthorName(.isaacAsimov),
            ]),
        ])

        XCTAssertEqual(observed!, expected)
    }

    func testSendsAfterUpdateThatAffectsGroupedBy() {
        insert(.jrrTolkien, .isaacAsimov, .rayBradbury, .orsonScottCard)

        observe {
            update(.rayBradbury, [\.born == 1951 ])
        }

        let expected = ResultSet([
            Group(key: 1920, values: [ AuthorName(.isaacAsimov) ]),
            Group(key: 1951, values: [ AuthorName(.orsonScottCard), AuthorName(.rayBradbury) ]),
        ])

        XCTAssertEqual(observed!, expected)
    }

    func testSendsAfterUpdateThatAffectsFilter() {
        insert(.jrrTolkien, .isaacAsimov, .orsonScottCard)

        observe {
            update(.jrrTolkien, [\.name == "J.R.R." ])
        }

        let expected = ResultSet([
            Group(key: 1892, values: [ AuthorName(.jrrTolkien, name: "J.R.R.") ]),
            Group(key: 1920, values: [ AuthorName(.isaacAsimov) ]),
            Group(key: 1951, values: [ AuthorName(.orsonScottCard) ]),
        ])

        XCTAssertEqual(observed!, expected)
    }

    func testSendsAfterUpdateThatRemovesObject() {
        insert(.jrrTolkien, .isaacAsimov, .orsonScottCard)

        observe {
            update(.orsonScottCard, [\.name == Author.Data.jrrTolkien.name ])
        }

        let expected = ResultSet([
            Group(key: 1920, values: [ AuthorName(.isaacAsimov) ]),
        ])

        XCTAssertEqual(observed!, expected)
    }

    func testDoesNotSendAfterUpdateToMatchingEntityThatDoesNotAffectResult() {
        insert(.isaacAsimov)

        observe {
            update(.isaacAsimov, [\.givenName == "Isaac Asimov" ])
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

    func makeTemporaryURL() -> URL {
        return URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("store.sqlite3")
    }

    func open(at url: URL, for types: [AnyModel.Type] = fixtures) -> Store<ReadOnly> {
        return Store
            .open(at: url, for: types)
            .awaitFirst()!
            .value!
    }

    func open(at url: URL, for types: [AnyModel.Type] = fixtures) -> Store<ReadWrite> {
        return Store
            .open(at: url, for: types)
            .awaitFirst()!
            .value!
    }
}

final class StoreOpenReadOnlyTests: StoreOpenTests {
    var reader: Store<ReadOnly>!

    override func setUp() {
        super.setUp()
        reader = open(at: url)
    }

    override func tearDown() {
        super.tearDown()
        reader = nil
    }

    func testCompatibleStore() {
        XCTAssertNotNil(reader)
    }

    func testNoExistingStore() {
        let result = Store<ReadOnly>
            .open(at: makeTemporaryURL(), for: fixtures)
            .awaitFirst()

        if case .incompatibleSchema? = result?.error {
        } else {
            XCTFail("wrong result: " + String(describing: result))
        }
    }

    func testIncompatibleSchema() {
        var author = Author.anySchema
        author.properties[\Author.born]?.path = "bornOn"

        let result = Store<ReadOnly>
            .open(at: url, for: [author])
            .awaitFirst()

        if case .incompatibleSchema? = result?.error {
        } else {
            XCTFail("wrong result: " + String(describing: result))
        }
    }
}

final class StoreOpenReadWriteTests: StoreOpenTests {
    func testCreatedAtCorrectURL() {
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func testCreatesSchemas() {
        insert(.jrrTolkien)

        XCTAssertEqual(fetchAll(), ResultSet([ AuthorInfo(.jrrTolkien) ]))
    }

    func testDoesWorkOnSubscription() {
        let url = makeTemporaryURL()
        let producer = Store<ReadWrite>.open(at: url, for: fixtures)
        let fileManager = FileManager.default

        XCTAssertFalse(fileManager.fileExists(atPath: url.path))

        _ = producer.await()

        XCTAssertTrue(fileManager.fileExists(atPath: url.path))
    }

    func testCanBeReopened() {
        insert(.jrrTolkien)

        store = open(at: url)

        XCTAssertEqual(fetchAll(), ResultSet([ AuthorInfo(.jrrTolkien) ]))
    }

    func testIncompatibleSchema() {
        var author = Author.anySchema
        author.properties[\Author.born]?.path = "bornOn"

        let result = Store<ReadWrite>
            .open(at: url, for: [author])
            .awaitFirst()

        if case .incompatibleSchema? = result?.error {
        } else {
            XCTFail("wrong result: " + String(describing: result))
        }
    }

    func testCreatesMissingModels() {
        insert(.jrrTolkien)

        store = open(at: url, for: [ Widget.self ])

        XCTAssertNotNil(store)
        XCTAssertEqual(fetchAll(), ResultSet([ AuthorInfo(.jrrTolkien) ]))
    }
}
