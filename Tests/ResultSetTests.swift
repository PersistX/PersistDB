@testable import PersistDB
import Schemata
import XCTest

private let groupedEmpty = ResultSet<Int, AuthorInfo>()
private let grouped = ResultSet<Int, AuthorInfo>([
    Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
    Group(key: 1920, values: [AuthorInfo(.isaacAsimov), AuthorInfo(.rayBradbury)]),
    Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
])

private let ungroupedEmpty = ResultSet<None, AuthorInfo>()
private let ungrouped = ResultSet<None, AuthorInfo>([
    AuthorInfo(.isaacAsimov),
    AuthorInfo(.jrrTolkien),
    AuthorInfo(.orsonScottCard),
    AuthorInfo(.rayBradbury),
])

class ResultSetCollectionTests: XCTestCase {
    func testCountGroupedEmpty() {
        XCTAssertEqual(groupedEmpty.count, 0)
    }

    func testCountGrouped() {
        XCTAssertEqual(grouped.count, 4)
    }

    func testCountUngroupedEmpty() {
        XCTAssertEqual(ungroupedEmpty.count, 0)
    }

    func testCountUngrouped() {
        XCTAssertEqual(ungrouped.count, 4)
    }
}
