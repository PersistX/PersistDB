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

class ExpressionUUIDTests: ExpressionTests {
    func testUUID() {
        let uuid = Expression<Book, UUID>.uuid()
        let query = SQL.Query
            .select([
                .init(uuid.sql, alias: "1"),
                .init(uuid.sql, alias: "2"),
            ])
        
        let result = db.query(query)[0]
        
        let uuid1 = result.dictionary["1"]
        let uuid2 = result.dictionary["2"]
        if case let .text(string1)? = uuid1,
            case let .text(string2)? = uuid2,
            let uuid1 = UUID(uuidString: string1),
            let uuid2 = UUID(uuidString: string2)
        {
            XCTAssertNotEqual(uuid1, uuid2)
        } else {
            XCTFail("Wrong result: " + String(describing: result))
        }
    }
}
