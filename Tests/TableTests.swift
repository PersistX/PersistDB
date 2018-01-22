@testable import PersistDB
import Schemata
import XCTest

private let grouped: Table<Int, AuthorInfo> = Table([
    Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
    Group(key: 1920, values: [AuthorInfo(.isaacAsimov), AuthorInfo(.rayBradbury)]),
    Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
])

private let ungrouped: Table<None, AuthorInfo> = Table([
    AuthorInfo(.isaacAsimov),
    AuthorInfo(.jrrTolkien),
    AuthorInfo(.orsonScottCard),
    AuthorInfo(.rayBradbury),
])

class TableSelectedTests: XCTestCase {
    func testEmpty() {
        XCTAssertNil(grouped.selected)
    }

    func testNonEmpty() {
        let table = Table(grouped.resultSet, selectedIDs: [.jrrTolkien, .rayBradbury])
        let expected: Predicate<Author> = [
            Author.ID.jrrTolkien,
            Author.ID.rayBradbury,
        ].contains(\.id)
        XCTAssertEqual(table.selected, expected)
    }
}

class TableRowCountTests: XCTestCase {
    func testEmptyGrouped() {
        XCTAssertEqual(Table<Int, AuthorInfo>().rowCount, 0)
    }

    func testEmptyUngrouped() {
        XCTAssertEqual(Table<None, AuthorInfo>().rowCount, 0)
    }

    func testGrouped() {
        XCTAssertEqual(grouped.rowCount, 7)
    }

    func testUngrouped() {
        XCTAssertEqual(ungrouped.rowCount, 4)
    }
}

class TableIndexPathForRowTests: XCTestCase {
    func testFirstIndexInUngrouped() {
        XCTAssertEqual(ungrouped.indexPath(forRow: 0), [0, 0])
    }

    func testFirstGroupIndex() {
        XCTAssertEqual(grouped.indexPath(forRow: 0), [0])
    }

    func testFirstGroupFirstValueIndex() {
        XCTAssertEqual(grouped.indexPath(forRow: 1), [0, 0])
    }

    func testSecondGroupIndex() {
        XCTAssertEqual(grouped.indexPath(forRow: 2), [1])
    }

    func testSecondGroupFirstValueIndex() {
        XCTAssertEqual(grouped.indexPath(forRow: 3), [1, 0])
    }

    func testSecondGroupSecondValueIndex() {
        XCTAssertEqual(grouped.indexPath(forRow: 4), [1, 1])
    }
}

class TableRowForIndexPathTests: XCTestCase {
    func testFirstIndexInUngrouped() {
        XCTAssertEqual(ungrouped.row(for: [0, 0]), 0)
    }

    func testFirstGroupIndex() {
        XCTAssertEqual(grouped.row(for: [0]), 0)
    }

    func testFirstGroupFirstValueIndex() {
        XCTAssertEqual(grouped.row(for: [0, 0]), 1)
    }

    func testSecondGroupIndex() {
        XCTAssertEqual(grouped.row(for: [1]), 2)
    }

    func testSecondGroupFirstValueIndex() {
        XCTAssertEqual(grouped.row(for: [1, 0]), 3)
    }

    func testSecondGroupSecondValueIndex() {
        XCTAssertEqual(grouped.row(for: [1, 1]), 4)
    }
}

class TableSubscriptRowTests: XCTestCase {
    func testFirstRowInUngrouped() {
        XCTAssertEqual(ungrouped[0], .value(AuthorInfo(.isaacAsimov)))
    }

    func testFirstGroup() {
        XCTAssertEqual(grouped[0], .group(1892))
    }

    func testFirstGroupFirstValue() {
        XCTAssertEqual(grouped[1], .value(AuthorInfo(.jrrTolkien)))
    }

    func testSecondGroup() {
        XCTAssertEqual(grouped[2], .group(1920))
    }

    func testSecondGroupFirstValue() {
        XCTAssertEqual(grouped[3], .value(AuthorInfo(.isaacAsimov)))
    }

    func testSecondGroupSecondValue() {
        XCTAssertEqual(grouped[4], .value(AuthorInfo(.rayBradbury)))
    }
}

class TableSelectedRowsTests: XCTestCase {
    func testEmpty() {
        XCTAssertTrue(grouped.selectedRows.isEmpty)
    }

    func testGrouped() {
        let table = Table(grouped.resultSet, selectedIDs: [ .jrrTolkien, .rayBradbury ])
        var expected = IndexSet()
        expected.update(with: 1)
        expected.update(with: 4)
        XCTAssertEqual(table.selectedRows, expected)
    }

