@testable import PersistTest
import XCTest

class TestStoreRowTests: XCTestCase {
    func testInitWithArrayOfValues() {
        let id = Author.ID(1)
        let row = id -- [
            \Author.name == "Ray Bradbury",
            \Author.born == 1920,
            \Author.died == 2012,
        ]
        
        let expected = TestStore.Row(
            type: Author.self,
            id: .int(1),
            values: [
                TestStore.AnyValue(keyPath: \Author.name, value: .string("Ray Bradbury")),
                TestStore.AnyValue(keyPath: \Author.born, value: .int(1920)),
                TestStore.AnyValue(keyPath: \Author.died, value: .int(2012)),
            ]
        )
        
        XCTAssertEqual(row, expected)
    }
    
    func testInitWithSingleValue() {
        let id = Author.ID(1)
        let row = id -- \Author.name == "Ray Bradbury"
        
        let expected = TestStore.Row(
            type: Author.self,
            id: .int(1),
            values: [
                TestStore.AnyValue(keyPath: \Author.name, value: .string("Ray Bradbury")),
            ]
        )
        
        XCTAssertEqual(row, expected)
        
    }
    
    func testInitWithClass() {
        let id = Author.ID(1)
        let row = id -- Author.self
        
        let expected = TestStore.Row(
            type: Author.self,
            id: .int(1),
            values: [ ]
        )
        
        XCTAssertEqual(row, expected)
    }
}
