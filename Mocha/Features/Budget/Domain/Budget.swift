import Foundation
import SwiftData

@Model
final class Budget {
    var name: String
    var amount: Decimal
    var periodRawValue: String
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    var period: BudgetPeriod {
        get { BudgetPeriod(rawValue: periodRawValue) ?? .monthly }
        set { periodRawValue = newValue.rawValue }
    }

    init(
        name: String,
        amount: Decimal,
        period: BudgetPeriod,
        isArchived: Bool = false
    ) {
        self.name = name
        self.amount = amount
        self.periodRawValue = period.rawValue
        self.isArchived = isArchived
        self.createdAt = .now
        self.updatedAt = .now
    }
}
