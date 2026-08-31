import XCTest
@testable import Mocha

final class BudgetProgressTests: XCTestCase {
    func testProgressAggregatesEntriesInCurrentPeriod() throws {
        let calendar = makeCalendar()
        let budget = Budget(name: "餐饮", amount: 1_000, period: .monthly)
        let currentDate = try date(2026, 8, 12, calendar: calendar)
        let entries = [
            BudgetEntry(budget: budget, amount: 100, spentAt: try date(2026, 8, 1, calendar: calendar)),
            BudgetEntry(budget: budget, amount: 250, spentAt: try date(2026, 8, 12, calendar: calendar)),
            BudgetEntry(budget: budget, amount: 999, spentAt: try date(2026, 7, 31, calendar: calendar))
        ]

        let progress = BudgetProgressCalculator.progress(
            for: budget,
            entries: entries,
            referenceDate: currentDate,
            calendar: calendar
        )

        XCTAssertEqual(progress.spent, 350)
        XCTAssertEqual(progress.remaining, 650)
        XCTAssertFalse(progress.isOverspent)
    }

    func testProgressTreatsIntervalEndAsExclusive() throws {
        let calendar = makeCalendar()
        let budget = Budget(name: "餐饮", amount: 1_000, period: .monthly)
        let currentDate = try date(2026, 8, 12, calendar: calendar)
        let entries = [
            BudgetEntry(budget: budget, amount: 100, spentAt: try date(2026, 8, 31, calendar: calendar)),
            BudgetEntry(budget: budget, amount: 200, spentAt: try date(2026, 9, 1, calendar: calendar))
        ]

        let progress = BudgetProgressCalculator.progress(
            for: budget,
            entries: entries,
            referenceDate: currentDate,
            calendar: calendar
        )

        XCTAssertEqual(progress.spent, 100)
    }

    func testOverspentProgressHasNegativeRemaining() throws {
        let calendar = makeCalendar()
        let budget = Budget(name: "订阅", amount: 300, period: .monthly)
        let currentDate = try date(2026, 8, 12, calendar: calendar)
        let entries = [
            BudgetEntry(budget: budget, amount: 320, spentAt: currentDate)
        ]

        let progress = BudgetProgressCalculator.progress(
            for: budget,
            entries: entries,
            referenceDate: currentDate,
            calendar: calendar
        )

        XCTAssertEqual(progress.spent, 320)
        XCTAssertEqual(progress.remaining, -20)
        XCTAssertTrue(progress.isOverspent)
        XCTAssertEqual(progress.ratio, 1)
    }

    func testArchivedBudgetStillAggregatesHistoricalEntries() throws {
        let calendar = makeCalendar()
        let budget = Budget(name: "旅行", amount: 12_000, period: .yearly, isArchived: true)
        let currentDate = try date(2026, 8, 12, calendar: calendar)
        let entries = [
            BudgetEntry(budget: budget, amount: 5_000, spentAt: try date(2026, 1, 10, calendar: calendar)),
            BudgetEntry(budget: budget, amount: 4_000, spentAt: try date(2025, 12, 30, calendar: calendar))
        ]

        let progress = BudgetProgressCalculator.progress(
            for: budget,
            entries: entries,
            referenceDate: currentDate,
            calendar: calendar
        )

        XCTAssertEqual(progress.spent, 5_000)
        XCTAssertEqual(progress.remaining, 7_000)
    }

    func testPeriodSummaryOnlyCountsBudgetsInRequestedPeriod() throws {
        let calendar = makeCalendar()
        let monthly = Budget(name: "餐饮", amount: 1_000, period: .monthly)
        let yearly = Budget(name: "旅行", amount: 12_000, period: .yearly)
        let currentDate = try date(2026, 8, 12, calendar: calendar)
        let entries = [
            BudgetEntry(budget: monthly, amount: 100, spentAt: currentDate),
            BudgetEntry(budget: yearly, amount: 3_000, spentAt: currentDate)
        ]

        XCTAssertEqual(
            BudgetProgressCalculator.totalSpent(
                for: .monthly,
                budgets: [monthly],
                entries: entries,
                referenceDate: currentDate,
                calendar: calendar
            ),
            100
        )
    }

    func testDailySpentOnlyCountsSelectedCalendarDayAndBudget() throws {
        let calendar = makeCalendar()
        let food = Budget(name: "餐饮", amount: 1_000, period: .monthly)
        let travel = Budget(name: "旅行", amount: 12_000, period: .yearly)
        let selectedDate = try date(2026, 8, 12, calendar: calendar)
        let entries = [
            BudgetEntry(budget: food, amount: 30, spentAt: selectedDate),
            BudgetEntry(budget: food, amount: 50, spentAt: try date(2026, 8, 13, calendar: calendar)),
            BudgetEntry(budget: travel, amount: 200, spentAt: selectedDate)
        ]

        XCTAssertEqual(
            BudgetProgressCalculator.spent(for: food, on: selectedDate, entries: entries, calendar: calendar),
            30
        )
    }

    private func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 8 * 60 * 60)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, calendar: Calendar) throws -> Date {
        try XCTUnwrap(calendar.date(from: DateComponents(year: year, month: month, day: day)))
    }
}
