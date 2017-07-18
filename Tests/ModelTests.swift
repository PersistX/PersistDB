@testable import PersistDB
import XCTest

class AnyPropertyTests: XCTestCase {
    func testSQLForPrimaryKey() {
        let property = Book.anySchema.properties[\Book.id]!
        let expected = SQL.Schema.Column(name: "id", type: .text, primaryKey: true)
        XCTAssertEqual(property.sql, expected)
    }
    
    func testSQLForToMany() {
        let property = Author.anySchema.properties[\Author.books]!
        XCTAssertNil(property.sql)
    }
    
    func testSQLForToOneWithIntID() {
        let property = Book.anySchema.properties[\Book.author]!
        let expected = SQL.Schema.Column(name: "author", type: .integer)
        XCTAssertEqual(property.sql, expected)
    }
    
    func testSQLForDate() {
        let property = Widget.anySchema.properties[\Widget.date]!
        let expected = SQL.Schema.Column(name: "date", type: .real)
        XCTAssertEqual(property.sql, expected)
    }
    
    func testSQLForFloat() {
        let property = Widget.anySchema.properties[\Widget.float]!
        let expected = SQL.Schema.Column(name: "float", type: .real)
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
                .init(name: "id", type: .text, primaryKey: true),
                .init(name: "title", type: .text),
                .init(name: "author", type: .integer),
            ]
        )
        XCTAssertEqual(Book.sql, expected)
    }
}
