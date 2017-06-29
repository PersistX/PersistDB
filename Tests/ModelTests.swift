@testable import PersistDB
import XCTest

class AnyPropertyTests: XCTestCase {
    func testSQLForToMany() {
        let property = Author.anySchema.properties[\Author.books]!
        XCTAssertNil(property.sql)
    }
    
    func testSQLForToOne() {
        let property = Book.anySchema.properties[\Book.author]!
        let expected = SQL.Schema.Column(name: "author", type: .integer)
        XCTAssertEqual(property.sql, expected)
    }
    
    func testSQLForString() {
        let property = Book.anySchema.properties[\Book.title]!
        let expected = SQL.Schema.Column(name: "title", type: .text)
        XCTAssertEqual(property.sql, expected)
    }
    
    func testSQLForInt() {
        let property = Author.anySchema.properties[\Author.born]!
        let expected = SQL.Schema.Column(name: "born", type: .integer)
        XCTAssertEqual(property.sql, expected)
    }
    
    func testSQLForOptionalInt() {
        let property = Author.anySchema.properties[\Author.died]!
        let expected = SQL.Schema.Column(name: "died", type: .integer, nullable: true)
        XCTAssertEqual(property.sql, expected)
    }
}

class ModelTests: XCTestCase {
    func testSQLForBook() {
        let expected = SQL.Schema(
            table: SQL.Table("Book"),
            columns: [
                .init(name: "id", type: .integer),
                .init(name: "title", type: .text),
                .init(name: "author", type: .integer),
            ]
        )
        XCTAssertEqual(Book.sql, expected)
    }
}
