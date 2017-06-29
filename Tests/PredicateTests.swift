@testable import PersistDB
import Schemata
import XCTest

private let jkRowling = Author(
    id: Author.ID(1),
    name: "J.K. Rowling",
    born: 1965,
    died: nil,
    books: Set()
)

private let sorcerersStone = Book(
    id: Book.ID(1),
    title: "Harry Potter and the Sorcerer's Stone",
    author: jkRowling
)

class PredicateTests: XCTestCase {
    //  MARK: - evaluate
    
    func test_evaluate_equal_string_true() {
        let predicate = \Author.name == "J.K. Rowling"
        XCTAssertTrue(predicate.evaluate(jkRowling))
    }
    
    func test_evaluate_equal_string_false() {
        let predicate = \Author.name == "Ray Bradbury"
        XCTAssertFalse(predicate.evaluate(jkRowling))
    }
    
    func test_evaluate_equal_toOne_string_true() {
        let predicate = \Book.author.name == "J.K. Rowling"
        XCTAssertTrue(predicate.evaluate(sorcerersStone))
    }
    
    func test_evaluate_equal_toOne_string_false() {
        let predicate = \Book.author.name == "Ray Bradbury"
        XCTAssertFalse(predicate.evaluate(sorcerersStone))
    }
    
    // MARK: - sqlExpression
    
    func test_sqlExpression_equal_string() {
        let predicate = \Author.name == "J.K. Rowling"
        let sql = SQL.Table("Author")["name"] == "J.K. Rowling"
        XCTAssertEqual(predicate.sql, sql)
    }
    
    func test_sqlExpression_equal_toOne_string() {
        let predicate = \Book.author.name == "J.K. Rowling"
        
        let author = SQL.Table("Author")
        let book = SQL.Table("Book")
        let sql = book["author"] == author["id"] && author["name"] == "J.K. Rowling"
        XCTAssertEqual(predicate.sql, sql)
    }
}
