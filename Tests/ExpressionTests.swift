@testable import PersistDB
import Schemata
import XCTest

extension AnyModelValue {
    fileprivate static func from(_ expression: AnyExpression) -> Self {
        let anyValue = Self.anyValue
        let primitive = TestDB()
            .query(.select([ .init(expression.sql, alias: "result") ]))[0]
            .dictionary["result"]!
            .primitive(anyValue.encoded)
        return anyValue.decode(primitive).value! as! Self // swiftlint:disable:this force_cast
    }
}

class AnyExpressionSQLTests: XCTestCase {
    func testNullEquals() {
        let text = SQL.Value.text("foo")
        let expr = AnyExpression.binary(.equal, .value(.null), .value(text))
        let sql = SQL.Expression.binary(.is, .value(text), .value(.null))
        XCTAssertEqual(expr.sql, sql)
    }

    func testEqualsNull() {
        let text = SQL.Value.text("foo")
        let expr = AnyExpression.binary(.equal, .value(text), .value(.null))
        let sql = SQL.Expression.binary(.is, .value(text), .value(.null))
        XCTAssertEqual(expr.sql, sql)
    }

    func testNullDoesNotEqual() {
        let text = SQL.Value.text("foo")
        let expr = AnyExpression.binary(.notEqual, .value(.null), .value(text))
        let sql = SQL.Expression.binary(.isNot, .value(text), .value(.null))
        XCTAssertEqual(expr.sql, sql)
    }

    func testDoesNotEqualNull() {
        let text = SQL.Value.text("foo")
        let expr = AnyExpression.binary(.notEqual, .value(text), .value(.null))
        let sql = SQL.Expression.binary(.isNot, .value(text), .value(.null))
        XCTAssertEqual(expr.sql, sql)
    }

    func testKeyPathThatJoins() {
        let expr = AnyExpression(\Book.author.name)
        let sql = SQL.Expression.join(
            Book.table["author"],
            Author.table["id"],
            Author.Table.name
        )
        XCTAssertEqual(expr.sql, sql)
    }

    func testDateNow() {
        let before = Date()
        let date = Date.from(.now)
        let after = Date()

        XCTAssertGreaterThan(date, before)
        XCTAssertLessThan(date, after)
    }

    func testLength() {
        let expression = AnyExpression.function(.length, [ .value(.text("test")) ])
        XCTAssertEqual(Int.from(expression), 4)
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

    func testStringCount() {
        let count = Expression<Book, String>("test").count
        let expected = AnyExpression.function(.length, [ .value(.text("test")) ])
        XCTAssertEqual(count.expression, expected)
    }
}
