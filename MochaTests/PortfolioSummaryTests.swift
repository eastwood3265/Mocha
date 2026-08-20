import XCTest
@testable import Mocha

final class PortfolioSummaryTests: XCTestCase {
    func testSummaryAggregatesHoldingAmountAndTotalProfit() {
        let bond = Investment(name: "债券", type: .bond, holdingAmount: 120, totalProfit: 20)
        let gold = Investment(name: "黄金", type: .gold, holdingAmount: 5_500, totalProfit: -100)
        let summary = PortfolioSummary(investments: [bond, gold])

        XCTAssertEqual(summary.holdingAmount, 5_620)
        XCTAssertEqual(summary.totalProfit, -80)
    }

    func testCashKeepsHoldingAmountAndHidesProfitFromSummary() {
        let cash = Investment(name: "备用金", type: .cash, holdingAmount: 12_000, totalProfit: 500)

        XCTAssertEqual(cash.holdingAmount, 12_000)
        XCTAssertEqual(cash.totalProfit, 0)
        XCTAssertEqual(cash.effectiveTotalProfit, 0)
        XCTAssertEqual(PortfolioSummary(investments: [cash]).totalProfit, 0)
    }
}
