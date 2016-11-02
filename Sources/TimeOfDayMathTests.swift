import XCTest
@testable import Catch


private extension Date {
  static func timeOfDay(hour: Int, minute: Int) -> Date {
    return DateComponents(calendar: .current, hour: hour, minute: minute).date!
  }
}


class TimeOfDayMathTests: XCTestCase {
  func testNonWrappingIntervals() {
    let time0415 = Date.timeOfDay(hour: 4, minute: 15)
    let time0400 = Date.timeOfDay(hour: 4, minute: 0)
    let time0500 = Date.timeOfDay(hour: 5, minute: 0)
    XCTAssertTrue(time0415.isTimeOfDayBetween(startTimeOfDay: time0400, endTimeOfDay: time0500))
    XCTAssertFalse(time0400.isTimeOfDayBetween(startTimeOfDay: time0415, endTimeOfDay: time0500))
    XCTAssertFalse(time0500.isTimeOfDayBetween(startTimeOfDay: time0400, endTimeOfDay: time0415))
  }
  
  func testWrappingIntervals() {
    let time0715 = Date.timeOfDay(hour: 7, minute: 15)
    let time0245 = Date.timeOfDay(hour: 2, minute: 45)
    let time0700 = Date.timeOfDay(hour: 7, minute: 0)
    let time0300 = Date.timeOfDay(hour: 3, minute: 0)
    XCTAssertTrue(time0715.isTimeOfDayBetween(startTimeOfDay: time0700, endTimeOfDay: time0300))
    XCTAssertTrue(time0245.isTimeOfDayBetween(startTimeOfDay: time0700, endTimeOfDay: time0300))
    XCTAssertFalse(time0700.isTimeOfDayBetween(startTimeOfDay: time0715, endTimeOfDay: time0300))
    XCTAssertFalse(time0300.isTimeOfDayBetween(startTimeOfDay: time0700, endTimeOfDay: time0245))
  }
  
  func testExactTimes() {
    // Upper bound is considered "outside" of range
    let time0400 = Date.timeOfDay(hour: 4, minute: 0)
    let time0500 = Date.timeOfDay(hour: 5, minute: 0)
    XCTAssertTrue(time0400.isTimeOfDayBetween(startTimeOfDay: time0400, endTimeOfDay: time0500))
    XCTAssertFalse(time0500.isTimeOfDayBetween(startTimeOfDay: time0400, endTimeOfDay: time0500))
    
    let time0900 = Date.timeOfDay(hour: 9, minute: 0)
    let time0100 = Date.timeOfDay(hour: 1, minute: 0)
    XCTAssertTrue(time0900.isTimeOfDayBetween(startTimeOfDay: time0900, endTimeOfDay: time0100))
    XCTAssertFalse(time0100.isTimeOfDayBetween(startTimeOfDay: time0900, endTimeOfDay: time0100))
  }
}
