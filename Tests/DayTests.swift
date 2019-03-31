@testable import PersistDB
import XCTest

extension TimeZone {
    fileprivate static let utc = TimeZone(abbreviation: "UTC")!
    fileprivate static let detroit = TimeZone(identifier: "America/Detroit")!
    fileprivate static let melbourne = TimeZone(identifier: "Australia/Melbourne")!
}

class DayInitWithDateTimeZoneTests: XCTestCase {
    func testReferenceDateStart() {
        let day = Day(
            Date(timeIntervalSinceReferenceDate: 0),
            timeZone: .utc
        )
        XCTAssertEqual(day.daysSinceReferenceDate, 0)
    }

    func testReferenceDateEnd() {
        let day = Day(
            Date(timeIntervalSinceReferenceDate: 60 * 60 * 24 - 1),
            timeZone: .utc
        )
        XCTAssertEqual(day.daysSinceReferenceDate, 0)
    }

    func testDayAfterReferenceDateStart() {
        let day = Day(
            Date(timeIntervalSinceReferenceDate: 60 * 60 * 24),
            timeZone: .utc
        )
        XCTAssertEqual(day.daysSinceReferenceDate, 1)
    }

    func testDayAfterReferenceDateEnd() {
        let day = Day(
            Date(timeIntervalSinceReferenceDate: 60 * 60 * 24 * 2 - 1),
            timeZone: .utc
        )
        XCTAssertEqual(day.daysSinceReferenceDate, 1)
    }

    func testModernDayStartAmericaDetroit() {
        let day = Day(
            Date(timeIntervalSinceReferenceDate: 521_956_800),
            timeZone: .detroit
        )
        XCTAssertEqual(day.daysSinceReferenceDate, 6041)
    }

    func testModernDayEndAmericaDetroit() {
        let day = Day(
            Date(timeIntervalSinceReferenceDate: 521_996_729),
            timeZone: .detroit
        )
        XCTAssertEqual(day.daysSinceReferenceDate, 6041)
    }

    func testModernDayStartAustraliaMelbourne() {
        let day = Day(
            Date(timeIntervalSinceReferenceDate: 521_906_400),
            timeZone: .melbourne
        )
        XCTAssertEqual(day.daysSinceReferenceDate, 6041)
    }

    func testModernDayEndAustraliaMelbourne() {
        let day = Day(
            Date(timeIntervalSinceReferenceDate: 521_992_799),
            timeZone: .melbourne
        )
        XCTAssertEqual(day.daysSinceReferenceDate, 6041)
    }
}

class DayComparableTests: XCTestCase {
    func testLessThan() {
        let a = Day(daysSinceReferenceDate: 99)
        let b = Day(daysSinceReferenceDate: 100)
        XCTAssertLessThan(a, b)
    }

    func testGreaterThan() {
        let a = Day(daysSinceReferenceDate: 100)
        let b = Day(daysSinceReferenceDate: 99)
        XCTAssertGreaterThan(a, b)
    }
}

class DayStartTests: XCTestCase {
    func testReferenceDateStart() {
        let start = Date(timeIntervalSinceReferenceDate: 0)
        let day = Day(start, timeZone: .utc)
        XCTAssertEqual(day.start(in: .utc), start)
    }

    func testDayAfterReferenceDateStart() {
        let start = Date(timeIntervalSinceReferenceDate: 60 * 60 * 24)
        let day = Day(start, timeZone: .utc)
        XCTAssertEqual(day.start(in: .utc), start)
    }

    func testModernDayStartAmericaDetroit() {
        let start = Date(timeIntervalSinceReferenceDate: 521_956_800)
        let day = Day(start, timeZone: .detroit)
        XCTAssertEqual(day.start(in: .detroit), start)
    }

    func testModernDayStartAustraliaMelbourne() {
        let start = Date(timeIntervalSinceReferenceDate: 521_906_400)
        let day = Day(start, timeZone: .melbourne)
        XCTAssertEqual(day.start(in: .melbourne), start)
    }
}

class DayValueTests: XCTestCase {
    func testDecode() throws {
        let day = Day(
            Date(timeIntervalSinceReferenceDate: 60 * 60 * 24),
            timeZone: .utc
        )
        XCTAssertEqual(try Day.value.decode(1).get(), day)
    }

    func testEncode() {
        let day = Day(
            Date(timeIntervalSinceReferenceDate: 60 * 60 * 24),
            timeZone: .utc
        )
        XCTAssertEqual(Day.value.encode(day), 1)
    }
}
