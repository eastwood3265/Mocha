import CryptoKit
import Foundation
import SwiftData

enum InvestmentSnapshotImportAction: String, CaseIterable, Identifiable {
    case create = "新建基金"
    case update = "更新已有"

    var id: Self { self }
}

struct InvestmentSnapshotImportDraft: Identifiable {
    let snapshot: ImportedInvestmentSnapshot
    var action: InvestmentSnapshotImportAction = .create
    var targetInvestment: Investment?
    var name: String
    var code: String
    var type: InvestmentType
    var holdingAmount: Decimal
    var totalProfit: Decimal
    var note: String = ""
    var storageLocation: StorageLocation?

    var id: String { snapshot.id }

    init(snapshot: ImportedInvestmentSnapshot) {
        self.snapshot = snapshot
        name = snapshot.fundName
        code = snapshot.fundCode
        type = snapshot.assetClass
        holdingAmount = snapshot.marketValue
        totalProfit = snapshot.totalProfit ?? 0
    }
}

struct InvestmentSnapshotImportPreview: Identifiable {
    let sourceIdentifier: String
    let parserVersion: Int
    let fileName: String
    let fileFingerprint: String
    let snapshots: [ImportedInvestmentSnapshot]

    var id: String { fileFingerprint }
    var defaultDrafts: [InvestmentSnapshotImportDraft] { snapshots.map(InvestmentSnapshotImportDraft.init) }
}

@MainActor
struct InvestmentSnapshotImportService {
    private let parser = InvestmentSnapshotParser()

    func preview(
        data: Data,
        fileName: String
    ) throws -> InvestmentSnapshotImportPreview {
        let parsed = try parser.parse(data: data, fileName: fileName)
        return InvestmentSnapshotImportPreview(
            sourceIdentifier: parsed.sourceIdentifier,
            parserVersion: parsed.parserVersion,
            fileName: fileName,
            fileFingerprint: Self.sha256(data),
            snapshots: parsed.records
        )
    }

    @discardableResult
    func commit(
        _ preview: InvestmentSnapshotImportPreview,
        drafts: [InvestmentSnapshotImportDraft],
        context: ModelContext
    ) throws -> ImportBatch {
        try validate(drafts)
        let insertedCount = drafts.filter { $0.action == .create }.count
        let updatedCount = drafts.filter { $0.action == .update }.count
        let batch = ImportBatch(
            domain: .investment,
            sourceIdentifier: preview.sourceIdentifier,
            fileName: preview.fileName,
            fileFingerprint: preview.fileFingerprint,
            parserVersion: preview.parserVersion,
            totalRecordCount: drafts.count,
            insertedRecordCount: insertedCount,
            updatedRecordCount: updatedCount,
            duplicateRecordCount: 0
        )
        context.insert(batch)

        for draft in drafts {
            switch draft.action {
            case .create:
                let investment = Investment(
                    name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
                    code: draft.type == .cash ? "" : draft.code.trimmingCharacters(in: .whitespacesAndNewlines),
                    type: draft.type,
                    holdingAmount: draft.holdingAmount,
                    totalProfit: draft.totalProfit,
                    note: draft.note,
                    storageLocation: draft.storageLocation
                )
                applyMetadata(draft.snapshot, to: investment, batch: batch)
                context.insert(investment)
            case .update:
                guard let investment = draft.targetInvestment else { continue }
                investment.name = draft.snapshot.fundName
                investment.code = draft.snapshot.fundCode
                investment.type = draft.snapshot.assetClass
                investment.holdingAmount = draft.snapshot.marketValue
                if let totalProfit = draft.snapshot.totalProfit { investment.totalProfit = totalProfit }
                applyMetadata(draft.snapshot, to: investment, batch: batch)
            }
        }

        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        return batch
    }

    private func validate(_ drafts: [InvestmentSnapshotImportDraft]) throws {
        let invalidCreates = drafts.filter {
            $0.action == .create &&
                ($0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || $0.holdingAmount < 0)
        }
        guard invalidCreates.isEmpty else {
            throw InvestmentSnapshotImportError.invalidImportConfiguration("新建基金的名称不能为空，持仓金额不能小于 0")
        }
        let updates = drafts.filter { $0.action == .update }
        guard updates.allSatisfy({ $0.targetInvestment != nil }) else {
            throw InvestmentSnapshotImportError.invalidImportConfiguration("请为每条更新记录选择已有基金")
        }
        let targetIDs = updates.compactMap { $0.targetInvestment?.persistentModelID }
        guard Set(targetIDs).count == targetIDs.count else {
            throw InvestmentSnapshotImportError.invalidImportConfiguration("同一已有基金不能被多条导入记录同时覆盖")
        }
    }

    private func applyMetadata(_ snapshot: ImportedInvestmentSnapshot, to investment: Investment, batch: ImportBatch) {
        investment.externalProductID = snapshot.externalProductID
        investment.dataSourceIdentifier = snapshot.sourceIdentifier
        investment.sourceAccountName = snapshot.accountAlias
        investment.snapshotAt = snapshot.snapshotAt
        investment.profitMetric = snapshot.profitMetric
        investment.lastImportBatch = batch
        investment.updatedAt = .now
    }

    private static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
