import SwiftData
import XCTest
@testable import Mocha

@MainActor
final class StatementImportServiceTests: XCTestCase {
    func testRepeatedImportDoesNotCreateDuplicateTransactions() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let data = Data(alipayCSV.utf8)
        let service = StatementImportService()

        let firstPreview = try service.preview(data: data, fileName: "alipay.csv", context: context)
        try service.commit(firstPreview, context: context)
        let secondPreview = try service.preview(data: data, fileName: "alipay.csv", context: context)

        XCTAssertEqual(firstPreview.newRecords.count, 1)
        XCTAssertEqual(secondPreview.newRecords.count, 0)
        XCTAssertEqual(secondPreview.duplicateRecordCount, 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<FinancialTransaction>()), 1)
    }

    func testDuplicateRowsInsideOneFileAreDeduplicated() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let duplicatedCSV = alipayCSV + "\n2026-08-20 08:00:00,早餐店,支出,12.50,A001\n"

        let preview = try StatementImportService().preview(
            data: Data(duplicatedCSV.utf8),
            fileName: "alipay.csv",
            context: context
        )

        XCTAssertEqual(preview.totalRecordCount, 2)
        XCTAssertEqual(preview.newRecords.count, 1)
        XCTAssertEqual(preview.duplicateRecordCount, 1)
    }

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ImportBatch.self,
            FinancialTransaction.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private var alipayCSV: String {
        """
        交易时间,交易对方,收/支,金额,交易订单号
        2026-08-20 08:00:00,早餐店,支出,12.50,A001
        """
    }
}
