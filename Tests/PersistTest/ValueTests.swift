@testable import PersistTest
import Schemata
import XCTest

class TestStoreAnyValueTests: XCTestCase {
    func testInit() {
        let value = TestStore.AnyValue(\Book.title == "Ubik")
        XCTAssertEqual(value.keyPath, \Book.title)
        XCTAssertEqual(value.value, .string("Ubik"))
    }
}

class TestStoreValueTests: XCTestCase {
    func testEqualsCreatesValue() {
        let value: TestStore.Value = \Book.title == "Ubik"
        XCTAssertEqual(value.keyPath, \Book.title)
        XCTAssertEqual(value.value, .string("Ubik"))
    }
    
    func testEqualsOptionalCreatesValue() {
        let value: TestStore.Value = \Author.died == nil
        XCTAssertEqual(value.keyPath, \Author.died)
        XCTAssertEqual(value.value, .null)
    }
}

