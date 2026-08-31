import Foundation

enum InvestmentProfitMetric: String, Codable, CaseIterable {
    case holding = "持有收益"
    case cumulative = "累计收益"
    case unspecified = "未说明"
}
