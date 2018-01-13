import PersistDB
import XCTest

class QueryTests: XCTestCase {
    func testSortBy() {
        let query = Author.all
            .filter(\Author.name != "J.K. Rowling")
            .sort(by: \Author.died, ascending: false)
            .sort(by: \Author.born)

        let expected = [
            Ordering(\Author.born),
            Ordering(\Author.died, ascending: false),
        ]

        XCTAssertEqual(query.predicates, [\.name != "J.K. Rowling"])
        XCTAssertEqual(query.order, expected)
    }
}
