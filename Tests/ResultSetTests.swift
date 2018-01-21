@testable import PersistDB
import Schemata
import XCTest

private let grouped = ResultSet<Int, AuthorInfo>([
    Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
    Group(key: 1920, values: [AuthorInfo(.isaacAsimov), AuthorInfo(.rayBradbury)]),
    Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
])

private let ungrouped = ResultSet<None, AuthorInfo>([
    AuthorInfo(.isaacAsimov),
    AuthorInfo(.jrrTolkien),
    AuthorInfo(.orsonScottCard),
    AuthorInfo(.rayBradbury),
])

class ResultSetInitProjections: XCTestCase {
    func testNoProjectionsIsEmpty() {
        let empty = [AuthorInfo]()
        XCTAssertTrue(ResultSet(empty).isEmpty)
    }

    func testNoProjectionsHasGroup() {
        let empty = [AuthorInfo]()
        XCTAssertEqual(ResultSet(empty).groups, [Group(key: .none, values: [])])
    }
}

class ResultSetCollectionTests: XCTestCase {
    func testCountGroupedEmpty() {
        XCTAssertEqual(ResultSet<Int, AuthorInfo>().count, 0)
    }

    func testCountGrouped() {
        XCTAssertEqual(grouped.count, 4)
    }

    func testCountUngroupedEmpty() {
        XCTAssertEqual(ResultSet<None, AuthorInfo>().count, 0)
    }

    func testCountUngrouped() {
        XCTAssertEqual(ungrouped.count, 4)
    }
}

class ResultSetDiffTests: XCTestCase {
    func testNoDiff() {
        let actual = grouped.diff(from: grouped)
        let expected = ResultSet<Int, AuthorInfo>.Diff([])
        XCTAssertEqual(actual, expected)
    }

