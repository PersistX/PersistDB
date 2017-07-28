@testable import PersistTest
import Schemata
import XCTest

class TestDBValueTests: XCTestCase {
    func testInitWithKeyPathValueSavesInfo() {
        let value = PersistTest.TestDB.Value(keyPath: \Book.title, value: "Ubik")
        XCTAssertEqual(value.keyPath, \Book.title)
        XCTAssertEqual(value.value, Primitive.string("Ubik"))
    }
    
    func testEqualsCreatesValue() {
        let value: PersistTest.TestDB.Value = \Book.title == "Ubik"
        XCTAssertEqual(value.keyPath, \Book.title)
        XCTAssertEqual(value.value, .string("Ubik"))
    }
}

