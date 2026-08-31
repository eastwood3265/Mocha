import Foundation
import SwiftData

@Model
final class ImportBatch {
    var domainRawValue: String = ImportDomain.payment.rawValue
    var sourceRawValue: String
    var fileName: String
    var fileFingerprint: String
    var parserVersion: Int = 1
    var importedAt: Date
    var totalRecordCount: Int
    var insertedRecordCount: Int
    var updatedRecordCount: Int = 0
    var duplicateRecordCount: Int

    var domain: ImportDomain { ImportDomain(rawValue: domainRawValue) ?? .payment }
    var sourceIdentifier: String { sourceRawValue }
    var paymentSource: TransactionSource? { TransactionSource(rawValue: sourceRawValue) }

    init(
        source: TransactionSource,
        fileName: String,
        fileFingerprint: String,
        importedAt: Date = .now,
        totalRecordCount: Int,
        insertedRecordCount: Int,
        duplicateRecordCount: Int
    ) {
        domainRawValue = ImportDomain.payment.rawValue
        self.sourceRawValue = source.rawValue
        self.fileName = fileName
        self.fileFingerprint = fileFingerprint
        self.importedAt = importedAt
        self.totalRecordCount = totalRecordCount
        self.insertedRecordCount = insertedRecordCount
        self.duplicateRecordCount = duplicateRecordCount
    }

    init(
        domain: ImportDomain,
        sourceIdentifier: String,
        fileName: String,
        fileFingerprint: String,
        parserVersion: Int,
        importedAt: Date = .now,
        totalRecordCount: Int,
        insertedRecordCount: Int,
        updatedRecordCount: Int,
        duplicateRecordCount: Int
    ) {
        domainRawValue = domain.rawValue
        sourceRawValue = sourceIdentifier
        self.fileName = fileName
        self.fileFingerprint = fileFingerprint
        self.parserVersion = parserVersion
        self.importedAt = importedAt
        self.totalRecordCount = totalRecordCount
        self.insertedRecordCount = insertedRecordCount
        self.updatedRecordCount = updatedRecordCount
        self.duplicateRecordCount = duplicateRecordCount
    }
}
