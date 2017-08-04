import PersistDB
import XCTest

class DateTests: XCTestCase {
    func testTodayReturns2014_06_02_1200_00() {
        XCTAssertEqual(
            Date.today(),
            Date(timeIntervalSinceReferenceDate: 423_403_200)
        )
    }
    
    func testTodayReturns2014_06_02_0102_03() {
        XCTAssertEqual(
            Date.today(h: 1, m: 2, s: 3),
            Date(timeIntervalSinceReferenceDate: 423_363_723)
        )
    }
    
    func testYesterdayReturns2014_06_01_1200_00() {
        XCTAssertEqual(
            Date.yesterday(),
            Date(timeIntervalSinceReferenceDate: 423_316_800)
        )
    }
    
    func testYesterdayReturns2014_06_01_0102_03() {
        XCTAssertEqual(
            Date.yesterday(h: 1, m: 2, s: 3),
            Date(timeIntervalSinceReferenceDate: 423_277_323)
        )
    }
    
    func testTomorrowReturns2014_06_03_1200_00() {
        XCTAssertEqual(
            Date.tomorrow(),
            Date(timeIntervalSinceReferenceDate: 423_489_600)
        )
    }
    
    func testTomorrowReturns2014_06_03_0102_03() {
        XCTAssertEqual(
            Date.tomorrow(h: 1, m: 2, s: 3),
            Date(timeIntervalSinceReferenceDate: 423_450_123)
        )
    }
}
