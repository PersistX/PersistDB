@testable import PersistDB
import XCTest

private let author = SQL.Table("Author")
private let book = SQL.Table("Book")
private let widget = SQL.Table("Widget")

class PredicateSQLTests: XCTestCase {

    // MARK: - sql

    func testEqualDate() {
        let predicate: Predicate = \Widget.date == Date(timeIntervalSinceReferenceDate: 100_000)
        let expression: AnyExpression = AnyExpression(\Widget.date) == .value(.real(100_000))
        XCTAssertEqual(predicate.expression, expression)
    }

    func testEqualToOneOptionalInt() {
        let predicate: Predicate = \Book.author.died == nil
        let expression: AnyExpression = AnyExpression(\Book.author.died) == .value(.null)
        XCTAssertEqual(predicate.expression, expression)
    }

    func testEqualString() {
        let predicate: Predicate = \Author.name == "J.K. Rowling"
        let expression: AnyExpression = AnyExpression(\Author.name) == .value(.text("J.K. Rowling"))
        XCTAssertEqual(predicate.expression, expression)
    }

    func testNotEqualDate() {
        let predicate = \Widget.date != Date(timeIntervalSinceReferenceDate: 100_000)
        let expression: AnyExpression = AnyExpression(\Widget.date) != .value(.real(100_000))
        XCTAssertEqual(predicate.expression, expression)
    }

    func testNotEqualToOneOptionalInt() {
        let predicate = \Book.author.died != nil
        let expression = AnyExpression(\Book.author.died) != .value(.null)
        XCTAssertEqual(predicate.expression, expression)
    }

    func testOr() {
        let predicate = \Author.name == "J" || \Author.name == "K"
        let name = AnyExpression(\Author.name)
        let expression: AnyExpression = name == .value(.text("J")) || name == .value(.text("K"))
        XCTAssertEqual(predicate.expression, expression)
    }

    func test_sql_and() {
        let predicate = \Author.name == "J" && \Author.name == "K"
        let name = AnyExpression(\Author.name)
        let expression: AnyExpression = name == .value(.text("J")) && name == .value(.text("K"))
        XCTAssertEqual(predicate.expression, expression)
    }

    func testNot() {
        let predicate = !(\Author.name == "J.K. Rowling")
        let expression: AnyExpression
            = !(AnyExpression(\Author.name) == .value(.text("J.K. Rowling")))
        XCTAssertEqual(predicate.expression, expression)
    }

    func testLessThan() {
        let predicate = \Author.born < 1950
        let expression: AnyExpression = AnyExpression(\Author.born) < .value(.integer(1950))
        XCTAssertEqual(predicate.expression, expression)
    }

    func testGreaterThan() {
        let predicate = \Author.born > 1950
        let expression: AnyExpression = AnyExpression(\Author.born) > .value(.integer(1950))
        XCTAssertEqual(predicate.expression, expression)
    }

    func testLessThanOrEqual() {
        let predicate = \Author.born <= 1950
        let expression: AnyExpression = AnyExpression(\Author.born) <= .value(.integer(1950))
        XCTAssertEqual(predicate.expression, expression)
    }

    func testGreaterThanOrEqual() {
        let predicate = \Author.born >= 1950
        let expression: AnyExpression = AnyExpression(\Author.born) >= .value(.integer(1950))
        XCTAssertEqual(predicate.expression, expression)
    }
}
