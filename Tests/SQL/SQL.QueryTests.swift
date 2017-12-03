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
        let query = SQL.Query.select([ .wildcard(Book.table) ])
        XCTAssertNotEqual(
            query.where(Book.Table.author == .value(.integer(Author.jrrTolkien.id.int))),
            query.where(Book.Table.author == .value(.integer(Author.orsonScottCard.id.int)))
        )
    }
    
    func testNotEqualWithDifferentOrder() {
        let query = SQL.Query.select([ .wildcard(Book.table) ])
        XCTAssertNotEqual(
            query.sorted(by: Book.Table.author.ascending),
            query.sorted(by: Book.Table.author.descending)
        )
    }
    
    // MARK: - Select
    
    func testSelectingAWildcard() {
        let query = SQL.Query
            .select([ .wildcard(Book.table) ])
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set(Book.byJRRTolkien + Book.byOrsonScottCard)
        )
    }
    
    func testSelectingOneExpression() {
        let query = SQL.Query
            .select([ SQL.Result(Author.Table.id)  ])
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([
                Row(["id": .integer(Author.orsonScottCard.id.int)]),
                Row(["id": .integer(Author.jrrTolkien.id.int)]),
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
                    "id": .integer(Author.orsonScottCard.id.int),
                    "name": .text("Orson Scott Card"),
                ]),
                Row([
                    "id": .integer(Author.jrrTolkien.id.int),
                    "name": .text("J.R.R. Tolkien"),
                ]),
            ])
        )
    }
    
    // MARK: - Generic Operators
    
    func testEqual() {
        let query = SQL.Query
            .select([ .wildcard(Book.table) ])
            .where(Book.Table.author == Author.Table.id)
            .where(Author.Table.id == .value(.integer(Author.jrrTolkien.id.int)))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set(Book.byJRRTolkien)
        )
    }
    
    func testEqualsNil() {
        let query = SQL.Query
            .select([ .wildcard(Author.table) ])
            .where(Author.Table.died == .value(.null))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.orsonScottCard.row])
        )
    }
    
    func testNilEquals() {
        let query = SQL.Query
            .select([ .wildcard(Author.table) ])
            .where(.value(.null) == Author.Table.died)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.orsonScottCard.row])
        )
    }
    
    func testNotEqual() {
        let query = SQL.Query
            .select([ .wildcard(Book.table) ])
            .where(Book.Table.author == Author.Table.id)
            .where(Author.Table.id != .value(.integer(Author.jrrTolkien.id.int)))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set(Book.byOrsonScottCard)
        )
    }
    
    func testDoesNotEqualNil() {
        let query = SQL.Query
            .select([ .wildcard(Author.table) ])
            .where(Author.Table.died != .value(.null))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.jrrTolkien.row])
        )
    }
    
    func testNilDoesNotEqual() {
        let query = SQL.Query
            .select([ .wildcard(Author.table) ])
            .where(.value(.null) != Author.Table.died)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.jrrTolkien.row])
        )
    }
    
    func testLessThan() {
        let query = SQL.Query
            .select([ .wildcard(Author.table) ])
            .where(Author.Table.born < .value(.integer(1951)))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.jrrTolkien.row])
        )
    }
    
    func testGreaterThan() {
        let query = SQL.Query
            .select([ .wildcard(Author.table) ])
            .where(Author.Table.born > .value(.integer(1950)))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.orsonScottCard.row])
        )
    }
    
    func testLessThanOrEqual() {
        let query = SQL.Query
            .select([ .wildcard(Author.table) ])
            .where(Author.Table.born <= .value(.integer(1892)))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.jrrTolkien.row])
        )
    }
    
    func testGreaterThanOrEqual() {
        let query = SQL.Query
            .select([ .wildcard(Author.table) ])
            .where(Author.Table.born >= .value(.integer(1951)))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.orsonScottCard.row])
        )
    }
    
    // MARK: - Bool Operators
    
    func testOr() {
        let title = Book.Table.title
        let query = SQL.Query
            .select([ .wildcard(Book.table) ])
            .where(title == .value(.text(Book.endersGame.title)) || title == .value(.text(Book.xenocide.title)))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([
                Book.endersGame.row,
                Book.xenocide.row,
            ])
        )
    }
    
    func testNot() {
        let query = SQL.Query
            .select([ .wildcard(Author.table) ])
            .where(!(Author.Table.name == .value(.text(Author.jrrTolkien.name))))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.orsonScottCard.row])
        )
    }
    
    // MARK: - Aggregates
    
    func testMax() {
        let maximum = max(
            Author.Table.born,
            Author.Table.died
        )
        let query = SQL.Query
            .select([ SQL.Result(maximum) ])
            .where(Author.Table.id == .value(.integer(Author.jrrTolkien.id.int)))
        
        let row: Row = [maximum.sql.debugDescription: .integer(Author.jrrTolkien.died!)]
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([row])
        )
    }
    
    func testMin() {
        let maximum = min(
            Author.Table.born,
            Author.Table.died
        )
        let query = SQL.Query
            .select([ SQL.Result(maximum) ])
            .where(Author.Table.id == .value(.integer(Author.jrrTolkien.id.int)))
        
        let row: Row = [maximum.sql.debugDescription: .integer(Author.jrrTolkien.born)]
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
            Author.Table.name == .value(.text(Author.jrrTolkien.name))
        )
        let query = SQL.Query
            .select([ .wildcard(Book.table) ])
            .where(join)
    
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set(Book.byJRRTolkien)
        )
    }
    
    func testSortJoin() {
        let join = SQL.Expression.join(
            SQL.Column(table: Book.table, name: "author"),
            SQL.Column(table: Author.table, name: "id"),
            .column(SQL.Column(table: Author.table, name: "name"))
        )
        let query = SQL.Query
            .select([ .wildcard(Book.table) ])
            .sorted(by:
                join.ascending,
                Book.Table.title.ascending
            )
        
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            db.query(query),
            [
                Book.theHobbit.row,
                Book.theLordOfTheRings.row,
                Book.childrenOfTheMind.row,
                Book.endersGame.row,
                Book.speakerForTheDead.row,
                Book.xenocide.row,
            ]
        )
    }
    
    // MARK: - Collections
    
    func testContains() {
        let books = [ Book.theHobbit, Book.xenocide ]
        let query = SQL.Query
            .select([ .wildcard(Book.table) ])
            .where(books.map { $0.title }.contains(Book.Table.title))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set(books.map { $0.row })
        )
    }
    
    // MARK: - where(_:)
    
    func testMultipleWhereMethods() {
        let query = SQL.Query
            .select([ .wildcard(Book.table) ])
            .where(Book.Table.author != .value(.integer(Author.jrrTolkien.id.int)))
            .where(Book.Table.author != .value(.integer(Author.orsonScottCard.id.int)))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set()
        )
    }
    
    // MARK: - sorted(by:)
    
    func testSortedByAscending() {
        let query = SQL.Query
            .select([ .wildcard(Book.table) ])
            .sorted(by: Book.Table.title.ascending)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            db.query(query),
            [
                Book.childrenOfTheMind.row,
                Book.endersGame.row,
                Book.speakerForTheDead.row,
                Book.theHobbit.row,
                Book.theLordOfTheRings.row,
                Book.xenocide.row,
            ]
        )
    }
    
    func testSortedByDescending() {
        let query = SQL.Query
            .select([ .wildcard(Book.table) ])
            .sorted(by: Book.Table.title.descending)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            db.query(query),
            [
                Book.xenocide.row,
                Book.theLordOfTheRings.row,
                Book.theHobbit.row,
                Book.speakerForTheDead.row,
                Book.endersGame.row,
                Book.childrenOfTheMind.row,
            ]
        )
    }
    
    func testSortedByWithMultipleDescriptors() {
        let query = SQL.Query
            .select([ .wildcard(Book.table) ])
            .where(Book.Table.author == Author.Table.id)
            .sorted(by:
                Author.Table.name.ascending,
                Book.Table.title.ascending
            )
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            db.query(query),
            [
                Book.theHobbit.row,
                Book.theLordOfTheRings.row,
                Book.childrenOfTheMind.row,
                Book.endersGame.row,
                Book.speakerForTheDead.row,
                Book.xenocide.row,
            ]
        )
    }
    
    func testSortedByWithMultipleCalls() {
        let query = SQL.Query
            .select([ .wildcard(Book.table) ])
            .where(Book.Table.author == Author.Table.id)
            .sorted(by: Book.Table.title.ascending)
            .sorted(by: Author.Table.name.ascending)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            db.query(query),
            [
                Book.theHobbit.row,
                Book.theLordOfTheRings.row,
                Book.childrenOfTheMind.row,
                Book.endersGame.row,
                Book.speakerForTheDead.row,
                Book.xenocide.row,
                ]
        )
    }
}
