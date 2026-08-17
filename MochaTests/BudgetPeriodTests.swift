import XCTest
@testable import Mocha

final class BudgetPeriodTests: XCTestCase {
    func testMonthlyIntervalStartsAtFirstDayAndEndsAtNextMonth() throws {
        let calendar = makeCalendar()
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 12, hour: 15)))

        let interval = BudgetPeriod.monthly.interval(containing: date, calendar: calendar)

        XCTAssertEqual(interval.start, try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))))
        XCTAssertEqual(interval.end, try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 9, day: 1))))
    }

    func testYearlyIntervalStartsAtJanuaryFirstAndEndsAtNextYear() throws {
        let calendar = makeCalendar()
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 12, hour: 15)))

        let interval = BudgetPeriod.yearly.interval(containing: date, calendar: calendar)

        XCTAssertEqual(interval.start, try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))))
        XCTAssertEqual(interval.end, try XCTUnwrap(calendar.date(from: DateComponents(year: 2027, month: 1, day: 1))))
    }

    private func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 8 * 60 * 60)!
        return calendar
    }
}