    func testUngrouped() {
        let table = Table(ungrouped.resultSet, selectedIDs: [ .jrrTolkien, .rayBradbury ])
        XCTAssertEqual(table.selectedRows.count, 2)
        XCTAssertTrue(table.selectedRows.contains(1))
        XCTAssertTrue(table.selectedRows.contains(3))
    }
}

class TableSectionCountTests: XCTestCase {
    func testEmptyGrouped() {
        XCTAssertEqual(Table<Int, AuthorInfo>().sectionCount, 0)
    }

    func testEmptyUngrouped() {
        XCTAssertEqual(Table<Int, AuthorInfo>().sectionCount, 0)
    }

    func testGrouped() {
        XCTAssertEqual(grouped.sectionCount, 3)
    }

    func testUngrouped() {
        XCTAssertEqual(ungrouped.sectionCount, 1)
    }
}

class TableRowCountInSectionTests: XCTestCase {
    func testGrouped() {
        XCTAssertEqual(grouped.rowCount(inSection: 1), 2)
    }

    func testUngrouped() {
        XCTAssertEqual(ungrouped.rowCount(inSection: 0), 4)
    }
}

class TableKeyForSectionTests: XCTestCase {
    func testFirstGroup() {
        XCTAssertEqual(grouped.key(forSection: 0), 1892)
    }

    func testSecondGroup() {
        XCTAssertEqual(grouped.key(forSection: 1), 1920)
    }
}

class TableSubscriptIndexPathTests: XCTestCase {
    func testFirstValueInUngrouped() {
        XCTAssertEqual(ungrouped[[0, 0]], AuthorInfo(.isaacAsimov))
    }

    func testFirstGroupFirstValue() {
        XCTAssertEqual(grouped[[0, 0]], AuthorInfo(.jrrTolkien))
    }

    func testSecondGroupFirstValue() {
        XCTAssertEqual(grouped[[1, 0]], AuthorInfo(.isaacAsimov))
    }

    func testSecondGroupSecondValue() {
        XCTAssertEqual(grouped[[1, 1]], AuthorInfo(.rayBradbury))
    }
}

class TableSelectedIndexPathsTests: XCTestCase {
    func testEmpty() {
        XCTAssertEqual(grouped.selectedIndexPaths, [])
    }

    func testNonEmpty() {
        let table = Table(grouped.resultSet, selectedIDs: [.jrrTolkien, .rayBradbury])
        let expected: Set<IndexPath> = [
            [0, 0],
            [1, 1],
        ]
        XCTAssertEqual(table.selectedIndexPaths, expected)
    }
}

