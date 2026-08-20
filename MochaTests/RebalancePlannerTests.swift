import XCTest
@testable import Mocha

final class RebalancePlannerTests: XCTestCase {
    func testBuyFillsLowerAssetTypesTowardEqualValues() {
        let items = makeFourTypes()
        let plan = RebalancePlanner.makePlan(
            investments: items,
            selectedIDs: Set(items.map(\.persistentModelID)),
            amount: 600,
            direction: .buy,
            tradingDayCount: 10
        )
        let amounts = Dictionary(uniqueKeysWithValues: plan.allocations.map { ($0.investment.type, $0.amount) })

        XCTAssertEqual(amounts[.bond], 300)
        XCTAssertEqual(amounts[.stock], 200)
        XCTAssertEqual(amounts[.gold], 100)
        XCTAssertNil(amounts[.cash])
        XCTAssertEqual(plan.allocatedAmount, 600)
    }

    func testSellReducesHigherAssetTypesTowardEqualValues() {
        let items = makeFourTypes()
        let plan = RebalancePlanner.makePlan(
            investments: items,
            selectedIDs: Set(items.map(\.persistentModelID)),
            amount: 600,
            direction: .sell,
            tradingDayCount: 10
        )
        let amounts = Dictionary(uniqueKeysWithValues: plan.allocations.map { ($0.investment.type, $0.amount) })

        XCTAssertNil(amounts[.bond])
        XCTAssertEqual(amounts[.stock], 100)
        XCTAssertEqual(amounts[.gold], 200)
        XCTAssertEqual(amounts[.cash], 300)
        XCTAssertEqual(plan.allocatedAmount, 600)
    }

    func testSameTypeComponentsSplitAmountEqually() {
        let first = Investment(name: "债券A", type: .bond, holdingAmount: 100, totalProfit: 0)
        let second = Investment(name: "债券B", type: .bond, holdingAmount: 200, totalProfit: 0)
        let items = [first, second]
        let plan = RebalancePlanner.makePlan(
            investments: items,
            selectedIDs: Set(items.map(\.persistentModelID)),
            amount: 100,
            direction: .buy,
            tradingDayCount: 5
        )

        XCTAssertEqual(plan.allocations.count, 2)
        XCTAssertTrue(plan.allocations.allSatisfy { $0.amount == 50 })
    }

    func testCashHasNoRecurringDailyAmount() {
        let cash = Investment(name: "现金", type: .cash, holdingAmount: 100, totalProfit: 0)
        let bond = Investment(name: "债券", type: .bond, holdingAmount: 100, totalProfit: 0)
        let cashAllocation = RebalanceAllocation(investment: cash, amount: 50)
        let bondAllocation = RebalanceAllocation(investment: bond, amount: 50)

        XCTAssertNil(cashAllocation.recurringDailyAmount(tradingDayCount: 5))
        XCTAssertEqual(bondAllocation.recurringDailyAmount(tradingDayCount: 5), 10)
    }

    func testTradingDaysExcludeWeekendsAndLegalHolidays() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Shanghai"))
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 3)))

        let weekdays = TradingDayEstimator.remainingWeekdaysInCurrentMonth(from: start, calendar: calendar)
        let tradingDays = TradingDayEstimator.remainingWeekdaysInCurrentMonth(
            from: start,
            calendar: calendar,
            holidayDates: ["2026-08-10"]
        )

        XCTAssertEqual(weekdays, 21)
        XCTAssertEqual(tradingDays, 20)
    }

    private func makeFourTypes() -> [Investment] {
        [
            Investment(name: "债券", type: .bond, holdingAmount: 100, totalProfit: 0),
            Investment(name: "股票", type: .stock, holdingAmount: 200, totalProfit: 0),
            Investment(name: "黄金", type: .gold, holdingAmount: 300, totalProfit: 0),
            Investment(name: "现金", type: .cash, holdingAmount: 400, totalProfit: 0)
        ]
    }
}
