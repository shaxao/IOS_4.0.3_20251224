import XCTest
@testable import RestaurantIngredientManager

final class DurationCalculatorTests: XCTestCase {
    func testUnitConversion() {
        XCTAssertEqual(DurationCalculator.totalMinutes(for: DurationValue(amount: 30, unit: .minute)), 30)
        XCTAssertEqual(DurationCalculator.totalMinutes(for: DurationValue(amount: 2, unit: .hour)), 120)
        XCTAssertEqual(DurationCalculator.totalMinutes(for: DurationValue(amount: 3, unit: .day)), 4320)
        XCTAssertEqual(DurationCalculator.totalMinutes(for: DurationValue(amount: 1, unit: .month)), 43200)
        XCTAssertEqual(DurationCalculator.totalMinutes(for: DurationValue(amount: 1, unit: .year)), 525600)
        XCTAssertEqual(DurationCalculator.totalMinutes(for: DurationValue(amount: 0, unit: .custom, customMinutes: 95)), 95)
    }

    func testBoundaryValues() {
        XCTAssertEqual(DurationCalculator.totalMinutes(for: DurationValue(amount: -1, unit: .hour)), 0)
        XCTAssertEqual(DurationCalculator.totalMinutes(for: DurationValue(amount: 0, unit: .minute)), 0)
        XCTAssertEqual(DurationCalculator.formatAsChineseDuration(DurationValue(amount: 0, unit: .minute)), "0年0月0日0时0分")
    }

    func testDaylightSavingTransition() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let start = formatter.date(from: "2026-03-08 01:30")!
        let result = DurationCalculator.add(DurationValue(amount: 1, unit: .hour), to: start, calendar: calendar)
        let output = formatter.string(from: result)
        XCTAssertEqual(output, "2026-03-08 03:30")
    }
}
