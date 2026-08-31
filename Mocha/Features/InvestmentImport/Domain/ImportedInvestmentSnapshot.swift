import Foundation

struct ImportedInvestmentSnapshot: Identifiable, Equatable {
    let sourceIdentifier: String
    let externalProductID: String
    let fundCode: String
    let fundName: String
    let assetClass: InvestmentType
    let marketValue: Decimal
    let totalProfit: Decimal?
    let profitMetric: InvestmentProfitMetric
    let snapshotAt: Date
    let accountAlias: String

    var id: String { positionIdentityKey }

    var productIdentityKey: String {
        if !fundCode.isEmpty { return "code:\(Self.normalize(fundCode))" }
        if !externalProductID.isEmpty { return "product:\(Self.normalize(externalProductID))" }
        return "name:\(Self.normalize(fundName))"
    }

    var positionIdentityKey: String {
        "\(productIdentityKey)|account:\(Self.normalize(accountAlias))"
    }

    static func normalize(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
            .lowercased()
    }
}
