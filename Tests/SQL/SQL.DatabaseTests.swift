@testable import PersistDB
import XCTest

class SQLDatabaseSchemaTests: XCTestCase {
    func test() {
        let schemas = Set([Author.sqlSchema, Book.sqlSchema])
        let db = SQL.Database()
        schemas.forEach(db.create)

        XCTAssertEqual(db.schema(), schemas)
    }
}
