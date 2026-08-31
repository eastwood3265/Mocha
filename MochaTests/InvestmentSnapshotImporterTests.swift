import XCTest
@testable import Mocha

final class InvestmentSnapshotImporterTests: XCTestCase {
    func testParsesFundEAccountWithoutMergingDifferentSalesChannels() throws {
        let rows = [
            ["基金E账户App投资者公募基金持有信息"],
            [], [], [],
            ["序号", "基金代码", "基金名称", "份额类别", "基金管理人", "基金账户", "销售机构", "交易账户", "持有份额", "份额日期", "基金净值", "净值日期", "资产情况", "结算币种", "分红方式"],
            ["1", "110022", "易方达消费行业股票", "前收费", "易方达", "A1", "蚂蚁财富", "T1", "1000", "2026/08/22", "4.2", "2026/08/22", "4200", "人民币", "红利再投"],
            ["2", "110022", "易方达消费行业股票", "前收费", "易方达", "A2", "腾讯理财通", "T2", "500", "2026/08/22", "4.2", "2026/08/22", "2100", "人民币", "现金分红"]
        ]

        let result = try FundEAccountSnapshotImporter().parse(rows: rows)

        XCTAssertEqual(result.sourceIdentifier, "investment.fund-e-account")
        XCTAssertEqual(result.records.count, 2)
        XCTAssertEqual(result.records.map(\.marketValue).reduce(0, +), 6300)
        XCTAssertEqual(Set(result.records.map(\.accountAlias)), ["腾讯理财通", "蚂蚁财富"])
        XCTAssertEqual(result.records[0].assetClass, .stock)
    }

    func testParsesNormalizedSnapshotCSV() throws {
        let parsed = try InvestmentSnapshotParser().parse(data: Data(csv.utf8))

        XCTAssertEqual(parsed.sourceIdentifier, "investment.tencent-licaitong")
        XCTAssertEqual(parsed.records.count, 1)
        XCTAssertEqual(parsed.records[0].fundCode, "110022")
        XCTAssertEqual(parsed.records[0].assetClass, .stock)
        XCTAssertEqual(parsed.records[0].marketValue, Decimal(string: "12500.00"))
        XCTAssertEqual(parsed.records[0].totalProfit, Decimal(string: "850.00"))
        XCTAssertEqual(parsed.records[0].profitMetric, .holding)
    }

    func testParsesCurrentFundEAccountAssetHeader() throws {
        let rows = [
            ["序号", "基金代码", "基金名称", "份额类别", "基金管理人", "基金账户", "销售机构", "交易账户", "持有份额", "份额日期", "基金净值", "净值日期", "资产情况\n（结算币种）", "结算币种", "分红方式"],
            ["1", "161115", "易方达岁丰添利债券型证券投资基金A类基金份额", "前收费", "易方达基金", "账户", "易方达财富管理", "交易账户", "1384.62", "2026/08/20", "1.7560", "2026/08/20", "2431.39", "人民币", "现金分红"],
            ["总记录数： 1 笔"],
            [""],
            ["说明："],
            ["数量单位：持有份额单位为“份”"]
        ]

        let result = try FundEAccountSnapshotImporter().parse(rows: rows)

        XCTAssertEqual(result.records.count, 1)
        XCTAssertEqual(result.records[0].fundCode, "161115")
        XCTAssertEqual(result.records[0].marketValue, Decimal(string: "2431.39"))
        XCTAssertEqual(result.records[0].assetClass, .bond)
    }

    func testFundEAccountUsesOnlyLatestSnapshotWithinSameChannel() throws {
        let rows = [
            ["基金代码", "基金名称", "销售机构", "持有份额", "份额日期", "基金净值", "资产情况"],
            ["110022", "易方达消费行业股票", "蚂蚁财富", "100", "2026/08/20", "4", "400"],
            ["110022", "易方达消费行业股票", "蚂蚁财富", "120", "2026/08/25", "4", "480"]
        ]

        let result = try FundEAccountSnapshotImporter().parse(rows: rows)

        XCTAssertEqual(result.records.count, 1)
        XCTAssertEqual(result.records[0].marketValue, 480)
    }

    func testRejectsDuplicateFundCodes() throws {
        let duplicated = csv + "\n2026-08-25,腾讯理财通,长期账户,110022,重复基金,股票,1,0,持有收益,\n"

        XCTAssertThrowsError(try InvestmentSnapshotParser().parse(data: Data(duplicated.utf8))) { error in
            guard case .duplicateProducts = error as? InvestmentSnapshotImportError else {
                return XCTFail("应拒绝同一文件内的重复基金")
            }
        }
    }

    private var csv: String {
        """
        快照日期,平台,账户,基金代码,基金名称,资产类别,持仓金额,总盈亏,收益口径,产品ID
        2026-08-25,腾讯理财通,长期账户,110022,易方达消费行业,股票,12500.00,850.00,持有收益,
        """
    }
}
