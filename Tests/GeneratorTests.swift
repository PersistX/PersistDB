@testable import PersistDB
import XCTest

class AnyGeneratorMakeSQLTests: XCTestCase {
    func testUUID() {
        let generator = AnyGenerator.uuid

        let sql1 = generator.makeSQL()
        let sql2 = generator.makeSQL()
        XCTAssertNotEqual(sql1, sql2)

        if case let .text(string) = sql1 {
            XCTAssertNotNil(UUID(uuidString: string))
        } else {
            XCTFail()
        }

        if case let .text(string) = sql2 {
            XCTAssertNotNil(UUID(uuidString: string))
        } else {
            XCTFail()
        }
    }
}

class GeneratorInitTests: XCTestCase {
    func testUUID() {
        let generator = Generator<UUID>.uuid()
        XCTAssertEqual(generator.generator, .uuid)
    }
}
