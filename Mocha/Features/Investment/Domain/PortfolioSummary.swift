import Foundation

struct PortfolioSummary {
    let investments: [Investment]

    var marketValue: Decimal { investments.reduce(0) { $0 + $1.marketValue } }
    var currentProfit: Decimal { investments.reduce(0) { $0 + $1.profit } }
}
