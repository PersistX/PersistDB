import PersistDB
import XCTest

class SQLTableTests: XCTestCase {
    func testEquality() {
        XCTAssertEqual(SQL.Table("foo"), SQL.Table("foo"))
    }
}
