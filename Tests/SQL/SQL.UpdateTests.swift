@testable import PersistDB
import XCTest

class SQLUpdateTests: XCTestCase {
    var db: TestDB!
    
    override func setUp() {
        super.setUp()
        db = TestDB()
    }
    
    override func tearDown() {
        super.tearDown()
        db = nil
    }
    
    func testWithPredicate() {
        let table = Author.table
        let predicate = SQL.Expression.binary(
            .equal,
            .column(table["name"]),
            .value(.text(Author.jrrTolkien.name))
        )
        let update = SQL.Update(
            table: table,
            values: [
                "born": .value(.integer(1792)),
                "died": .value(.integer(1873)),
            ],
            predicate: predicate
        )
        
        db.update(update)
        
        let query = SQL.Query.select([ .wildcard(table) ])
        XCTAssertEqual(
            Set(db.query(query)),
            Set([
                Author.orsonScottCard.row,
                Row([
                    "id": .integer(Author.jrrTolkien.id.int),
                    "name": .text(Author.jrrTolkien.name),
                    "born": .integer(1792),
                    "died": .integer(1873),
                ]),
            ])
        )
    }
    
    func testWithoutPredicate() {
        let table = Author.table
        let update = SQL.Update(
            table: table,
            values: [
                "born": .value(.integer(1792)),
                "died": .value(.integer(1873)),
            ],
            predicate: nil
        )
        
        db.update(update)
        
        let query = SQL.Query.select([ .wildcard(table) ])
        XCTAssertEqual(
            Set(db.query(query)),
            Set([
                Row([
                    "id": .integer(Author.orsonScottCard.id.int),
                    "name": .text(Author.orsonScottCard.name),
                    "born": .integer(1792),
                    "died": .integer(1873),
                ]),
                Row([
                    "id": .integer(Author.jrrTolkien.id.int),
                    "name": .text(Author.jrrTolkien.name),
                    "born": .integer(1792),
                    "died": .integer(1873),
                ]),
            ])
        )
    }
}
