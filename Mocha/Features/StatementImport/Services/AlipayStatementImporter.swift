import Foundation

struct AlipayStatementImporter: StatementImporter {
    let source = TransactionSource.alipay

    private let timeColumns = ["交易时间", "入账时间"]
    private let amountColumns = ["金额", "收支金额", "金额（元）", "金额(元)"]

    func canParse(header: [String]) -> Bool {
        let columns = StatementColumnMap(header: header)
        return columns.contains(any: timeColumns)
            && columns.contains(any: amountColumns)
            && columns.contains(any: ["交易订单号", "支付宝交易号", "交易号"])
    }

    func parse(rows: [[String]], headerIndex: Int) throws -> ParsedStatement {
        let columns = StatementColumnMap(header: rows[headerIndex])
        guard columns.contains(any: timeColumns), columns.contains(any: amountColumns) else {
            throw StatementImportError.missingRequiredColumns(["交易时间", "金额"])
        }

        var records: [ImportedTransaction] = []
        var invalidCount = 0
        var emptyCount = 0
        for row in rows.dropFirst(headerIndex + 1) {
            let timeText = columns.value(in: row, aliases: timeColumns)
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
                externalID: columns.value(in: row, aliases: ["交易订单号", "支付宝交易号", "交易号"]),
                occurredAt: occurredAt,
                direction: StatementValueParser.direction(columns.value(in: row, aliases: ["收/支", "收支", "收支类型"])),
                amount: amount,
                counterparty: columns.value(in: row, aliases: ["交易对方", "对方名称", "对方支付宝账户"]),
                description: columns.value(in: row, aliases: ["商品说明", "商品名称", "账务类型"]),
                paymentMethod: columns.value(in: row, aliases: ["收/付款方式", "付款方式", "支付方式"]),
                status: columns.value(in: row, aliases: ["交易状态", "状态"]),
                merchantOrderID: columns.value(in: row, aliases: ["商家订单号", "商户订单号"]),
                note: columns.value(in: row, aliases: ["备注"])
            ))
        }
        if invalidCount > 0 { throw StatementImportError.invalidRows(invalidCount) }
        if records.isEmpty { throw StatementImportError.noTransactions }
        return ParsedStatement(source: source, records: records, skippedEmptyRowCount: emptyCount)
    }
}
