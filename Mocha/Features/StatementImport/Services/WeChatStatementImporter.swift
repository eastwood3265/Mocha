import Foundation

struct WeChatStatementImporter: StatementImporter {
    let source = TransactionSource.wechat

    private let amountColumns = ["金额(元)", "金额（元）", "金额"]

    func canParse(header: [String]) -> Bool {
        let columns = StatementColumnMap(header: header)
        return columns.contains(any: ["交易时间"])
            && columns.contains(any: amountColumns)
            && columns.contains(any: ["微信支付账单号", "交易单号", "微信支付交易单号"])
    }

    func parse(rows: [[String]], headerIndex: Int) throws -> ParsedStatement {
        let columns = StatementColumnMap(header: rows[headerIndex])
        guard columns.contains(any: ["交易时间"]), columns.contains(any: amountColumns) else {
            throw StatementImportError.missingRequiredColumns(["交易时间", "金额"])
        }

        var records: [ImportedTransaction] = []
        var invalidCount = 0
        var emptyCount = 0
        for row in rows.dropFirst(headerIndex + 1) {
            let timeText = columns.value(in: row, aliases: ["交易时间"])
            let amountText = columns.value(in: row, aliases: amountColumns)
            if timeText.isEmpty && amountText.isEmpty {
                emptyCount += 1
                continue
            }
            guard let occurredAt = StatementValueParser.date(timeText),
                  let amount = StatementValueParser.amount(amountText) else {
                invalidCount += 1
                continue
            }
            records.append(ImportedTransaction(
                source: source,
                externalID: columns.value(in: row, aliases: ["微信支付账单号", "交易单号", "微信支付交易单号"]),
                occurredAt: occurredAt,
                direction: StatementValueParser.direction(columns.value(in: row, aliases: ["收/支", "收支"])),
                amount: amount,
                counterparty: columns.value(in: row, aliases: ["交易对方"]),
                description: columns.value(in: row, aliases: ["商品", "商品说明"]),
                paymentMethod: columns.value(in: row, aliases: ["支付方式", "收/付款方式"]),
                status: columns.value(in: row, aliases: ["当前状态", "交易状态"]),
                merchantOrderID: columns.value(in: row, aliases: ["商户单号", "商家订单号"]),
                note: columns.value(in: row, aliases: ["备注"])
            ))
        }
        if invalidCount > 0 { throw StatementImportError.invalidRows(invalidCount) }
        if records.isEmpty { throw StatementImportError.noTransactions }
        return ParsedStatement(source: source, records: records, skippedEmptyRowCount: emptyCount)
    }
}
