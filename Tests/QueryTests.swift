import PersistDB
import XCTest

class QueryTests: XCTestCase {
    func testSortBy() {
        let query = Author.all
            .filter(\Author.name != "J.K. Rowling")
            .sort(by: \Author.died, ascending: false)
            .sort(by: \Author.born, ascending: true)
        
        let expected = [
            SortDescriptor(keyPath: \Author.born, ascending: true),
            SortDescriptor(keyPath: \Author.died, ascending: false),
        ]
        
        XCTAssertEqual(query.predicates, [\.name != "J.K. Rowling"])
        XCTAssertEqual(query.sortDescriptors, expected)
    }
}
