import Foundation
import SwiftData

enum SavingsBucketEntryType: String, Codable, CaseIterable, Identifiable {
    case deposit
    case withdrawal

    var id: Self { self }

    var title: String {
        switch self {
        case .deposit: "存入"
        case .withdrawal: "取出"
        }
    }

    var systemImage: String {
        switch self {
        case .deposit: "arrow.down.circle.fill"
        case .withdrawal: "arrow.up.circle.fill"
        }
    }

    func signedAmount(_ amount: Decimal) -> Decimal {
        switch self {
        case .deposit: amount
        case .withdrawal: -amount
        }
    }
}

@Model
final class SavingsBucketEntry {
    var typeRawValue: String
    var amount: Decimal
    var occurredAt: Date
    var note: String
    var createdAt: Date
    var updatedAt: Date
    var bucket: SavingsBucket?

    var type: SavingsBucketEntryType {
        get { SavingsBucketEntryType(rawValue: typeRawValue) ?? .deposit }
        set { typeRawValue = newValue.rawValue }
    }

    var signedAmount: Decimal { type.signedAmount(amount) }

    init(
        bucket: SavingsBucket,
        type: SavingsBucketEntryType,
        amount: Decimal,
        occurredAt: Date = .now,
        note: String = ""
    ) {
        self.typeRawValue = type.rawValue
        self.amount = amount
        self.occurredAt = occurredAt
        self.note = note
        self.createdAt = .now
        self.updatedAt = .now
        self.bucket = bucket
    }
}
