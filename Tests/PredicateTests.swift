@testable import PersistDB
import XCTest

class PredicateTests: XCTestCase {
    // MARK: - sql
    
    func test_sql_equal_string() {
        let predicate = \Author.name == "J.K. Rowling"
        let sql: SQL.Expression = SQL.Table("Author")["name"] == .value(.text("J.K. Rowling"))
        XCTAssertEqual(predicate.sql, sql)
    }
    
    func test_sql_equal_toOne_string() {
        let predicate = \Book.author.name == "J.K. Rowling"
        
        let author = SQL.Table("Author")
        let book = SQL.Table("Book")
        let sql: SQL.Expression = book["author"] == author["id"] && author["name"] == .value(.text("J.K. Rowling"))
        XCTAssertEqual(predicate.sql, sql)
    }
}
