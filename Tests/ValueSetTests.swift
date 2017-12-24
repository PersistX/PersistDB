@testable import PersistDB
import XCTest

class ValueSetSufficientForInsertTests: XCTestCase {
    func testEveryPropertySet() {
        let assignments: [Assignment<Author>] = [
            \.id == Author.ID(1),
            \.name == "Some Gal",
            \.givenName == "Someantha Gal",
            \.born == 1930,
            \.died == nil,
        ]
        XCTAssertTrue(ValueSet(assignments).sufficientForInsert)
    }
    
    func testWithoutOptionalProperties() {
        let assignments: [Assignment<Author>] = [
            \.id == Author.ID(1),
            \.name == "Some Gal",
            \.givenName == "Someantha Gal",
            \.born == 1930,
        ]
        XCTAssertTrue(ValueSet(assignments).sufficientForInsert)
    }
    
    func testMissingProperties() {
        let valueSet: ValueSet<Author> = [
            \.id == Author.ID(1),
            \.born == 1930,
        ]
        XCTAssertFalse(valueSet.sufficientForInsert)
    }
}
