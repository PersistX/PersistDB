@testable import PersistDB
import XCTest

class ExpressionTests: XCTestCase {
    var db: TestDB!
    
    override func setUp() {
        super.setUp()
        db = TestDB()
    }
    
    override func tearDown() {
        super.tearDown()
        db = nil
    }
}

class ExpressionInitTests: ExpressionTests {
    func test_initWithValue() {
        let expression = Expression<Book, String>("foo")
        let sql = SQL.Expression.value(.text("foo"))
        XCTAssertEqual(expression.sql, sql)
    }
    
    func test_initWithOptionalValue_some() {
        let expression = Expression<Book, String?>("foo")
        let sql = SQL.Expression.value(.text("foo"))
        XCTAssertEqual(expression.sql, sql)
    }
    
    func test_initWithOptionalValue_none() {
        let expression = Expression<Book, String?>(nil)
        let sql = SQL.Expression.value(.null)
        XCTAssertEqual(expression.sql, sql)
    }
}

class ExpressionDateTests: ExpressionTests {
    func testNow() {
        let query = SQL.Query
            .select([ .init(Expression<Book, Date>.now.sql, alias: "now") ])
        
        let before = Date()
        let result = db.query(query)[0]
        let after = Date()
            
        let primitive = result.dictionary["now"]?.primitive(.date)
        if case let .date(date)? = primitive {
            XCTAssertGreaterThan(date, before)
            XCTAssertLessThan(date, after)
        } else {
            XCTFail("Wrong primitive: " + String(describing: primitive))
        }
    }
}
