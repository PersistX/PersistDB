@testable import PersistDB
import XCTest

class ExpressionTests: XCTestCase {
    func test_initWithValue() {
        let expression = Expression<Book, String>("foo")
        let sql = SQL.Expression.value(.text("foo"))
        XCTAssertEqual(expression.sql, sql)
    }
}
