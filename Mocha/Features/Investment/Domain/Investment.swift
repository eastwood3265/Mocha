import Foundation
import SwiftData

@Model
final class Investment {
    var name: String
    var code: String
    var typeRawValue: String
    var holdingAmount: Decimal = 0
    var totalProfit: Decimal = 0
    var note: String
    var externalProductID: String = ""
    var dataSourceIdentifier: String = ""
    var sourceAccountName: String = ""
    var snapshotAt: Date?
    var profitMetricRawValue: String = InvestmentProfitMetric.unspecified.rawValue
    var createdAt: Date
    var updatedAt: Date
    var storageLocation: StorageLocation?
    var lastImportBatch: ImportBatch?

    var type: InvestmentType {
        get { InvestmentType(rawValue: typeRawValue) ?? .bond }
        set {
            typeRawValue = newValue.rawValue
            if newValue == .cash { totalProfit = 0 }
        }
    }

    var effectiveTotalProfit: Decimal { type == .cash ? 0 : totalProfit }

    var dataSourceName: String {
        switch dataSourceIdentifier {
        case "investment.tencent-licaitong": "腾讯理财通"
        case "investment.ant-wealth": "蚂蚁财富"
        case "investment.efunds": "易方达"
        case "investment.fund-e-account": "基金 E 账户"
        case "investment.mixed": "多个平台"
        default: dataSourceIdentifier
        }
    }

    var profitMetric: InvestmentProfitMetric {
        get { InvestmentProfitMetric(rawValue: profitMetricRawValue) ?? .unspecified }
        set { profitMetricRawValue = newValue.rawValue }
    }

    init(
        name: String,
        code: String = "",
        type: InvestmentType,
        holdingAmount: Decimal,
        totalProfit: Decimal,
        note: String = "",
        storageLocation: StorageLocation? = nil
    ) {
        self.name = name
        self.code = code
        self.typeRawValue = type.rawValue
        self.holdingAmount = holdingAmount
        self.totalProfit = type == .cash ? 0 : totalProfit
        self.note = note
        self.createdAt = .now
        self.updatedAt = .now
        self.storageLocation = storageLocation
    }
}
