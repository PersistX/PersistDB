@testable import PersistDB
import XCTest

class DatabaseSchemaTests: XCTestCase {
    func test() {
        let schemas = Set([Author.sqlSchema, Book.sqlSchema])
        let db = Database()
        schemas.forEach(db.create)

        XCTAssertEqual(db.schema(), schemas)
    }
}
