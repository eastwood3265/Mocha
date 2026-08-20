import Foundation
import SwiftData

@Model
final class SavingsBucket {
    var name: String
    var targetAmount: Decimal?
    var deadline: Date?
    var note: String
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .nullify, inverse: \SavingsBucketEntry.bucket)
    var entries: [SavingsBucketEntry] = []

    init(
        name: String,
        targetAmount: Decimal? = nil,
        deadline: Date? = nil,
        note: String = "",
        isArchived: Bool = false
    ) {
        self.name = name
        self.targetAmount = targetAmount
        self.deadline = deadline
        self.note = note
        self.isArchived = isArchived
        self.createdAt = .now
        self.updatedAt = .now
    }
}

enum GoldenBucketSettings {
    static let negativeBalanceWarningKey = "goldenBucketNegativeBalanceWarningEnabled"
}
