@testable import PersistDB
import Schemata
import XCTest

class PrimitiveTests: XCTestCase {
    func test_sql_date() {
        let interval: Double = 100_000
        let date = Date(timeIntervalSinceReferenceDate: interval)
        XCTAssertEqual(Primitive.date(date).sql, .real(interval))
    }
    
    func test_sql_double() {
        XCTAssertEqual(Primitive.double(123.456789).sql, .real(123.456789))
    }
    
    func test_sql_int() {
        XCTAssertEqual(Primitive.int(123456789).sql, .integer(123456789))
    }
    
    func test_sql_null() {
        XCTAssertEqual(Primitive.null.sql, .null)
    }
    
    func test_sql_string() {
        XCTAssertEqual(Primitive.string("mdiep").sql, .text("mdiep"))
    }
}
