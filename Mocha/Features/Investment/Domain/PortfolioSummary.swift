import Foundation

struct PortfolioSummary {
    let investments: [Investment]

    var holdingAmount: Decimal { investments.reduce(0) { $0 + $1.holdingAmount } }
    var totalProfit: Decimal { investments.reduce(0) { $0 + $1.effectiveTotalProfit } }
}
