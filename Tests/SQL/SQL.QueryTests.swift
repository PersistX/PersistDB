@testable import PersistDB
import XCTest

class SQLQueryTests: XCTestCase {
    var db: TestDB!
    
    override func setUp() {
        super.setUp()
        db = TestDB()
    }
    
    override func tearDown() {
        super.tearDown()
        db = nil
    }
    
    // MARK: - Equality
    
    func testNotEqualWithDifferentResults() {
        XCTAssertNotEqual(
            SQL.Query.select([ SQL.Result(Book.Table.title) ]),
            SQL.Query.select([ SQL.Result(Book.Table.author) ])
        )
    }
    
    func testNotEqualWithDifferentPredicates() {
        let query = SQL.Query.select(Book.Table.allColumns)
        XCTAssertNotEqual(
            query.where(.binary(.equal, Book.Table.author, .value(.integer(Author.ID.jrrTolkien.int)))),
            query.where(.binary(.equal, Book.Table.author, .value(.integer(Author.ID.orsonScottCard.int))))
        )
    }
    
    func testNotEqualWithDifferentOrder() {
        let query = SQL.Query.select(Book.Table.allColumns)
        XCTAssertNotEqual(
            query.sorted(by: Book.Table.author.ascending),
            query.sorted(by: Book.Table.author.descending)
        )
    }
    
    // MARK: - Select
    
