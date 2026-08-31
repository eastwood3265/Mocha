import CoreFoundation
import XCTest
@testable import Mocha

final class StatementParserTests: XCTestCase {
    func testParsesAlipayCSVWithPreambleAndQuotedComma() throws {
        let csv = """
        支付宝交易记录明细查询
        交易时间,交易分类,交易对方,商品说明,收/支,金额,收/付款方式,交易状态,交易订单号,商家订单号,备注
        2026-08-20 12:30:10,餐饮美食,"咖啡,便利店",午餐,支出,25.80,招商银行卡,交易成功,20260820001,M001,"工作日,午餐"
        """

        let statement = try StatementParser().parse(data: Data(csv.utf8))

        XCTAssertEqual(statement.source, .alipay)
        XCTAssertEqual(statement.records.count, 1)
        XCTAssertEqual(statement.records[0].counterparty, "咖啡,便利店")
        XCTAssertEqual(statement.records[0].amount, Decimal(string: "25.80"))
        XCTAssertEqual(statement.records[0].direction, .expense)
        XCTAssertEqual(statement.records[0].externalID, "20260820001")
    }

    func testParsesGB18030AlipayCSV() throws {
        let csv = """
        交易时间,交易对方,商品说明,收/支,金额,交易状态,交易订单号
        2026-08-20 08:00:00,早餐店,早餐,支出,12.50,交易成功,A001
        """
        let encoding = String.Encoding(
            rawValue: CFStringConvertEncodingToNSStringEncoding(
                CFStringEncoding(0x0632)
            )
        )
        let data = try XCTUnwrap(csv.data(using: encoding))

        let statement = try StatementParser().parse(data: data)

        XCTAssertEqual(statement.records.first?.counterparty, "早餐店")
    }

    func testParsesWeChatCSV() throws {
        let csv = """
        微信支付账单明细
        交易时间,交易类型,交易对方,商品,收/支,金额(元),支付方式,当前状态,交易单号,商户单号,备注
        2026-08-21 18:05:00,商户消费,便利店,饮料,支出,6.00,零钱,支付成功,WX001,M002,
        """

        let statement = try StatementParser().parse(data: Data(csv.utf8))

        XCTAssertEqual(statement.source, .wechat)
        XCTAssertEqual(statement.records.first?.externalID, "WX001")
        XCTAssertEqual(statement.records.first?.paymentMethod, "零钱")
    }

    func testRejectsInvalidTransactionRowsInsteadOfSilentlyDroppingThem() throws {
        let csv = """
        交易时间,交易对方,收/支,金额,交易订单号
        无效日期,早餐店,支出,12.50,A001
        """

        XCTAssertThrowsError(try StatementParser().parse(data: Data(csv.utf8))) { error in
            XCTAssertEqual(error as? StatementImportError, .invalidRows(1))
        }
    }
}
