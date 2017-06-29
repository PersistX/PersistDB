@testable import PersistDB
import XCTest

class SQLExpressionTests: XCTestCase {
    func testEqualityColumn() {
        let table = SQL.Table("foo")
        let column = table["bar"]
        XCTAssertEqual(column, table["bar"])
        XCTAssertNotEqual(column, table["boo"])
    }
}