class TableDiffGroupedTests: XCTestCase {
    func testToEmpty() {
        let actual = Table().diff(from: grouped)
        let expected = Table<Int, AuthorInfo>.Diff([
            .delete(.init(row: 0, indexPath: IndexPath(index: 0))),
            .delete(.init(row: 1, indexPath: [0, 0])),
            .delete(.init(row: 2, indexPath: IndexPath(index: 1))),
            .delete(.init(row: 3, indexPath: [1, 0])),
            .delete(.init(row: 4, indexPath: [1, 1])),
            .delete(.init(row: 5, indexPath: IndexPath(index: 2))),
            .delete(.init(row: 6, indexPath: [2, 0])),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testFromEmpty() {
        let actual = grouped.diff(from: Table())
        let expected = Table<Int, AuthorInfo>.Diff([
            .insert(.init(row: 0, indexPath: IndexPath(index: 0))),
            .insert(.init(row: 1, indexPath: [0, 0])),
            .insert(.init(row: 2, indexPath: IndexPath(index: 1))),
            .insert(.init(row: 3, indexPath: [1, 0])),
            .insert(.init(row: 4, indexPath: [1, 1])),
            .insert(.init(row: 5, indexPath: IndexPath(index: 2))),
            .insert(.init(row: 6, indexPath: [2, 0])),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testInsertSection() {
        let after = Table<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1920, values: [AuthorInfo(.isaacAsimov), AuthorInfo(.rayBradbury)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
            Group(key: 1963, values: [AuthorInfo(.liuCixin)]),
        ])
        let actual = after.diff(from: grouped)
        let expected = Table<Int, AuthorInfo>.Diff([
            .insert(.init(row: 7, indexPath: IndexPath(index: 3))),
            .insert(.init(row: 8, indexPath: [3, 0])),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testDeleteSection() {
        let after = Table<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
        ])
        let actual = after.diff(from: grouped)
        let expected = Table<Int, AuthorInfo>.Diff([
            .delete(.init(row: 2, indexPath: IndexPath(index: 1))),
            .delete(.init(row: 3, indexPath: [1, 0])),
            .delete(.init(row: 4, indexPath: [1, 1])),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testMoveSection() {
        let after = Table<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
            Group(key: 1920, values: [AuthorInfo(.isaacAsimov), AuthorInfo(.rayBradbury)]),
        ])
        let actual = after.diff(from: grouped)
        let expected = Table<Int, AuthorInfo>.Diff([
            .update(
                .init(row: 2, indexPath: IndexPath(index: 1)),
                .init(row: 4, indexPath: IndexPath(index: 2))
            ),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testMoveWithinMoveGroup() {
        let after = Table<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
            Group(key: 1920, values: [AuthorInfo(.rayBradbury), AuthorInfo(.isaacAsimov)]),
        ])
        let actual = after.diff(from: grouped)
        let expected = Table<Int, AuthorInfo>.Diff([
            .update(
                .init(row: 2, indexPath: IndexPath(index: 1)),
                .init(row: 4, indexPath: IndexPath(index: 2))
            ),
            .update(
                .init(row: 4, indexPath: [1, 1]),
                .init(row: 5, indexPath: [2, 0])
            ),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testUpdateGroup() {
        let after = Table<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 0, values: [AuthorInfo(.isaacAsimov), AuthorInfo(.rayBradbury)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
        ])
        let actual = after.diff(from: grouped)
        let expected = Table<Int, AuthorInfo>.Diff([
            .delete(.init(row: 2, indexPath: IndexPath(index: 1))),
            .insert(.init(row: 2, indexPath: IndexPath(index: 1))),
            .update(
                .init(row: 3, indexPath: [1, 0]),
                .init(row: 3, indexPath: [1, 0])
            ),
            .update(
                .init(row: 4, indexPath: [1, 1]),
                .init(row: 4, indexPath: [1, 1])
            ),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testInsertValue() {
        let before = Table<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1920, values: [AuthorInfo(.isaacAsimov)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
        ])
        let actual = grouped.diff(from: before)
        let expected = Table<Int, AuthorInfo>.Diff([
            .insert(.init(row: 4, indexPath: [1, 1])),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testDeleteValue() {
        let after = Table<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1920, values: [AuthorInfo(.isaacAsimov)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
        ])
        let actual = after.diff(from: grouped)
        let expected = Table<Int, AuthorInfo>.Diff([
            .delete(.init(row: 4, indexPath: [1, 1])),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testUpdateValue() {
        let asimov = AuthorInfo(.isaacAsimov, name: Author.Data.isaacAsimov.givenName)

        let after = Table<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1920, values: [asimov, AuthorInfo(.rayBradbury)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
        ])
        let actual = after.diff(from: grouped)
        let expected = Table<Int, AuthorInfo>.Diff([
            .update(
                .init(row: 3, indexPath: [1, 0]),
                .init(row: 3, indexPath: [1, 0])
            ),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testReplaceValue() {
        let after = Table<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1920, values: [AuthorInfo(.liuCixin), AuthorInfo(.rayBradbury)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
        ])
        let actual = after.diff(from: grouped)
        let expected = Table<Int, AuthorInfo>.Diff([
            .delete(.init(row: 3, indexPath: [1, 0])),
            .insert(.init(row: 3, indexPath: [1, 0])),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testMoveValueWithinGroup() {
        let after = Table<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1920, values: [AuthorInfo(.rayBradbury), AuthorInfo(.isaacAsimov)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
        ])
        let actual = after.diff(from: grouped)
        let expected = Table<Int, AuthorInfo>.Diff([
            .update(
                .init(row: 3, indexPath: [1, 0]),
                .init(row: 4, indexPath: [1, 1])
            ),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testMoveValueBetweenGroups() {
        let after = Table<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1920, values: [AuthorInfo(.isaacAsimov)]),
            Group(key: 1951, values: [AuthorInfo(.rayBradbury), AuthorInfo(.orsonScottCard)]),
        ])
        let actual = after.diff(from: grouped)
        let expected = Table<Int, AuthorInfo>.Diff([
            .update(
                .init(row: 4, indexPath: [1, 1]),
                .init(row: 5, indexPath: [2, 0])
            ),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testInsertValueBeforeDelete() {
        let after = Table<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1920, values: [AuthorInfo(.liuCixin), AuthorInfo(.isaacAsimov)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
        ])
        let actual = after.diff(from: grouped)
        let expected = Table<Int, AuthorInfo>.Diff([
            .delete(.init(row: 4, indexPath: [1, 1])),
            .insert(.init(row: 3, indexPath: [1, 0])),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testDeleteValueBeforeInsert() {
        let after = Table<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1920, values: [AuthorInfo(.rayBradbury), AuthorInfo(.liuCixin)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
        ])
        let actual = after.diff(from: grouped)
        let expected = Table<Int, AuthorInfo>.Diff([
            .delete(.init(row: 3, indexPath: [1, 0])),
            .insert(.init(row: 4, indexPath: [1, 1])),
        ])
        XCTAssertEqual(actual, expected)
    }
}

class TableDiffUngroupedTests: XCTestCase {
    func testToEmpty() {
        let actual = Table().diff(from: ungrouped)
        let expected = Table<None, AuthorInfo>.Diff([
            .delete(.init(row: 0, indexPath: [0, 0])),
            .delete(.init(row: 1, indexPath: [0, 1])),
            .delete(.init(row: 2, indexPath: [0, 2])),
            .delete(.init(row: 3, indexPath: [0, 3])),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testFromEmpty() {
        let actual = ungrouped.diff(from: Table())
        let expected = Table<None, AuthorInfo>.Diff([
            .insert(.init(row: 0, indexPath: [0, 0])),
            .insert(.init(row: 1, indexPath: [0, 1])),
            .insert(.init(row: 2, indexPath: [0, 2])),
            .insert(.init(row: 3, indexPath: [0, 3])),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testDelete() {
        let new = Table<None, AuthorInfo>([
            ungrouped[[0, 0]],
            ungrouped[[0, 2]],
        ])

        let actual = new.diff(from: ungrouped)
        let expected = Table<None, AuthorInfo>.Diff([
            .delete(.init(row: 1, indexPath: [0, 1])),
            .delete(.init(row: 3, indexPath: [0, 3])),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testInsert() {
        let old = Table<None, AuthorInfo>([
            ungrouped[[0, 0]],
            ungrouped[[0, 2]],
        ])

        let actual = ungrouped.diff(from: old)
        let expected = Table<None, AuthorInfo>.Diff([
            .insert(.init(row: 1, indexPath: [0, 1])),
            .insert(.init(row: 3, indexPath: [0, 3])),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testMove() {
        let new = Table<None, AuthorInfo>([
            ungrouped[[0, 2]],
            ungrouped[[0, 0]],
            ungrouped[[0, 1]],
            ungrouped[[0, 3]],
        ])

        let actual = new.diff(from: ungrouped)
        let expected = Table<None, AuthorInfo>.Diff([
            .update(
                .init(row: 2, indexPath: [0, 2]),
                .init(row: 0, indexPath: [0, 0])
            ),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testUpdate() {
        var info = ungrouped[[0, 0]]
        info.name = Author.Data.isaacAsimov.givenName

        let new = Table<None, AuthorInfo>([
            info,
            ungrouped[[0, 1]],
            ungrouped[[0, 2]],
            ungrouped[[0, 3]],
        ])

        let actual = new.diff(from: ungrouped)
        let expected = Table<None, AuthorInfo>.Diff([
            .update(
                .init(row: 0, indexPath: [0, 0]),
                .init(row: 0, indexPath: [0, 0])
            ),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testInsertBeforeDelete() {
        let new = Table<None, AuthorInfo>([
            AuthorInfo(.isaacAsimov),
            AuthorInfo(.jrrTolkien),
            AuthorInfo(.liuCixin),
            AuthorInfo(.orsonScottCard),
        ])

        let actual = new.diff(from: ungrouped)
        let expected = Table<None, AuthorInfo>.Diff([
            .insert(.init(row: 2, indexPath: [0, 2])),
            .delete(.init(row: 3, indexPath: [0, 3])),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testDeleteBeforeInsert() {
        let new = Table<None, AuthorInfo>([
            AuthorInfo(.jrrTolkien),
            AuthorInfo(.liuCixin),
            AuthorInfo(.orsonScottCard),
            AuthorInfo(.rayBradbury),
        ])

        let actual = new.diff(from: ungrouped)
        let expected = Table<None, AuthorInfo>.Diff([
            .delete(.init(row: 0, indexPath: [0, 0])),
            .insert(.init(row: 1, indexPath: [0, 1])),
        ])
        XCTAssertEqual(actual, expected)
    }
}
