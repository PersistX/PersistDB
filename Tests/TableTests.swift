@testable import PersistDB
import Schemata
import XCTest

private let grouped: Table<Int, AuthorInfo> = Table([
    Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
    Group(key: 1920, values: [AuthorInfo(.isaacAsimov), AuthorInfo(.rayBradbury)]),
    Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
])

private let ungrouped: Table<Int, AuthorInfo> = Table(grouped.resultSet, hasGroupRows: false)

class TableResultDidSetSelectedIDsTests: XCTestCase {
    func testInsertDoesNotAffectSelection() {
        var table = Table([
            Group(key: 1920, values: [AuthorInfo(.isaacAsimov), AuthorInfo(.rayBradbury)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
        ])
        table.selectedIDs = [ .isaacAsimov, .rayBradbury ]
        table.resultSet = grouped.resultSet
        XCTAssertEqual(table.selectedIDs, [ .isaacAsimov, .rayBradbury ])
    }

    func testMoveDoesNotAffectSelection() {
        var table = Table([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1920, values: [AuthorInfo(.rayBradbury), AuthorInfo(.isaacAsimov)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
        ])
        table.selectedIDs = [ .isaacAsimov, .rayBradbury ]
        table.resultSet = grouped.resultSet
        XCTAssertEqual(table.selectedIDs, [ .isaacAsimov, .rayBradbury ])
    }

    func testPartialDeleteRemovesSelection() {
        var table = Table([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1920, values: [
                AuthorInfo(.rayBradbury),
                AuthorInfo(.liuCixin),
                AuthorInfo(.isaacAsimov),
            ]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
        ])
        table.selectedIDs = [ .isaacAsimov, .liuCixin, .rayBradbury ]
        table.resultSet = grouped.resultSet
        XCTAssertEqual(table.selectedIDs, [ .isaacAsimov, .rayBradbury ])
    }

    func testTotalDeleteRemovesSelection() {
        var table = grouped
        table.selectedIDs = [ .isaacAsimov, .rayBradbury ]
        table.resultSet = ResultSet([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
        ])
        XCTAssertEqual(table.selectedIDs, [])
    }
}

class TableMapKeysTests: XCTestCase {
    func test() {
        let mapped = grouped.mapKeys { $0.description }
        let expected: Table<String, AuthorInfo> = Table([
            Group(key: "1892", values: [AuthorInfo(.jrrTolkien)]),
            Group(key: "1920", values: [AuthorInfo(.isaacAsimov), AuthorInfo(.rayBradbury)]),
            Group(key: "1951", values: [AuthorInfo(.orsonScottCard)]),
        ])
        XCTAssertEqual(mapped, expected)
    }

    func testPreservesSelection() {
        let table = Table(grouped.resultSet, selectedIDs: [.jrrTolkien, .rayBradbury])
        let mapped = table.mapKeys { $0.description }
        XCTAssertEqual(mapped.selectedIDs, table.selectedIDs)
    }

    func testPreservesGrouping() {
        let mapped = ungrouped.mapKeys { $0.description }
        XCTAssertFalse(mapped.hasGroupRows)
    }
}

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

class TableSelectedValuesTests: XCTestCase {
    func testEmpty() {
        XCTAssertTrue(grouped.selectedValues.isEmpty)
    }

    func testNonEmpty() {
        let table = Table(grouped.resultSet, selectedIDs: [.jrrTolkien, .rayBradbury])
        XCTAssertEqual(table.selectedValues, [ AuthorInfo(.jrrTolkien), AuthorInfo(.rayBradbury) ])
    }
}

class TableRowCountTests: XCTestCase {
    func testGroupedEmpty() {
        XCTAssertEqual(Table<Int, AuthorInfo>().rowCount, 0)
    }

    func testUngroupedEmpty() {
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
    func testUngrouped0x0() {
        XCTAssertEqual(ungrouped.indexPath(forRow: 0), [0, 0])
    }

    func testUngrouped1x0() {
        XCTAssertEqual(ungrouped.indexPath(forRow: 1), [1, 0])
    }

    func testUngrouped1x1() {
        XCTAssertEqual(ungrouped.indexPath(forRow: 2), [1, 1])
    }

    func testGrouped0() {
        XCTAssertEqual(grouped.indexPath(forRow: 0), [0])
    }

    func testGrouped0x0() {
        XCTAssertEqual(grouped.indexPath(forRow: 1), [0, 0])
    }

    func testGrouped1() {
        XCTAssertEqual(grouped.indexPath(forRow: 2), [1])
    }

    func testGrouped1x0() {
        XCTAssertEqual(grouped.indexPath(forRow: 3), [1, 0])
    }

    func testGrouped1x1() {
        XCTAssertEqual(grouped.indexPath(forRow: 4), [1, 1])
    }
}

class TableRowForIndexPathTests: XCTestCase {
    func testUngrouped0() {
        XCTAssertNil(ungrouped.row(for: [0]))
    }

    func testUngrouped0x0() {
        XCTAssertEqual(ungrouped.row(for: [0, 0]), 0)
    }

    func testUngrouped1() {
        XCTAssertNil(ungrouped.row(for: [1]))
    }

    func testUngrouped1x0() {
        XCTAssertEqual(ungrouped.row(for: [1, 0]), 1)
    }

    func testUngrouped1x1() {
        XCTAssertEqual(ungrouped.row(for: [1, 1]), 2)
    }

    func testGrouped0() {
        XCTAssertEqual(grouped.row(for: [0]), 0)
    }

    func testGrouped0x0() {
        XCTAssertEqual(grouped.row(for: [0, 0]), 1)
    }

    func testGrouped1() {
        XCTAssertEqual(grouped.row(for: [1]), 2)
    }

    func testGrouped1x0() {
        XCTAssertEqual(grouped.row(for: [1, 0]), 3)
    }

    func testGrouped1x1() {
        XCTAssertEqual(grouped.row(for: [1, 1]), 4)
    }
}

class TableSubscriptRowTests: XCTestCase {
    func testUngrouped0x0() {
        XCTAssertEqual(ungrouped[0], .value(AuthorInfo(.jrrTolkien)))
    }

    func testUngrouped1x0() {
        XCTAssertEqual(ungrouped[1], .value(AuthorInfo(.isaacAsimov)))
    }

    func testUngrouped1x1() {
        XCTAssertEqual(ungrouped[2], .value(AuthorInfo(.rayBradbury)))
    }

    func testGrouped0() {
        XCTAssertEqual(grouped[0], .group(1892))
    }

    func testGrouped0x0() {
        XCTAssertEqual(grouped[1], .value(AuthorInfo(.jrrTolkien)))
    }

    func testGrouped1() {
        XCTAssertEqual(grouped[2], .group(1920))
    }

    func testGrouped1x0() {
        XCTAssertEqual(grouped[3], .value(AuthorInfo(.isaacAsimov)))
    }

    func testGrouped1x1() {
        XCTAssertEqual(grouped[4], .value(AuthorInfo(.rayBradbury)))
    }
}

class TableSelectedRowsGetTests: XCTestCase {
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
        let table = Table(
            ungrouped.resultSet,
            selectedIDs: [ .jrrTolkien, .rayBradbury ],
            hasGroupRows: false
        )
        XCTAssertEqual(table.selectedRows.count, 2)
        XCTAssertTrue(table.selectedRows.contains(0))
        XCTAssertTrue(table.selectedRows.contains(2))
    }
}

class TableSelectedRowsSetTests: XCTestCase {
    func testEmpty() {
        var table = Table(grouped.resultSet, selectedIDs: [ .jrrTolkien, .rayBradbury ])

        table.selectedRows = IndexSet()

        XCTAssertEqual(table.selectedIDs, [])
    }

    func testGrouped() {
        var table = Table(grouped.resultSet, selectedIDs: [ .jrrTolkien, .rayBradbury ])
        var expected = IndexSet()
        expected.update(with: 3)
        expected.update(with: 6)

        table.selectedRows = expected

        XCTAssertEqual(table.selectedIDs, [ .isaacAsimov, .orsonScottCard ])
    }

    func testUngrouped() {
        var table = Table(
            ungrouped.resultSet,
            selectedIDs: [ .jrrTolkien, .rayBradbury ],
            hasGroupRows: false
        )
        var expected = IndexSet()
        expected.update(with: 1)
        expected.update(with: 3)

        table.selectedRows = expected

        XCTAssertEqual(table.selectedIDs, [ .isaacAsimov, .orsonScottCard ])
    }
}

class TableRowForIDTests: XCTestCase {
    func testIncluded() {
        XCTAssertEqual(grouped.row(for: .rayBradbury), 4)
    }

    func testNotIncluded() {
        XCTAssertNil(grouped.row(for: .liuCixin))
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
        XCTAssertEqual(ungrouped.sectionCount, 3)
    }
}

class TableRowCountInSectionTests: XCTestCase {
    func testGrouped() {
        XCTAssertEqual(grouped.rowCount(inSection: 1), 2)
    }

    func testUngrouped() {
        XCTAssertEqual(ungrouped.rowCount(inSection: 1), 2)
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

class TableSelectedIndexPathsGetTests: XCTestCase {
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

class TableSelectedIndexPathsSetTests: XCTestCase {
    func testEmpty() {
        var table = Table(grouped.resultSet, selectedIDs: [.jrrTolkien, .rayBradbury])

        table.selectedIndexPaths = []

        XCTAssertEqual(grouped.selectedIDs, [])
    }

    func testNonEmpty() {
        var table = Table(grouped.resultSet, selectedIDs: [.jrrTolkien, .rayBradbury])

        table.selectedIndexPaths = [
            [1, 0],
            [2, 0],
        ]

        XCTAssertEqual(table.selectedIDs, [ .isaacAsimov, .orsonScottCard ])
    }
}

class TableIndexPathForIDTests: XCTestCase {
    func testIncluded() {
        XCTAssertEqual(grouped.indexPath(for: .rayBradbury), [1, 1])
    }

    func testNotIncluded() {
        XCTAssertNil(grouped.indexPath(for: .liuCixin))
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
            .move(
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
            .move(
                .init(row: 2, indexPath: IndexPath(index: 1)),
                .init(row: 4, indexPath: IndexPath(index: 2))
            ),
            .move(
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
            .move(
                .init(row: 3, indexPath: [1, 0]),
                .init(row: 3, indexPath: [1, 0])
            ),
            .move(
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
            .update(.init(row: 3, indexPath: [1, 0])),
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
            .move(
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
            .move(
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
        let expected = Table<Int, AuthorInfo>.Diff([
            .delete(.init(row: nil, indexPath: IndexPath(index: 0))),
            .delete(.init(row: 0, indexPath: [0, 0])),
            .delete(.init(row: nil, indexPath: IndexPath(index: 1))),
            .delete(.init(row: 1, indexPath: [1, 0])),
            .delete(.init(row: 2, indexPath: [1, 1])),
            .delete(.init(row: nil, indexPath: IndexPath(index: 2))),
            .delete(.init(row: 3, indexPath: [2, 0])),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testFromEmpty() {
        let actual = ungrouped.diff(from: Table())
        let expected = Table<Int, AuthorInfo>.Diff([
            .insert(.init(row: nil, indexPath: IndexPath(index: 0))),
            .insert(.init(row: 0, indexPath: [0, 0])),
            .insert(.init(row: nil, indexPath: IndexPath(index: 1))),
            .insert(.init(row: 1, indexPath: [1, 0])),
            .insert(.init(row: 2, indexPath: [1, 1])),
            .insert(.init(row: nil, indexPath: IndexPath(index: 2))),
            .insert(.init(row: 3, indexPath: [2, 0])),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testDelete() {
        let new = ResultSet<Int, AuthorInfo>([
            Group(key: 1920, values: [AuthorInfo(.isaacAsimov)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
        ])

        let actual = Table(new, hasGroupRows: false).diff(from: ungrouped)
        let expected = Table<Int, AuthorInfo>.Diff([
            .delete(.init(row: nil, indexPath: [0])),
            .delete(.init(row: 0, indexPath: [0, 0])),
            .delete(.init(row: 2, indexPath: [1, 1])),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testInsert() {
        let old = ResultSet<Int, AuthorInfo>([
            Group(key: 1920, values: [AuthorInfo(.isaacAsimov)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
        ])

        let actual = ungrouped.diff(from: Table(old, hasGroupRows: false))
        let expected = Table<Int, AuthorInfo>.Diff([
            .insert(.init(row: nil, indexPath: [0])),
            .insert(.init(row: 0, indexPath: [0, 0])),
            .insert(.init(row: 2, indexPath: [1, 1])),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testMove() {
        let new = ResultSet<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.rayBradbury), AuthorInfo(.jrrTolkien)]),
            Group(key: 1920, values: [AuthorInfo(.isaacAsimov)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
        ])

        let actual = Table(new, hasGroupRows: false).diff(from: ungrouped)
        let expected = Table<Int, AuthorInfo>.Diff([
            .move(
                .init(row: 2, indexPath: [1, 1]),
                .init(row: 0, indexPath: [0, 0])
            ),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testUpdate() {
        var info = ungrouped[[1, 0]]
        info.name = Author.Data.isaacAsimov.givenName

        let new = ResultSet<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1920, values: [info, AuthorInfo(.rayBradbury)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
        ])

        let actual = Table(new, hasGroupRows: false).diff(from: ungrouped)
        let expected = Table<Int, AuthorInfo>.Diff([
            .update(.init(row: 1, indexPath: [1, 0])),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testInsertBeforeDelete() {
        let new = ResultSet<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien), AuthorInfo(.liuCixin)]),
            Group(key: 1920, values: [AuthorInfo(.isaacAsimov)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard)]),
        ])

        let actual = Table(new, hasGroupRows: false).diff(from: ungrouped)
        let expected = Table<Int, AuthorInfo>.Diff([
            .insert(.init(row: 1, indexPath: [0, 1])),
            .delete(.init(row: 2, indexPath: [1, 1])),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testDeleteBeforeInsert() {
        let new = ResultSet<Int, AuthorInfo>([
            Group(key: 1892, values: [AuthorInfo(.jrrTolkien)]),
            Group(key: 1920, values: [AuthorInfo(.rayBradbury)]),
            Group(key: 1951, values: [AuthorInfo(.orsonScottCard), AuthorInfo(.liuCixin)]),
        ])

        let actual = Table(new, hasGroupRows: false).diff(from: ungrouped)
        let expected = Table<Int, AuthorInfo>.Diff([
            .delete(.init(row: 1, indexPath: [1, 0])),
            .insert(.init(row: 3, indexPath: [2, 1])),
        ])
        XCTAssertEqual(actual, expected)
    }
}

class TableDiffInsertedRowsTests: XCTestCase {
    func testGrouped() {
        let diff = Table<Int, AuthorInfo>.Diff([
            .insert(.init(row: 0, indexPath: IndexPath(index: 0))),
            .insert(.init(row: 2, indexPath: [1, 0])),
        ])
        XCTAssertEqual(diff.insertedRows.map { $0 }, [0, 2])
    }

    func testUngrouped() {
        let diff = Table<None, AuthorInfo>.Diff([
            .insert(.init(row: nil, indexPath: IndexPath(index: 0))),
            .insert(.init(row: 2, indexPath: [1, 0])),
        ])
        XCTAssertEqual(diff.insertedRows.map { $0 }, [2])
    }
}

class TableDiffDeletedRowsTests: XCTestCase {
    func testGrouped() {
        let diff = Table<Int, AuthorInfo>.Diff([
            .delete(.init(row: 0, indexPath: IndexPath(index: 0))),
            .delete(.init(row: 2, indexPath: [1, 0])),
        ])
        XCTAssertEqual(diff.deletedRows.map { $0 }, [0, 2])
    }

    func testUngrouped() {
        let diff = Table<None, AuthorInfo>.Diff([
            .delete(.init(row: nil, indexPath: IndexPath(index: 0))),
            .delete(.init(row: 2, indexPath: [1, 0])),
        ])
        XCTAssertEqual(diff.deletedRows.map { $0 }, [2])
    }
}

class TableDiffMovedRowsTests: XCTestCase {
    func testGroup() {
        let diff = Table<Int, AuthorInfo>.Diff([
            .move(
                .init(row: 2, indexPath: IndexPath(index: 1)),
                .init(row: 4, indexPath: IndexPath(index: 2))
            ),
        ])
        let moved = diff.movedRows
        XCTAssertEqual(moved.count, 1)
        XCTAssertTrue(moved[0] == (2, 4))
    }

    func testValue() {
        let diff = Table<Int, AuthorInfo>.Diff([
            .move(
                .init(row: 4, indexPath: [1, 1]),
                .init(row: 5, indexPath: [2, 0])
            ),
        ])
        let moved = diff.movedRows
        XCTAssertEqual(moved.count, 1)
        XCTAssertTrue(moved[0] == (4, 5))
    }

    func testWithDeleteBeforeBoth() {
        let diff = Table<Int, AuthorInfo>.Diff([
            .delete(.init(row: 3, indexPath: [1, 0])),
            .move(
                .init(row: 4, indexPath: [1, 1]),
                .init(row: 5, indexPath: [2, 0])
            ),
        ])
        let moved = diff.movedRows
        XCTAssertEqual(moved.count, 1)
        XCTAssertTrue(moved[0] == (3, 5))
    }

    func testWithDeleteBetweenMoveEarlier() {
        let diff = Table<Int, AuthorInfo>.Diff([
            .delete(.init(row: 5, indexPath: [1, 1])),
            .move(
                .init(row: 7, indexPath: [1, 3]),
                .init(row: 4, indexPath: [1, 0])
            ),
        ])
        let moved = diff.movedRows
        XCTAssertEqual(moved.count, 1)
        XCTAssertTrue(moved[0] == (6, 4))
    }

    func testWithDeleteBetweenMoveLater() {
        let diff = Table<Int, AuthorInfo>.Diff([
            .delete(.init(row: 5, indexPath: [1, 1])),
            .move(
                .init(row: 4, indexPath: [1, 0]),
                .init(row: 7, indexPath: [1, 3])
            ),
        ])
        let moved = diff.movedRows
        XCTAssertEqual(moved.count, 1)
        XCTAssertTrue(moved[0] == (4, 7))
    }

    func testWithDeleteAfterBoth() {
        let diff = Table<Int, AuthorInfo>.Diff([
            .delete(.init(row: 7, indexPath: [2, 2])),
            .move(
                .init(row: 4, indexPath: [1, 1]),
                .init(row: 5, indexPath: [2, 0])
            ),
        ])
        let moved = diff.movedRows
        XCTAssertEqual(moved.count, 1)
        XCTAssertTrue(moved[0] == (4, 5))
    }

    func testWithInsertBeforeBoth() {
        let diff = Table<Int, AuthorInfo>.Diff([
            .insert(.init(row: 3, indexPath: [1, 0])),
            .move(
                .init(row: 4, indexPath: [1, 1]),
                .init(row: 6, indexPath: [1, 3])
            ),
        ])
        let moved = diff.movedRows
        XCTAssertEqual(moved.count, 1)
        XCTAssertTrue(moved[0] == (4, 5))
    }

    func testWithInsertBetweenMoveEarlier() {
        let diff = Table<Int, AuthorInfo>.Diff([
            .insert(.init(row: 5, indexPath: [1, 1])),
            .move(
                .init(row: 7, indexPath: [1, 3]),
                .init(row: 4, indexPath: [1, 0])
            ),
        ])
        let moved = diff.movedRows
        XCTAssertEqual(moved.count, 1)
        XCTAssertTrue(moved[0] == (7, 4))
    }

    func testWithInsertBetweenMoveLater() {
        let diff = Table<Int, AuthorInfo>.Diff([
            .insert(.init(row: 5, indexPath: [1, 1])),
            .move(
                .init(row: 4, indexPath: [1, 0]),
                .init(row: 7, indexPath: [1, 3])
            ),
        ])
        let moved = diff.movedRows
        XCTAssertEqual(moved.count, 1)
        XCTAssertTrue(moved[0] == (4, 6))
    }

    func testSwapped() {
        let diff = Table<Int, AuthorInfo>.Diff([
            .move(
                .init(row: 4, indexPath: [1, 0]),
                .init(row: 7, indexPath: [1, 3])
            ),
            .move(
                .init(row: 7, indexPath: [1, 3]),
                .init(row: 4, indexPath: [1, 0])
            ),
        ])
        let moved = diff.movedRows
        XCTAssertEqual(moved.count, 2)
        XCTAssertTrue(moved[0] == (7, 4))
        XCTAssertTrue(moved[1] == (5, 7))
    }

    func testMovedEarlierTogether() {
        let diff = Table<Int, AuthorInfo>.Diff([
            .move(
                .init(row: 8, indexPath: [3, 0]),
                .init(row: 3, indexPath: [1, 0])
            ),
            .move(
                .init(row: 9, indexPath: [3, 1]),
                .init(row: 4, indexPath: [1, 1])
            ),
            .move(
                .init(row: 10, indexPath: [3, 2]),
                .init(row: 5, indexPath: [1, 2])
            ),
        ])
        let moved = diff.movedRows
        XCTAssertEqual(moved.count, 3)
        XCTAssertTrue(moved[0] == (8, 3))
        XCTAssertTrue(moved[1] == (9, 4))
        XCTAssertTrue(moved[2] == (10, 5))
    }

    func testMovedLaterTogether() {
        let diff = Table<Int, AuthorInfo>.Diff([
            .move(
                .init(row: 3, indexPath: [1, 0]),
                .init(row: 8, indexPath: [3, 0])
            ),
            .move(
                .init(row: 4, indexPath: [1, 1]),
                .init(row: 9, indexPath: [3, 1])
            ),
            .move(
                .init(row: 5, indexPath: [1, 2]),
                .init(row: 10, indexPath: [3, 2])
            ),
        ])
        let moved = diff.movedRows
        XCTAssertEqual(moved.count, 3)
        XCTAssertTrue(moved[0] == (3, 10))
        XCTAssertTrue(moved[1] == (3, 10))
        XCTAssertTrue(moved[2] == (3, 10))
    }

    func testMovedLaterTogetherBackwards() {
        let diff = Table<Int, AuthorInfo>.Diff([
            .move(
                .init(row: 3, indexPath: [1, 0]),
                .init(row: 10, indexPath: [3, 2])
            ),
            .move(
                .init(row: 4, indexPath: [1, 1]),
                .init(row: 9, indexPath: [3, 1])
            ),
            .move(
                .init(row: 5, indexPath: [1, 2]),
                .init(row: 8, indexPath: [3, 0])
            ),
        ])
        let moved = diff.movedRows
        XCTAssertEqual(moved.count, 3)
        XCTAssertTrue(moved[0] == (5, 10))
        XCTAssertTrue(moved[1] == (4, 10))
        XCTAssertTrue(moved[2] == (3, 10))
    }

    func testMoveLeapfrogsAnotherMove() {
        let diff = Table<Int, AuthorInfo>.Diff([
            .move(
                .init(row: 3, indexPath: [1, 0]),
                .init(row: 8, indexPath: [3, 0])
            ),
            .move(
                .init(row: 4, indexPath: [1, 1]),
                .init(row: 5, indexPath: [1, 2])
            ),
        ])
        let moved = diff.movedRows
        XCTAssertEqual(moved.count, 2)
        XCTAssertTrue(moved[0] == (4, 6))
        XCTAssertTrue(moved[1] == (3, 8))
    }
}

class TableDiffUpdatedRowsTests: XCTestCase {
    func testGrouped() {
        let diff = Table<Int, AuthorInfo>.Diff([
            .update(.init(row: 0, indexPath: IndexPath(index: 0))),
            .update(.init(row: 2, indexPath: [1, 0])),
        ])
        XCTAssertEqual(diff.updatedRows.map { $0 }, [0, 2])
    }

    func testUngrouped() {
        let diff = Table<None, AuthorInfo>.Diff([
            .update(.init(row: nil, indexPath: IndexPath(index: 0))),
            .update(.init(row: 2, indexPath: [1, 0])),
        ])
        XCTAssertEqual(diff.updatedRows.map { $0 }, [2])
    }
}

class TableDiffInsertedGroupsTests: XCTestCase {
    func test() {
        let diff = Table<Int, AuthorInfo>.Diff([
            .insert(.init(row: 0, indexPath: IndexPath(index: 0))),
            .insert(.init(row: 2, indexPath: [1, 0])),
        ])
        XCTAssertEqual(diff.insertedGroups.map { $0 }, [0])
    }
}

class TableDiffDeletedGroupsTests: XCTestCase {
    func test() {
        let diff = Table<Int, AuthorInfo>.Diff([
            .delete(.init(row: 0, indexPath: IndexPath(index: 0))),
            .delete(.init(row: 2, indexPath: [1, 0])),
        ])
        XCTAssertEqual(diff.deletedGroups.map { $0 }, [0])
    }
}

class TableDiffMovedGroupsTests: XCTestCase {
    func test() {
        let diff = Table<Int, AuthorInfo>.Diff([
            .move(
                .init(row: 2, indexPath: IndexPath(index: 1)),
                .init(row: 4, indexPath: IndexPath(index: 2))
            ),
            .move(
                .init(row: 4, indexPath: [1, 1]),
                .init(row: 5, indexPath: [2, 0])
            ),
        ])
        let moved = diff.movedGroups
        XCTAssertEqual(moved.count, 1)
        XCTAssertTrue(moved[0] == (1, 2))
    }
}

class TableDiffInsertedValuesTests: XCTestCase {
    func test() {
        let diff = Table<Int, AuthorInfo>.Diff([
            .insert(.init(row: 0, indexPath: IndexPath(index: 0))),
            .insert(.init(row: 2, indexPath: [1, 0])),
        ])
        XCTAssertEqual(diff.insertedValues, [[1, 0]])
    }
}

class TableDiffDeletedValuesTests: XCTestCase {
    func test() {
        let diff = Table<Int, AuthorInfo>.Diff([
            .delete(.init(row: 0, indexPath: IndexPath(index: 0))),
            .delete(.init(row: 2, indexPath: [1, 0])),
        ])
        XCTAssertEqual(diff.deletedValues, [[1, 0]])
    }
}

class TableDiffUpdatedValuesTests: XCTestCase {
    func test() {
        let diff = Table<Int, AuthorInfo>.Diff([
            .update(.init(row: 0, indexPath: IndexPath(index: 0))),
            .update(.init(row: 2, indexPath: [1, 0])),
        ])
        XCTAssertEqual(diff.updatedValues, [[1, 0]])
    }
}

class TableDiffMovedValuesTests: XCTestCase {
    func test() {
        let diff = Table<Int, AuthorInfo>.Diff([
            .move(
                .init(row: 2, indexPath: IndexPath(index: 1)),
                .init(row: 4, indexPath: IndexPath(index: 2))
            ),
            .move(
                .init(row: 4, indexPath: [1, 1]),
                .init(row: 5, indexPath: [2, 0])
            ),
        ])
        let moved = diff.movedValues
        XCTAssertEqual(moved.count, 1)
        XCTAssertTrue(moved[0] == ([1, 1], [2, 0]))
    }
}
