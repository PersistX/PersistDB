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
            query.where(Book.Table.author == Author.jrrTolkien.id.int),
            query.where(Book.Table.author == Author.orsonScottCard.id.int)
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
                    "name": .string("Orson Scott Card"),
                ]),
                Row([
                    "id": .integer(Author.jrrTolkien.id.int),
                    "name": .string("J.R.R. Tolkien"),
                ]),
            ])
        )
    }
    
    // MARK: - Generic Operators
    
    func testEqual() {
        let query = SQL.Query
            .select([ .wildcard(Book.table) ])
            .where(Book.Table.author == Author.Table.id)
            .where(Author.Table.id == Author.jrrTolkien.id.int)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set(Book.byJRRTolkien)
        )
    }
    
    func testNotEqual() {
        let query = SQL.Query
            .select([ .wildcard(Book.table) ])
            .where(Book.Table.author == Author.Table.id)
            .where(Author.Table.id != Author.jrrTolkien.id.int)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set(Book.byOrsonScottCard)
        )
    }
    
    // MARK: - Bool Operators
    
    func testOr() {
        let title = Book.Table.title
        let query = SQL.Query
            .select([ .wildcard(Book.table) ])
            .where(title == Book.endersGame.title || title == Book.xenocide.title)
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
            .where(!(Author.Table.name == Author.jrrTolkien.name))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.orsonScottCard.row])
        )
    }
    
    // MARK: - Int Operators
    
    func testExpressionEqualsInt() {
        let query = SQL.Query
            .select([ .wildcard(Book.table) ])
            .where(Book.Table.author == Author.jrrTolkien.id.int)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set(Book.byJRRTolkien)
        )
    }
    
    func testIntEqualsExpression() {
        let query = SQL.Query
            .select([ .wildcard(Book.table) ])
            .where(Author.jrrTolkien.id.int == Book.Table.author)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set(Book.byJRRTolkien)
        )
    }
    
    func testExpressionDoesNotEqualInt() {
        let query = SQL.Query
            .select([ .wildcard(Book.table) ])
            .where(Book.Table.author != Author.jrrTolkien.id.int)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set(Book.byOrsonScottCard)
        )
    }
    
    func testIntDoesNotEqualExpression() {
        let query = SQL.Query
            .select([ .wildcard(Book.table) ])
            .where(Author.jrrTolkien.id.int != Book.Table.author)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set(Book.byOrsonScottCard)
        )
    }
    
    func testIntLessThanExpression() {
        let query = SQL.Query
            .select([ .wildcard(Author.table) ])
            .where(1950 < Author.Table.born)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.orsonScottCard.row])
        )
    }
    
    func testExpressionLessThanInt() {
        let query = SQL.Query
            .select([ .wildcard(Author.table) ])
            .where(Author.Table.born < 1951)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.jrrTolkien.row])
        )
    }
    
    func testIntGreaterThanExpression() {
        let query = SQL.Query
            .select([ .wildcard(Author.table) ])
            .where(1951 > Author.Table.born)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.jrrTolkien.row])
        )
    }
    
    func testExpressionGreaterThanInt() {
        let query = SQL.Query
            .select([ .wildcard(Author.table) ])
            .where(Author.Table.born > 1950)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.orsonScottCard.row])
        )
    }
    
    // MARK: - Int? Operators
    
    func testExpressionEqualsOptionalInt() {
        let query = SQL.Query
            .select([ .wildcard(Author.table) ])
            .where(Author.Table.died == nil)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([ Author.orsonScottCard.row ])
        )
    }
    
    func testOptionalIntEqualsExpression() {
        let query = SQL.Query
            .select([ .wildcard(Author.table) ])
            .where(nil == Author.Table.died)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([ Author.orsonScottCard.row ])
        )
    }
    
    func testExpressionDoesNotEqualOptionalInt() {
        let query = SQL.Query
            .select([ .wildcard(Author.table) ])
            .where(Author.Table.died != nil)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([ Author.jrrTolkien.row ])
        )
    }
    
    func testOptionalIntDoesNotEqualExpression() {
        let query = SQL.Query
            .select([ .wildcard(Author.table) ])
            .where(nil != Author.Table.died)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([ Author.jrrTolkien.row ])
        )
    }
    
    // MARK: - String Operators
    
    func testExpressionEqualsString() {
        let query = SQL.Query
            .select([ .wildcard(Author.table) ])
            .where(Author.Table.name == Author.jrrTolkien.name)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.jrrTolkien.row])
        )
    }
    
    func testStringEqualsExpression() {
        let query = SQL.Query
            .select([ .wildcard(Author.table) ])
            .where(Author.jrrTolkien.name == Author.Table.name)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.jrrTolkien.row])
        )
    }
    
    func testExpressionDoesNotEqualString() {
        let query = SQL.Query
            .select([ .wildcard(Author.table) ])
            .where(Author.Table.name != Author.jrrTolkien.name)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.orsonScottCard.row])
        )
    }
    
    func testStringDoesNotEqualExpression() {
        let query = SQL.Query
            .select([ .wildcard(Author.table) ])
            .where(Author.jrrTolkien.name != Author.Table.name)
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
            .where(Author.Table.id == Author.jrrTolkien.id.int)
        
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
            .where(Author.Table.id == Author.jrrTolkien.id.int)
        
        let row: Row = [maximum.sql.debugDescription: .integer(Author.jrrTolkien.born)]
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([row])
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
            .where(Book.Table.author != Author.jrrTolkien.id.int)
            .where(Book.Table.author != Author.orsonScottCard.id.int)
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
