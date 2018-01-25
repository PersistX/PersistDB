import PersistDB
@testable import Todo
import XCTest

private let a = UUID()
private let b = UUID()

private let earliest = Date(timeIntervalSinceReferenceDate: -1000)
private let earlier = Date(timeIntervalSinceReferenceDate: -10)
private let later = Date(timeIntervalSinceReferenceDate: 10)
private let latest = Date(timeIntervalSinceReferenceDate: 1000)

private func AssertMatch(
    _ query: Query<Task>,
    _ valueSet: ValueSet<Task>,
    file: StaticString = #file,
    line: UInt = #line
) {
    let uuid = UUID()
    let store = TestStore([ uuid: valueSet ])
    let results = store.fetch(query)
    XCTAssertEqual(results, [uuid], file: file, line: line)
}

private func AssertNoMatch(
    _ query: Query<Task>,
    _ valueSet: ValueSet<Task>,
    file: StaticString = #file,
    line: UInt = #line
) {
    let store = TestStore([ UUID(): valueSet ])
    let results = store.fetch(query)
    XCTAssertEqual(results, [], file: file, line: line)
}

class TaskSortOrderTests: XCTestCase {
    func testIncompleteBeforeComplete() {
        let store = TestStore([
            a: [\Task.createdAt == earlier, \Task.completedAt == nil ],
            b: [\Task.createdAt == earliest, \Task.completedAt == later ],
        ])

        XCTAssertEqual(store.fetch(Task.all), [a, b])
    }

    func testIncompleteByCreatedAt() {
        let store = TestStore([
            a: [\Task.createdAt == later ],
            b: [\Task.createdAt == earlier ],
        ])

        XCTAssertEqual(store.fetch(Task.all), [b, a])
    }

    func testCompleteByCompletedAt() {
        let store = TestStore([
            a: [\Task.createdAt == earliest, \Task.completedAt == latest ],
            b: [\Task.createdAt == earlier, \Task.completedAt == later ],
        ])

        XCTAssertEqual(store.fetch(Task.all), [b, a])
    }
}

class TaskActiveQueryTests: XCTestCase {
    func testMatchesIncomplete() {
        AssertMatch(Task.active, [\.completedAt == nil ])
    }

    func testDoesNotMatchComplete() {
        AssertNoMatch(Task.active, [\.completedAt == Date() ])
    }

    func testSortedByCreatedAt() {
        let store = TestStore([
            a: [\Task.createdAt == later ],
            b: [\Task.createdAt == earlier ],
        ])

        XCTAssertEqual(store.fetch(Task.active), [b, a])
    }
}

class TodayCompletedQueryTests: XCTestCase {
    func testDoesNotMatchIncomplete() {
        AssertNoMatch(Task.completed, [\.completedAt == nil ])
    }

    func testMatchesComplete() {
        AssertMatch(Task.completed, [\.completedAt == Date() ])
    }

    func testSortedByCompletedAt() {
        let store = TestStore([
            a: [\Task.createdAt == earliest, \Task.completedAt == latest ],
            b: [\Task.createdAt == earlier, \Task.completedAt == later ],
        ])

        XCTAssertEqual(store.fetch(Task.completed), [b, a])
    }
}

class TaskNewTaskTests: XCTestCase {
    private let newTask = Task.newTask(text: "Ship!!!")

    func testIsActive() {
        AssertMatch(Task.active, newTask.valueSet)
    }

    func testSetsCreatedAt() {
        let store = TestStore(for: [Task.self])

        let before = Date()
        let task: Task = store.insert(newTask)
        let after = Date()

        XCTAssertGreaterThan(task.createdAt, before)
        XCTAssertLessThan(task.createdAt, after)
    }

    func testSetsText() {
        let store = TestStore(for: [Task.self])
        let task: Task = store.insert(newTask)
        XCTAssertEqual(task.text, "Ship!!!")
    }
}

class TaskCompleteValueSetTests: XCTestCase {
    func testCancelsOutIncomplete() {
        XCTAssertEqual(Task.incomplete.update(with: Task.complete), Task.complete)
    }

    func testMatchesCompleted() {
        AssertMatch(Task.completed, Task.complete)
    }
}

class TaskIncompleteValueSetTests: XCTestCase {
    func testCancelsOutComplete() {
        XCTAssertEqual(Task.complete.update(with: Task.incomplete), Task.incomplete)
    }

    func testMatchesActive() {
        AssertMatch(Task.active, Task.incomplete)
    }
}
