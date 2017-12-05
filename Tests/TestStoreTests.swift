import PersistDB
import XCTest

class TestStoreTests: XCTestCase {
    func testQuery() {
        let theHobbit = Book.ISBN("the-hobbit")
        let query = Book.all.filter(\Book.title == Book.theHobbit.title)
        let store = TestStore(
            [
                .theHobbit: [
                    \Book.title == Book.theHobbit.title,
                ],
                theHobbit: [
                    \Book.title == Book.theHobbit.title,
                ],
                .theLordOfTheRings: [
                    \Book.title == Book.theLordOfTheRings.title,
                ]
            ]
        )
        XCTAssertEqual(store.fetch(query), [.theHobbit, theHobbit])
    }
}
