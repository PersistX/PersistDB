import PersistDB
import XCTest

private let jkRowling = Author(
    id: Author.ID("j.k.rowling"),
    name: "J.K. Rowling",
    books: Set()
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
}
