import Foundation
import SwiftData

@Model
final class Investment {
    var name: String
    var code: String
    var typeRawValue: String
    var quantity: Decimal = 0
    var currentPrice: Decimal
    var currentProfit: Decimal = 0
    var note: String
    var createdAt: Date
    var updatedAt: Date
    var storageLocation: StorageLocation?

    var type: InvestmentType {
        get { InvestmentType(rawValue: typeRawValue) ?? .bond }
        set { typeRawValue = newValue.rawValue }
    }

    var marketValue: Decimal { type == .cash ? quantity : quantity * currentPrice }
    var profit: Decimal { type == .cash ? 0 : currentProfit }

    init(
        name: String,
        code: String = "",
        type: InvestmentType,
        quantity: Decimal,
        currentPrice: Decimal,
        currentProfit: Decimal,
        note: String = "",
        storageLocation: StorageLocation? = nil
    ) {
        self.name = name
        self.code = code
        self.typeRawValue = type.rawValue
        self.quantity = quantity
        self.currentPrice = currentPrice
        self.currentProfit = currentProfit
        self.note = note
        self.createdAt = .now
        self.updatedAt = .now
        self.storageLocation = storageLocation
    }
}
