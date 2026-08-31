import SwiftData
import XCTest
@testable import Mocha

@MainActor
final class InvestmentSnapshotImportServiceTests: XCTestCase {
    func testDefaultsToCreateAndCanExplicitlyUpdateSelectedInvestment() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let location = StorageLocation(name: "腾讯理财通", type: .fundPlatform)
        context.insert(location)
        let service = InvestmentSnapshotImportService()

        let first = try service.preview(
            data: data(value: "10000", date: "2026-08-20"),
            fileName: "first.csv"
        )
        var createDrafts = first.defaultDrafts
        createDrafts[0].storageLocation = location
        let firstBatch = try service.commit(first, drafts: createDrafts, context: context)
        let second = try service.preview(
            data: data(value: "10500", date: "2026-08-25"),
            fileName: "second.csv"
        )
        var updateDrafts = second.defaultDrafts
        updateDrafts[0].action = .update
        updateDrafts[0].targetInvestment = try XCTUnwrap(context.fetch(FetchDescriptor<Investment>()).first)
        let secondBatch = try service.commit(second, drafts: updateDrafts, context: context)

        let investments = try context.fetch(FetchDescriptor<Investment>())
        XCTAssertEqual(firstBatch.insertedRecordCount, 1)
        XCTAssertEqual(secondBatch.updatedRecordCount, 1)
        XCTAssertEqual(investments.count, 1)
        XCTAssertEqual(investments[0].holdingAmount, 10500)
        XCTAssertEqual(investments[0].storageLocation?.persistentModelID, location.persistentModelID)
        XCTAssertEqual(investments[0].dataSourceIdentifier, "investment.tencent-licaitong")
        XCTAssertEqual(investments[0].sourceAccountName, "长期账户")
    }

    func testCreateConfigurationCanOverrideImportedDefaults() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let location = StorageLocation(name: "腾讯理财通", type: .fundPlatform)
        context.insert(location)
        let service = InvestmentSnapshotImportService()
        let preview = try service.preview(
            data: data(value: "10500", date: "2026-08-25"),
            fileName: "configured.csv"
        )
        var drafts = preview.defaultDrafts
        drafts[0].name = "我的消费基金"
        drafts[0].type = .bond
        drafts[0].holdingAmount = 10888
        drafts[0].note = "长期持有"
        drafts[0].storageLocation = location
        try service.commit(preview, drafts: drafts, context: context)

        let investment = try XCTUnwrap(context.fetch(FetchDescriptor<Investment>()).first)
        XCTAssertEqual(investment.name, "我的消费基金")
        XCTAssertEqual(investment.type, .bond)
        XCTAssertEqual(investment.holdingAmount, 10888)
        XCTAssertEqual(investment.note, "长期持有")
        XCTAssertEqual(investment.storageLocation?.persistentModelID, location.persistentModelID)
    }

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Investment.self,
            StorageLocation.self,
            ImportBatch.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func data(value: String, date: String) -> Data {
        Data("""
        快照日期,平台,账户,基金代码,基金名称,资产类别,持仓金额,总盈亏,收益口径,产品ID
        \(date),腾讯理财通,长期账户,110022,易方达消费行业,股票,\(value),850,持有收益,
        """.utf8)
    }
}
