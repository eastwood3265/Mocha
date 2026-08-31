import Foundation
import SwiftData

@Model
final class FinancialTransaction {
    var sourceRawValue: String
    var externalID: String
    var fingerprint: String
    var occurredAt: Date
    var directionRawValue: String
    var amount: Decimal
    var counterparty: String
    var descriptionText: String
    var paymentMethod: String
    var status: String
    var merchantOrderID: String
    var note: String
    var createdAt: Date
    var importBatch: ImportBatch?

    var source: TransactionSource {
        TransactionSource(rawValue: sourceRawValue) ?? .alipay
    }

    var direction: TransactionDirection {
        TransactionDirection(rawValue: directionRawValue) ?? .neutral
    }

    init(record: ImportedTransaction, importBatch: ImportBatch) {
        sourceRawValue = record.source.rawValue
        externalID = record.externalID
        fingerprint = record.fingerprint
        occurredAt = record.occurredAt
        directionRawValue = record.direction.rawValue
        amount = record.amount
        counterparty = record.counterparty
        descriptionText = record.description
        paymentMethod = record.paymentMethod
        status = record.status
        merchantOrderID = record.merchantOrderID
        note = record.note
        createdAt = .now
        self.importBatch = importBatch
    }
}