    func testSelectingAWildcard() {
        let query = SQL.Query
            .select(Book.Table.allColumns)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set(Book.Data.byJRRTolkien + Book.Data.byOrsonScottCard)
        )
    }
    
    func testSelectingOneExpression() {
        let query = SQL.Query
            .select([ SQL.Result(Author.Table.id)  ])
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([
                Row(["id": .integer(Author.ID.orsonScottCard.int)]),
                Row(["id": .integer(Author.ID.jrrTolkien.int)]),
            ])
        )
    }
    
    func testSelectingMultipleExpressions() {
        let query = SQL.Query
            .select([
                SQL.Result(Author.Table.id),
                SQL.Result(Author.Table.name),
            ])
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([
                Row([
                    "id": .integer(Author.ID.orsonScottCard.int),
                    "name": .text("Orson Scott Card"),
                ]),
                Row([
                    "id": .integer(Author.ID.jrrTolkien.int),
                    "name": .text("J.R.R. Tolkien"),
                ]),
            ])
        )
    }
    
    func testSelectingWithAlias() {
        let query = SQL.Query.select([ SQL.Result(Author.Table.name).as("foo") ])
        XCTAssertEqual(
            Set(db.query(query)),
            Set([
                Row([ "foo": .text("Orson Scott Card") ]),
                Row([ "foo": .text("J.R.R. Tolkien") ]),
            ])
        )
    }
    
    func testSelectingAValue() {
        let query = SQL.Query.select([ SQL.Result(.value(.text("bar"))).as("foo") ])
        XCTAssertEqual(
            Set(db.query(query)),
            Set([
                Row([ "foo": .text("bar") ]),
            ])
        )
    }
    
    // MARK: - Generic Operators
    
    func testEqual() {
        let query = SQL.Query
            .select(Book.Table.allColumns)
            .where(.binary(.equal, Book.Table.author, Author.Table.id))
            .where(.binary(.equal, Author.Table.id, .value(.integer(Author.ID.jrrTolkien.int))))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set(Book.Data.byJRRTolkien)
        )
    }
    
    func testIsNil() {
        let query = SQL.Query
            .select(Author.Table.allColumns)
            .where(.binary(.is, Author.Table.died, .value(.null)))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.Data.orsonScottCard.row])
        )
    }
    
    func testNotEqual() {
        let query = SQL.Query
            .select(Book.Table.allColumns)
            .where(.binary(.equal, Book.Table.author, Author.Table.id))
            .where(.binary(.notEqual, Author.Table.id, .value(.integer(Author.ID.jrrTolkien.int))))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set(Book.Data.byOrsonScottCard)
        )
    }
    
    func testIsNotNull() {
        let query = SQL.Query
            .select(Author.Table.allColumns)
            .where(.binary(.isNot, Author.Table.died, .value(.null)))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.Data.jrrTolkien.row])
        )
    }
    
    func testLessThan() {
        let query = SQL.Query
            .select(Author.Table.allColumns)
            .where(.binary(.lessThan, Author.Table.born, .value(.integer(1951))))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.Data.jrrTolkien.row])
        )
    }
    
    func testGreaterThan() {
        let query = SQL.Query
            .select(Author.Table.allColumns)
            .where(.binary(.greaterThan, Author.Table.born, .value(.integer(1950))))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.Data.orsonScottCard.row])
        )
    }
    
    func testLessThanOrEqual() {
        let query = SQL.Query
            .select(Author.Table.allColumns)
            .where(.binary(.lessThanOrEqual, Author.Table.born, .value(.integer(1892))))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.Data.jrrTolkien.row])
        )
    }
    
    func testGreaterThanOrEqual() {
        let query = SQL.Query
            .select(Author.Table.allColumns)
            .where(.binary(.greaterThanOrEqual, Author.Table.born, .value(.integer(1951))))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.Data.orsonScottCard.row])
        )
    }
    
    // MARK: - Bool Operators
    
    func testOr() {
        let title = Book.Table.title
        let query = SQL.Query
            .select(Book.Table.allColumns)
            .where(.binary(
                .or,
                .binary(.equal, title, .value(.text(Book.Data.endersGame.title))),
                .binary(.equal, title, .value(.text(Book.Data.xenocide.title)))
            ))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([
                Book.Data.endersGame.row,
                Book.Data.xenocide.row,
            ])
        )
    }
    
    func testNot() {
        let query = SQL.Query
            .select(Author.Table.allColumns)
            .where(.unary(.not, .binary(.equal, Author.Table.name, .value(.text(Author.Data.jrrTolkien.name)))))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.Data.orsonScottCard.row])
        )
    }
    
    // MARK: - Aggregates
    
    func testMax() {
        let maximum = SQL.Expression.function(.max, [ Author.Table.born, Author.Table.died ])
        let query = SQL.Query
            .select([ SQL.Result(maximum) ])
            .where(.binary(.equal, Author.Table.id, .value(.integer(Author.ID.jrrTolkien.int))))
        
        let row: Row = [maximum.sql.debugDescription: .integer(Author.Data.jrrTolkien.died!)]
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([row])
        )
    }
    
    func testMin() {
        let maximum = SQL.Expression.function(.min, [ Author.Table.born, Author.Table.died ])
        let query = SQL.Query
            .select([ SQL.Result(maximum) ])
            .where(.binary(.equal, Author.Table.id, .value(.integer(Author.ID.jrrTolkien.int))))
        
        let row: Row = [maximum.sql.debugDescription: .integer(Author.Data.jrrTolkien.born)]
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([row])
        )
    }
    
    // MARK: - Joins
    
    func testJoin() {
        let join = SQL.Expression.join(
            SQL.Column(table: Book.table, name: "author"),
            SQL.Column(table: Author.table, name: "id"),
            .binary(.equal, Author.Table.name, .value(.text(Author.Data.jrrTolkien.name)))
        )
        let query = SQL.Query
            .select(Book.Table.allColumns)
            .where(join)
    
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set(Book.Data.byJRRTolkien)
        )
    }
    
    func testSortJoin() {
        let join = SQL.Expression.join(
            SQL.Column(table: Book.table, name: "author"),
            SQL.Column(table: Author.table, name: "id"),
            .column(SQL.Column(table: Author.table, name: "name"))
        )
        let query = SQL.Query
            .select(Book.Table.allColumns)
            .sorted(by:
                join.ascending,
                Book.Table.title.ascending
            )
        
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            db.query(query),
            [
                Book.Data.theHobbit.row,
                Book.Data.theLordOfTheRings.row,
                Book.Data.childrenOfTheMind.row,
                Book.Data.endersGame.row,
                Book.Data.speakerForTheDead.row,
                Book.Data.xenocide.row,
            ]
        )
    }
    
    func testResultJoin() {
        let join = SQL.Expression.join(
            SQL.Column(table: Book.table, name: "author"),
            SQL.Column(table: Author.table, name: "id"),
            .column(SQL.Column(table: Author.table, name: "name"))
        )
        let query = SQL.Query
            .select([ SQL.Result(join).as("authorName") ])
            .where(.binary(.equal, Book.Table.title, .value(.text(Book.Data.theHobbit.title))))
        
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            db.query(query),
            [
                ["authorName": .text(Author.Data.jrrTolkien.name)],
            ]
        )
    }
    
    // MARK: - Collections
    
    func testContains() {
        let books = [ Book.Data.theHobbit, Book.Data.xenocide ]
        let query = SQL.Query
            .select(Book.Table.allColumns)
            .where(.inList(Book.Table.title, books.map { SQL.Value.text($0.title) }))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set(books.map { $0.row })
        )
    }
    
    // MARK: - where(_:)
    
    func testMultipleWhereMethods() {
        let query = SQL.Query
            .select(Book.Table.allColumns)
            .where(.binary(.notEqual, Book.Table.author, .value(.integer(Author.ID.jrrTolkien.int))))
            .where(.binary(.notEqual, Book.Table.author, .value(.integer(Author.ID.orsonScottCard.int))))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set()
        )
    }
    
    // MARK: - sorted(by:)
    
    func testSortedByAscending() {
        let query = SQL.Query
            .select(Book.Table.allColumns)
            .sorted(by: Book.Table.title.ascending)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            db.query(query),
            [
                Book.Data.childrenOfTheMind.row,
                Book.Data.endersGame.row,
                Book.Data.speakerForTheDead.row,
                Book.Data.theHobbit.row,
                Book.Data.theLordOfTheRings.row,
                Book.Data.xenocide.row,
            ]
        )
    }
    
    func testSortedByDescending() {
        let query = SQL.Query
            .select(Book.Table.allColumns)
            .sorted(by: Book.Table.title.descending)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            db.query(query),
            [
                Book.Data.xenocide.row,
                Book.Data.theLordOfTheRings.row,
                Book.Data.theHobbit.row,
                Book.Data.speakerForTheDead.row,
                Book.Data.endersGame.row,
                Book.Data.childrenOfTheMind.row,
            ]
        )
    }
    
    func testSortedByWithMultipleDescriptors() {
        let query = SQL.Query
            .select(Book.Table.allColumns)
            .where(.binary(.equal, Book.Table.author, Author.Table.id))
            .sorted(by:
                Author.Table.name.ascending,
                Book.Table.title.ascending
            )
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            db.query(query),
            [
                Book.Data.theHobbit.row,
                Book.Data.theLordOfTheRings.row,
                Book.Data.childrenOfTheMind.row,
                Book.Data.endersGame.row,
                Book.Data.speakerForTheDead.row,
                Book.Data.xenocide.row,
            ]
        )
    }
    
    func testSortedByWithMultipleCalls() {
        let query = SQL.Query
            .select(Book.Table.allColumns)
            .where(.binary(.equal, Book.Table.author, Author.Table.id))
            .sorted(by: Book.Table.title.ascending)
            .sorted(by: Author.Table.name.ascending)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            db.query(query),
            [
                Book.Data.theHobbit.row,
                Book.Data.theLordOfTheRings.row,
                Book.Data.childrenOfTheMind.row,
                Book.Data.endersGame.row,
                Book.Data.speakerForTheDead.row,
                Book.Data.xenocide.row,
            ]
        )
    }
}

