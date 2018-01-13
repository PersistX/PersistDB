import Foundation
@testable import PersistDB
import XCTest

class SQLValueTests: XCTestCase {
    func testEquatable() {
        XCTAssertEqual(SQL.Value.integer(5), SQL.Value.integer(5))
        XCTAssertNotEqual(SQL.Value.integer(5), SQL.Value.integer(6))

        XCTAssertEqual(SQL.Value.text("A"), SQL.Value.text("A"))
        XCTAssertNotEqual(SQL.Value.text("A"), SQL.Value.text("B"))

        XCTAssertNotEqual(SQL.Value.integer(5), SQL.Value.text("A"))
    }

    func testIntegerLiteralConvertible() {
        XCTAssertEqual(5, SQL.Value.integer(5))
    }

    func testStringLiteralConvertible() {
        XCTAssertEqual("A", SQL.Value.text("A"))
    }

    func testNullSQL() {
        XCTAssertEqual(SQL.Value.null.sql, SQL("NULL"))
    }
}

class StringTests: XCTestCase {
    func testPlaceholders() {
        XCTAssertEqual("/* ? */".placeholders, IndexSet())
        XCTAssertEqual("-- ?".placeholders, IndexSet())
        XCTAssertEqual("'?'".placeholders, IndexSet())
        XCTAssertEqual("A ? B".placeholders, IndexSet(integer: 2))
    }
}

class SQLTests: XCTestCase {
    func testEquatable() {
        XCTAssertEqual(SQL("A"), SQL("A"))
        XCTAssertNotEqual(SQL("A"), SQL("B"))
        XCTAssertNotEqual(SQL("?", parameters: "A"), SQL("?", parameters: "B"))
    }

    func testDebugDescription() {
        let sql = SQL("SELECT * FROM foo WHERE bar = ? AND baz = ?", parameters: "A", 5)
        let debug = "SELECT * FROM foo WHERE bar = 'A' AND baz = 5"
        XCTAssertEqual(sql.debugDescription, debug)
    }

    func testAppend() {
        var sql = SQL("b")
        sql.append(" AND c")
        XCTAssertEqual(sql, SQL("b AND c"))
    }

    func testAppending() {
        XCTAssertEqual(
            SQL("bar = ?", parameters: 5) + " AND " + SQL("baz = ?", parameters: 6),
            SQL("bar = ? AND baz = ?", parameters: 5, 6)
        )
    }

    func testParenthesized() {
        XCTAssertEqual(SQL("4").parenthesized, SQL("(4)"))
    }
}

class SequenceTests: XCTestCase {
    func testSQLJoined() {
        let items = [
            SQL("bar = ?", parameters: 5),
            SQL("baz = ?", parameters: 6),
        ]
        XCTAssertEqual(
            items.joined(separator: " AND "),
            SQL("bar = ? AND baz = ?", parameters: 5, 6)
        )
    }
}
