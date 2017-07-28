@testable import PersistTest
import Schemata
import XCTest

class TestStoreValueTests: XCTestCase {
    func testEqualsCreatesValue() {
        let value: TestStore.Value = \Book.title == "Ubik"
        XCTAssertEqual(value.keyPath, \Book.title)
        XCTAssertEqual(value.value, .string("Ubik"))
    }
}