class SQLQueryInvalidatedByTests: XCTestCase {
    let query = SQL.Query
        .select([ .init(Author.Table.name, alias: "foo") ])
        .where(.binary(.isNot, Author.Table.died, .value(.null)))
        .sorted(by: SQL.Ordering(Author.Table.born, .ascending))
    
    let joined = SQL.Query
        .select([
            .init(.join(
                Book.table["author"],
                Author.table["id"],
                Author.Table.name
            ), alias: "foo")
        ])
        .where(.binary(
            .isNot,
            .join(Book.table["author"], Author.table["id"], Author.Table.died),
            .value(.null)
        ))
        .sorted(by: SQL.Ordering(
            .join(Book.table["author"], Author.table["id"], Author.Table.born),
            .ascending
        ))
    
    func testNotInvalidatedByInsertInAnotherTable() {
        let insert = SQL.Insert(
            table: Book.table,
            values: [
                "name": .value(.text("name")),
                "born": .value(.text("born")),
                "died": .value(.text("died")),
            ]
        )
        
        XCTAssertFalse(query.invalidated(by: .inserted(insert, id: .null)))
    }
    
    func testInvalidatedByInsert() {
        let insert = SQL.Insert(
            table: Author.table,
            values: [
                "name": .value(.text("name")),
                "born": .value(.text("born")),
                "died": .value(.text("died")),
            ]
        )
        
        XCTAssertTrue(query.invalidated(by: .inserted(insert, id: .null)))
    }
    
