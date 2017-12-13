@testable import PersistDB
import XCTest

class ValueSetSufficientForInsertTests: XCTestCase {
    func testEveryPropertySet() {
        let valueSet: ValueSet<Author> = [
            \Author.id == Author.ID(1),
            \Author.name == "Some Gal",
            \Author.born == 1930,
            \Author.died == nil,
        ]
        XCTAssertTrue(valueSet.sufficientForInsert)
    }
    
    func testWithoutOptionalProperties() {
        let valueSet: ValueSet<Author> = [
            \.id == Author.ID(1),
            \.name == "Some Gal",
            \.born == 1930,
        ]
        XCTAssertTrue(valueSet.sufficientForInsert)
    }
    
    func testMissingProperties() {
        let valueSet: ValueSet<Author> = [
            \.id == Author.ID(1),
            \.born == 1930,
        ]
        XCTAssertFalse(valueSet.sufficientForInsert)
    }
}
