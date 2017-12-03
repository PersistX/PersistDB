@testable import PersistDB
import XCTest

private let author = SQL.Table("Author")
private let book = SQL.Table("Book")
private let widget = SQL.Table("Widget")

class PredicateTests: XCTestCase {
    // MARK: - sql
    
    func test_sql_equal_date() {
        let predicate = \Widget.date == Date(timeIntervalSinceReferenceDate: 100_000)
        let sql: SQL.Expression = .column(widget["date"]) == .value(.real(100_000))
        XCTAssertEqual(predicate.sql, sql)
    }
    
    func test_sql_equal_toOne_optional_int() {
        let predicate = \Book.author.died == nil
        
        let sql: SQL.Expression = .join(book["author"], author["id"], .column(author["died"])) == .value(.null)
        XCTAssertEqual(predicate.sql, sql)
    }
    
    func test_sql_equal_optional_int() {
        let predicate = \Author.died == nil
        let sql: SQL.Expression = .column(author["died"]) == .value(.null)
        XCTAssertEqual(predicate.sql, sql)
    }
    
    func test_sql_equal_int() {
        let predicate = \Author.born == 1900
        let sql: SQL.Expression = .column(author["born"]) == .value(.integer(1900))
        XCTAssertEqual(predicate.sql, sql)
    }
    
    func test_sql_equal_string() {
        let predicate = \Author.name == "J.K. Rowling"
        let sql: SQL.Expression = .column(author["name"]) == .value(.text("J.K. Rowling"))
        XCTAssertEqual(predicate.sql, sql)
    }
    
    func test_sql_equal_toOne_string() {
        let predicate = \Book.author.name == "J.K. Rowling"
        
        let sql: SQL.Expression = .join(book["author"], author["id"], .column(author["name"])) == .value(.text("J.K. Rowling"))
        XCTAssertEqual(predicate.sql, sql)
    }
    
    func test_sql_notEqual_date() {
        let predicate = \Widget.date != Date(timeIntervalSinceReferenceDate: 100_000)
        let sql: SQL.Expression = .column(widget["date"]) != .value(.real(100_000))
        XCTAssertEqual(predicate.sql, sql)
    }
    
    func test_sql_notEqual_toOne_optional_int() {
        let predicate = \Book.author.died != nil
        
        let sql: SQL.Expression = .join(book["author"], author["id"], .column(author["died"])) != .value(.null)
        XCTAssertEqual(predicate.sql, sql)
    }
    
    func test_sql_notEqual_toOne_string() {
        let predicate = \Book.author.name != "J.K. Rowling"

        let sql: SQL.Expression = .join(book["author"], author["id"], .column(author["name"])) != .value(.text("J.K. Rowling"))
        XCTAssertEqual(predicate.sql, sql)
    }
    
    func test_sql_or() {
        let predicate = \Author.name == "J" || \Author.name == "K"
        let name = author["name"]
        let sql: SQL.Expression = .column(name) == .value(.text("J")) || .column(name) == .value(.text("K"))
        XCTAssertEqual(predicate.sql, sql)
    }
    
    func test_sql_and() {
        let predicate = \Author.name == "J" && \Author.name == "K"
        let name = author["name"]
        let sql: SQL.Expression = .column(name) == .value(.text("J")) && .column(name) == .value(.text("K"))
        XCTAssertEqual(predicate.sql, sql)
    }
    
    func test_sql_not() {
        let predicate = !(\Author.name == "J.K. Rowling")
        let sql: SQL.Expression = !(.column(author["name"]) == .value(.text("J.K. Rowling")))
        XCTAssertEqual(predicate.sql, sql)
    }
}
