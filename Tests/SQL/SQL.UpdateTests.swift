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
            .value(.text(Author.Data.jrrTolkien.name))
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

        let query = SQL.Query.select(Author.Table.allColumns)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([
                Author.Data.orsonScottCard.row,
                SQL.Row([
                    "id": .integer(Author.ID.jrrTolkien.int),
                    "name": .text(Author.Data.jrrTolkien.name),
                    "givenName": .text(Author.Data.jrrTolkien.givenName),
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

        let query = SQL.Query.select(Author.Table.allColumns)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([
                SQL.Row([
                    "id": .integer(Author.ID.orsonScottCard.int),
                    "name": .text(Author.Data.orsonScottCard.name),
                    "givenName": .text(Author.Data.orsonScottCard.givenName),
                    "born": .integer(1792),
                    "died": .integer(1873),
                ]),
                SQL.Row([
                    "id": .integer(Author.ID.jrrTolkien.int),
                    "name": .text(Author.Data.jrrTolkien.name),
                    "givenName": .text(Author.Data.jrrTolkien.givenName),
                    "born": .integer(1792),
                    "died": .integer(1873),
                ]),
            ])
        )
    }
}
