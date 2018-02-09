@testable import PersistDB
import XCTest

class AnyExpressionMakeSQLTests: XCTestCase {
    func testNullEquals() {
        let text = SQL.Value.text("foo")
        let expr = AnyExpression.binary(.equal, .value(.null), .value(text))
        let sql = SQL.Expression.binary(.is, .value(text), .value(.null))
        XCTAssertEqual(expr.makeSQL(), sql)
    }

    func testEqualsNull() {
        let text = SQL.Value.text("foo")
        let expr = AnyExpression.binary(.equal, .value(text), .value(.null))
        let sql = SQL.Expression.binary(.is, .value(text), .value(.null))
        XCTAssertEqual(expr.makeSQL(), sql)
    }

    func testNullDoesNotEqual() {
        let text = SQL.Value.text("foo")
        let expr = AnyExpression.binary(.notEqual, .value(.null), .value(text))
        let sql = SQL.Expression.binary(.isNot, .value(text), .value(.null))
        XCTAssertEqual(expr.makeSQL(), sql)
    }

    func testDoesNotEqualNull() {
        let text = SQL.Value.text("foo")
        let expr = AnyExpression.binary(.notEqual, .value(text), .value(.null))
        let sql = SQL.Expression.binary(.isNot, .value(text), .value(.null))
        XCTAssertEqual(expr.makeSQL(), sql)
    }

    func testKeyPathThatJoins() {
        let expr = AnyExpression(\Book.author.name)
        let sql = SQL.Expression.join(
            Book.table["author"],
            Author.table["id"],
            Author.Table.name
        )
        XCTAssertEqual(expr.makeSQL(), sql)
    }

    func testNow() {
        let db = TestDB()
        let query = SQL.Query
            .select([.init(AnyExpression.now.makeSQL(), alias: "now")])

        let before = Date()
        let result = db.query(query)[0]
        let after = Date()

        let primitive = result.dictionary["now"]?.primitive(.date)
        if case let .date(date)? = primitive {
            XCTAssertGreaterThan(date, before)
            XCTAssertLessThan(date, after)
        } else {
            XCTFail("Wrong primitive: " + String(describing: primitive))
        }
    }
}

class ExpressionInitTests: XCTestCase {
    func test_initWithValue() {
        let expression = Expression<Book, String>("foo")
        XCTAssertEqual(expression.expression, .value(.text("foo")))
    }

    func test_initWithOptionalValue_some() {
        let expression = Expression<Book, String?>("foo")
        XCTAssertEqual(expression.expression, .value(.text("foo")))
    }

    func test_initWithOptionalValue_none() {
        let expression = Expression<Book, String?>(nil)
        XCTAssertEqual(expression.expression, .value(.null))
    }

    func testDateNow() {
        let expr = Expression<Book, Date>.now
        XCTAssertEqual(expr.expression, .now)
    }
}
