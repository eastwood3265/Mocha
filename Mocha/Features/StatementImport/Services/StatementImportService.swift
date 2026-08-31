import CryptoKit
import Foundation
import SwiftData

struct StatementImportPreview {
    let source: TransactionSource
    let fileName: String
    let fileFingerprint: String
    let totalRecordCount: Int
    let newRecords: [ImportedTransaction]
    let duplicateRecordCount: Int
}

@MainActor
struct StatementImportService {
    private let parser = StatementParser()

    func preview(data: Data, fileName: String, context: ModelContext) throws -> StatementImportPreview {
        let statement = try parser.parse(data: data)
        let existingFingerprints = Set(
            try context.fetch(FetchDescriptor<FinancialTransaction>()).map(\.fingerprint)
        )
        var seenFingerprints = existingFingerprints
        var newRecords: [ImportedTransaction] = []
        var duplicateCount = 0

        for record in statement.records {
            if seenFingerprints.insert(record.fingerprint).inserted {
                newRecords.append(record)
            } else {
                duplicateCount += 1
            }
        }

        return StatementImportPreview(
            source: statement.source,
            fileName: fileName,
            fileFingerprint: Self.sha256(data),
            totalRecordCount: statement.records.count,
            newRecords: newRecords,
            duplicateRecordCount: duplicateCount
        )
    }

    @discardableResult
    func commit(_ preview: StatementImportPreview, context: ModelContext) throws -> ImportBatch {
        let batch = ImportBatch(
            source: preview.source,
            fileName: preview.fileName,
            fileFingerprint: preview.fileFingerprint,
            totalRecordCount: preview.totalRecordCount,
            insertedRecordCount: preview.newRecords.count,
            duplicateRecordCount: preview.duplicateRecordCount
        )
        context.insert(batch)
        for record in preview.newRecords {
            context.insert(FinancialTransaction(record: record, importBatch: batch))
        }
        try context.save()
        return batch
    }

    private static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