    func testInvalidatedByInsertedInJoinedQuery() {
        let insert = SQL.Insert(
            table: Author.table,
            values: [
                "name": .value(.text("name")),
                "born": .value(.text("born")),
                "died": .value(.text("died")),
            ]
        )
        
        XCTAssertTrue(joined.invalidated(by: .inserted(insert, id: .null)))
    }
    
    func testNotInvalidatedByDeleteInAnotherTable() {
        let delete = SQL.Delete(table: Book.table, predicate: nil)
        XCTAssertFalse(query.invalidated(by: .deleted(delete)))
    }
    
    func testInvalidatedByDelete() {
        let delete = SQL.Delete(table: Author.table, predicate: nil)
        XCTAssertTrue(query.invalidated(by: .deleted(delete)))
    }
    
    func testJoinedInvalidatedByDelete() {
        let delete = SQL.Delete(table: Author.table, predicate: nil)
        XCTAssertTrue(joined.invalidated(by: .deleted(delete)))
    }
    
    func testNotInvalidatedByUpdateInAnotherTable() {
        let update = SQL.Update(
            table: Book.table,
            values: [
                "name": .value(.text("name"))
            ],
            predicate: nil
        )
        XCTAssertFalse(query.invalidated(by: .updated(update)))
    }
    
    func testNotInvalidatedByUpdateToUnusedColumn() {
        let update = SQL.Update(
            table: Author.table,
            values: [
                "givenName": .value(.text("givenName"))
            ],
            predicate: nil
        )
        XCTAssertFalse(query.invalidated(by: .updated(update)))
    }
    
    func testNotInvalidatedByUpdateToUnusedJoinedColumn() {
        let update = SQL.Update(
            table: Author.table,
            values: [
                "givenName": .value(.text("givenName"))
            ],
            predicate: nil
        )
        XCTAssertFalse(joined.invalidated(by: .updated(update)))
    }
    
    func testInvalidatedByUpdateToSortColumn() {
        let update = SQL.Update(
            table: Author.table,
            values: [
                "born": .value(.integer(1000))
            ],
            predicate: nil
        )
        XCTAssertTrue(query.invalidated(by: .updated(update)))
    }
    
    func testInvalidatedByUpdateToJoinedSortColumn() {
        let update = SQL.Update(
            table: Author.table,
            values: [
                "born": .value(.integer(1000))
            ],
            predicate: nil
        )
        XCTAssertTrue(joined.invalidated(by: .updated(update)))
    }
    
    func testInvalidatedByUpdateToFilterColumn() {
        let update = SQL.Update(
            table: Author.table,
            values: [
                "died": .value(.integer(1000))
            ],
            predicate: nil
        )
        XCTAssertTrue(query.invalidated(by: .updated(update)))
    }
    
    func testInvalidatedByUpdateToJoinedFilterColumn() {
        let update = SQL.Update(
            table: Author.table,
            values: [
                "died": .value(.integer(1000))
            ],
            predicate: nil
        )
        XCTAssertTrue(joined.invalidated(by: .updated(update)))
    }
    
    func testInvalidatedByUpdateToJoinedAliasedColumnResult() {
        let update = SQL.Update(
            table: Author.table,
            values: [
                "name": .value(.text("givenName"))
            ],
            predicate: nil
        )
        XCTAssertTrue(joined.invalidated(by: .updated(update)))
    }
    
    func testInvalidatedByUpdateToDoubleJoinedAliasedColumnResult() {
        let publisher = SQL.Table("Publisher")
        let query = SQL.Query
            .select([.init(
                .join(
                    Book.table["author"],
                    Author.table["id"],
                    .join(
                        Author.table["publisher"],
                        publisher["id"],
                        .column(publisher["name"])
                    )
                ),
                alias: "foo"
            )])
        let update = SQL.Update(
            table: publisher,
            values: [
                "name": .value(.text("givenName"))
            ],
            predicate: nil
        )
        XCTAssertTrue(query.invalidated(by: .updated(update)))
    }
}
