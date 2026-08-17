import Foundation
import SwiftData

@Model
final class BudgetEntry {
    var amount: Decimal
    var spentAt: Date
    var note: String
    var createdAt: Date
    var updatedAt: Date
    var budget: Budget?

    init(
        budget: Budget,
        amount: Decimal,
        spentAt: Date = .now,
        note: String = ""
    ) {
        self.amount = amount
        self.spentAt = spentAt
        self.note = note
        self.createdAt = .now
        self.updatedAt = .now
        self.budget = budget
    }
}
