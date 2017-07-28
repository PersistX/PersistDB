@testable import PersistTest
import Schemata
import XCTest

class TestStoreValueTests: XCTestCase {
    func testInitWithKeyPathValueSavesInfo() {
        let value = TestStore.Value(keyPath: \Book.title, value: "Ubik")
        XCTAssertEqual(value.keyPath, \Book.title)
        XCTAssertEqual(value.value, Primitive.string("Ubik"))
    }
    
    func testEqualsCreatesValue() {
        let value: TestStore.Value = \Book.title == "Ubik"
        XCTAssertEqual(value.keyPath, \Book.title)
        XCTAssertEqual(value.value, .string("Ubik"))
    }
}

