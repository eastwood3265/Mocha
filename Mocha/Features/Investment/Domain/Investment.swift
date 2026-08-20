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
    var createdAt: Date
    var updatedAt: Date
    var storageLocation: StorageLocation?

    var type: InvestmentType {
        get { InvestmentType(rawValue: typeRawValue) ?? .bond }
        set {
            typeRawValue = newValue.rawValue
            if newValue == .cash { totalProfit = 0 }
        }
    }

    var effectiveTotalProfit: Decimal { type == .cash ? 0 : totalProfit }

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
