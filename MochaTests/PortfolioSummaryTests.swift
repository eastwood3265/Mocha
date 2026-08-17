import XCTest
@testable import Mocha

final class PortfolioSummaryTests: XCTestCase {
    func testSummaryAggregatesMarketValueAndCurrentProfit() {
        let bond = Investment(name: "债券", type: .bond, quantity: 100, currentPrice: 1.2, currentProfit: 20)
        let gold = Investment(name: "黄金", type: .gold, quantity: 10, currentPrice: 550, currentProfit: -100)
        let summary = PortfolioSummary(investments: [bond, gold])

        XCTAssertEqual(summary.marketValue, 5_620)
        XCTAssertEqual(summary.currentProfit, -80)
    }

    func testCashUsesHoldingAsMarketValueAndAlwaysHasZeroProfit() {
        let cash = Investment(name: "备用金", type: .cash, quantity: 12_000, currentPrice: 99, currentProfit: 500)

        XCTAssertEqual(cash.marketValue, 12_000)
        XCTAssertEqual(cash.profit, 0)
        XCTAssertEqual(PortfolioSummary(investments: [cash]).currentProfit, 0)
    }
}