    func testToEmpty() {
        let actual = ResultSet().diff(from: grouped)
        let expected = ResultSet<Int, AuthorInfo>.Diff([
            .deleteGroup(0),
            .deleteValue(0, 0),
            .deleteGroup(1),
            .deleteValue(1, 0),
            .deleteValue(1, 1),
            .deleteGroup(2),
            .deleteValue(2, 0),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testFromEmpty() {
        let actual = grouped.diff(from: ResultSet())
        let expected = ResultSet<Int, AuthorInfo>.Diff([
            .insertGroup(0),
            .insertValue(0, 0),
            .insertGroup(1),
            .insertValue(1, 0),
            .insertValue(1, 1),
            .insertGroup(2),
            .insertValue(2, 0),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testInsertEmptyGroup() {
        let empty = ResultSet<None, AuthorInfo>([
            Group(key: .none, values: []),
        ])
        let actual = empty.diff(from: ResultSet())
        let expected = ResultSet<None, AuthorInfo>.Diff([
            .insertGroup(0),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testDeleteEmptyGroup() {
        let empty = ResultSet<None, AuthorInfo>([
            Group(key: .none, values: []),
        ])
        let actual = ResultSet().diff(from: empty)
        let expected = ResultSet<None, AuthorInfo>.Diff([
            .deleteGroup(0),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testInsertGroup() {
        let after = ResultSet<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1920, values: [AuthorInfo(.isaacAsimov), AuthorInfo(.rayBradbury)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
            Group(key: 1963, values: [AuthorInfo(.liuCixin)]),
        ])
        let actual = after.diff(from: grouped)
        let expected = ResultSet<Int, AuthorInfo>.Diff([
            .insertGroup(3),
            .insertValue(3, 0),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testDeleteGroup() {
        let after = ResultSet<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
        ])
        let actual = after.diff(from: grouped)
        let expected = ResultSet<Int, AuthorInfo>.Diff([
            .deleteGroup(1),
            .deleteValue(1, 0),
            .deleteValue(1, 1),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testMoveGroup() {
        let after = ResultSet<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
            Group(key: 1920, values: [AuthorInfo(.isaacAsimov), AuthorInfo(.rayBradbury)]),
        ])
        let actual = after.diff(from: grouped)
        let expected = ResultSet<Int, AuthorInfo>.Diff([
            .moveGroup(1, 2),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testMoveWithinMoveGroup() {
        let after = ResultSet<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
            Group(key: 1920, values: [AuthorInfo(.rayBradbury), AuthorInfo(.isaacAsimov)]),
        ])
        let actual = after.diff(from: grouped)
        let expected = ResultSet<Int, AuthorInfo>.Diff([
            .moveGroup(1, 2),
            .updateValue(1, 1, 2, 0),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testUpdateGroup() {
        let after = ResultSet<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 0, values: [AuthorInfo(.isaacAsimov), AuthorInfo(.rayBradbury)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
        ])
        let actual = after.diff(from: grouped)
        let expected = ResultSet<Int, AuthorInfo>.Diff([
            .deleteGroup(1),
            .insertGroup(1),
            .updateValue(1, 0, 1, 0),
            .updateValue(1, 1, 1, 1),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testInsertValue() {
        let before = ResultSet<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1920, values: [AuthorInfo(.isaacAsimov)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
        ])
        let actual = grouped.diff(from: before)
        let expected = ResultSet<Int, AuthorInfo>.Diff([
            .insertValue(1, 1),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testDeleteValue() {
        let after = ResultSet<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1920, values: [AuthorInfo(.isaacAsimov)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
        ])
        let actual = after.diff(from: grouped)
        let expected = ResultSet<Int, AuthorInfo>.Diff([
            .deleteValue(1, 1),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testUpdateValue() {
        let asimov = AuthorInfo(.isaacAsimov, name: Author.Data.isaacAsimov.givenName)

        let after = ResultSet<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1920, values: [asimov, AuthorInfo(.rayBradbury)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
        ])
        let actual = after.diff(from: grouped)
        let expected = ResultSet<Int, AuthorInfo>.Diff([
            .updateValue(1, 0, 1, 0),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testReplaceValue() {
        let after = ResultSet<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1920, values: [AuthorInfo(.liuCixin), AuthorInfo(.rayBradbury)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
        ])
        let actual = after.diff(from: grouped)
        let expected = ResultSet<Int, AuthorInfo>.Diff([
            .deleteValue(1, 0),
            .insertValue(1, 0),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testMoveValueWithinGroup() {
        let after = ResultSet<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1920, values: [AuthorInfo(.rayBradbury), AuthorInfo(.isaacAsimov)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
        ])
        let actual = after.diff(from: grouped)
        let expected = ResultSet<Int, AuthorInfo>.Diff([
            .updateValue(1, 0, 1, 1),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testMoveValueBetweenGroups() {
        let after = ResultSet<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1920, values: [AuthorInfo(.isaacAsimov)]),
            Group(key: 1951, values: [AuthorInfo(.rayBradbury), AuthorInfo(.orsonScottCard)]),
        ])
        let actual = after.diff(from: grouped)
        let expected = ResultSet<Int, AuthorInfo>.Diff([
            .updateValue(1, 1, 2, 0),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testInsertValueBeforeDelete() {
        let after = ResultSet<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1920, values: [AuthorInfo(.liuCixin), AuthorInfo(.isaacAsimov)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
        ])
        let actual = after.diff(from: grouped)
        let expected = ResultSet<Int, AuthorInfo>.Diff([
            .insertValue(1, 0),
            .deleteValue(1, 1),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testDeleteValueBeforeInsert() {
        let after = ResultSet<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1920, values: [AuthorInfo(.rayBradbury), AuthorInfo(.liuCixin)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
        ])
        let actual = after.diff(from: grouped)
        let expected = ResultSet<Int, AuthorInfo>.Diff([
            .insertValue(1, 1),
            .deleteValue(1, 0),
        ])
        XCTAssertEqual(actual, expected)
    }
}
