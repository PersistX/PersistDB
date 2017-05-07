import PersistDB
import Schemata
import XCTest

extension Author.ID: RecordValue {
    static let record = String.record.bimap(
        decode: Author.ID.init,
        encode: { $0.string }
    )
}

extension Author: RecordObject {
    static let record = Schema<Author, Record>(
        Author.init,
        Author.id ~ "id",
        Author.name ~ "name"
    )
}

class RecordTests: XCTestCase {
    func testStringDecodeFailure() {
        //        XCTAssertEqual(String.record.decode(.null).error, [.typeMismatch(String.self, .null)])
    }
    
    func testStringDecodeSuccess() {
        let result = String.record.decode(.string("foo"))
        XCTAssertEqual(result.value, "foo")
        XCTAssertNil(result.error)
    }
    
    func testStringEncode() {
        XCTAssertEqual(String.record.encode("foo"), .string("foo"))
    }
    
    func testAuthorIDDecodeFailure() {
        //        XCTAssertEqual(Author.ID.record.decode(.null).error, [.typeMismatch(Author.ID.self, .null)])
    }
    
    func testAuthorIDDecodeSuccess() {
        let result = Author.ID.record.decode(.string("foo"))
        XCTAssertEqual(result.value, Author.ID("foo"))
        XCTAssertNil(result.error)
    }
    
    func testAuthorIDEncode() {
        XCTAssertEqual(Author.ID.record.encode(Author.ID("foo")), .string("foo"))
    }
    
    func testAuthorDecodeFailure() {
        
    }
    
    func testAuthorDecodeSuccess() {
        let id = Author.ID("1")
        let name = "Ray Bradbury"
        let author = Author(id: id, name: name)
        let record = Record([
            "id": .string(id.string),
            "name": .string(name),
            ])
        XCTAssertEqual(Author.record.decode(record).value, author)
    }
    
    func testAuthorEncode() {
        let id = Author.ID("1")
        let name = "Ray Bradbury"
        let author = Author(id: id, name: name)
        let record = Record([
            "id": .string(id.string),
            "name": .string(name),
            ])
        XCTAssertEqual(Author.record.encode(author), record)
    }
}
