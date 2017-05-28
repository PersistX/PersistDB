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
}
