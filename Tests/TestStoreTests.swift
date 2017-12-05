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
    
    func testQueryWithImplicitlyNilColumn() {
        let query = Author.all.filter(\Author.died == nil)
        let store = TestStore(
            [ .jrrTolkien: [ \Author.name == Author.jrrTolkien.name ]]
        )
        XCTAssertEqual(store.fetch(query), [.jrrTolkien])
    }
}
