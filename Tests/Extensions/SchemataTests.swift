@testable import PersistDB
import Schemata
import XCTest

class PrimitiveSQLTests: XCTestCase {
    func testDate() {
        let interval: Double = 100_000
        let date = Date(timeIntervalSinceReferenceDate: interval)
        XCTAssertEqual(Primitive.date(date).sql, .real(interval))
    }

    func testDouble() {
        XCTAssertEqual(Primitive.double(123.456789).sql, .real(123.456789))
    }

    func testInt() {
        XCTAssertEqual(Primitive.int(123_456_789).sql, .integer(123_456_789))
    }

    func testNull() {
        XCTAssertEqual(Primitive.null.sql, .null)
    }

    func testString() {
        XCTAssertEqual(Primitive.string("mdiep").sql, .text("mdiep"))
    }
}
