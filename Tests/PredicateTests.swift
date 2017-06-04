import PersistDB
import XCTest

private let jkRowling = Author(
    id: Author.ID("j.k.rowling"),
    name: "J.K. Rowling",
    books: Set()
)

private let sorcerersStone = Book(
    id: Book.ID("1"),
    title: "Harry Potter and the Sorcerer's Stone",
    author: jkRowling
)

class PredicateTests: XCTestCase {
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
}
