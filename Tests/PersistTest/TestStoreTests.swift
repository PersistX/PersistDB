@testable import PersistTest
import XCTest

private func ==(
    lhs: [TestStore.ID: [TestStore.AnyValue]],
    rhs: [TestStore.ID: [TestStore.AnyValue]]
) -> Bool {
    guard lhs.count == rhs.count else { return false }
    
    for (id, values) in lhs {
        guard
            let rhsValues = rhs[id],
            rhsValues == values
        else { return false }
    }
    
    return true
}

class TestStoreTests: XCTestCase {
    func testInit() {
        let store = TestStore(
            .theHobbit -- \Book.title == "The Hobbit",
            .theLordOfTheRings -- \Book.title == "The Lord of the Rings",
            .jrrTolkien -- \Author.name == "J.R.R. Tolkien"
        )
        
        let theHobbit = TestStore.ID(
            type: Book.self,
            id: .string(Book.ID.theHobbit.string)
        )
        let theLordOfTheRings = TestStore.ID(
            type: Book.self,
            id: .string(Book.ID.theLordOfTheRings.string)
        )
        let jrrTolkien = TestStore.ID(
            type: Author.self,
            id: .int(Author.ID.jrrTolkien.int)
        )
        let expected: [TestStore.ID: [TestStore.AnyValue]] = [
            theHobbit: [
                TestStore.AnyValue(\Book.title == "The Hobbit")
            ],
            theLordOfTheRings: [
                TestStore.AnyValue(\Book.title == "The Lord of the Rings")
            ],
            jrrTolkien: [
                TestStore.AnyValue(\Author.name == "J.R.R. Tolkien")
            ],
        ]
        
        XCTAssert(store.data == expected)
    }
}
