import Foundation

struct NormalizedInvestmentSnapshotCSVImporter: InvestmentSnapshotImporter {
    let parserVersion = 1

    private let requiredColumns = ["快照日期", "平台", "基金名称", "资产类别", "持仓金额"]

    func canParse(rows: [[String]]) -> Bool {
        rows.contains { row in
            let columns = StatementColumnMap(header: row)
            return requiredColumns.allSatisfy { columns.contains(any: [$0]) }
        }
    }

    func parse(rows: [[String]]) throws -> ParsedInvestmentSnapshot {
        guard let headerIndex = rows.firstIndex(where: { row in
            let columns = StatementColumnMap(header: row)
            return requiredColumns.allSatisfy { columns.contains(any: [$0]) }
        }) else {
            throw InvestmentSnapshotImportError.missingRequiredColumns(requiredColumns)
        }
        let columns = StatementColumnMap(header: rows[headerIndex])
        var records: [ImportedInvestmentSnapshot] = []
        var invalidCount = 0

        for row in rows.dropFirst(headerIndex + 1) {
            let name = columns.value(in: row, aliases: ["基金名称"])
            let platform = columns.value(in: row, aliases: ["平台"])
            let marketValueText = columns.value(in: row, aliases: ["持仓金额"])
            if name.isEmpty && marketValueText.isEmpty { continue }

            guard !name.isEmpty, !platform.isEmpty,
                  let date = Self.date(columns.value(in: row, aliases: ["快照日期"])),
                  let assetClass = Self.assetClass(columns.value(in: row, aliases: ["资产类别"])),
                  let marketValue = StatementValueParser.amount(marketValueText),
                  marketValue >= 0 else {
                invalidCount += 1
                continue
            }

            let profitText = columns.value(in: row, aliases: ["总盈亏"])
            let profit = profitText.isEmpty ? nil : StatementValueParser.amount(profitText)
            if !profitText.isEmpty && profit == nil {
                invalidCount += 1
                continue
            }

            records.append(ImportedInvestmentSnapshot(
                sourceIdentifier: Self.sourceIdentifier(platform),
                externalProductID: columns.value(in: row, aliases: ["产品ID"]),
                fundCode: columns.value(in: row, aliases: ["基金代码"]),
                fundName: name,
                assetClass: assetClass,
                marketValue: marketValue,
                totalProfit: profit,
                profitMetric: Self.profitMetric(columns.value(in: row, aliases: ["收益口径"])),
                snapshotAt: date,
                accountAlias: columns.value(in: row, aliases: ["账户"])
            ))
        }

        if invalidCount > 0 { throw InvestmentSnapshotImportError.invalidRows(invalidCount) }
        if records.isEmpty { throw InvestmentSnapshotImportError.noSnapshots }

        let grouped = Dictionary(grouping: records, by: \.positionIdentityKey)
        let duplicates = grouped.values.filter { $0.count > 1 }.compactMap { $0.first?.fundName }
        if !duplicates.isEmpty { throw InvestmentSnapshotImportError.duplicateProducts(duplicates.sorted()) }

        let sources = Set(records.map(\.sourceIdentifier))
        return ParsedInvestmentSnapshot(
            sourceIdentifier: sources.count == 1 ? sources.first! : "investment.mixed",
            parserVersion: parserVersion,
            records: records
        )
    }

    private static func date(_ value: String) -> Date? {
        for format in ["yyyy-MM-dd", "yyyy/MM/dd", "yyyy-MM-dd HH:mm:ss"] {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
            formatter.dateFormat = format
            if let date = formatter.date(from: value) { return date }
        }
        return nil
    }

    private static func assetClass(_ value: String) -> InvestmentType? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return InvestmentType.allCases.first { $0.rawValue == normalized }
    }

    private static func profitMetric(_ value: String) -> InvestmentProfitMetric {
        InvestmentProfitMetric(rawValue: value.trimmingCharacters(in: .whitespacesAndNewlines)) ?? .unspecified
    }

    private static func sourceIdentifier(_ value: String) -> String {
        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "腾讯理财通", "理财通": "investment.tencent-licaitong"
        case "蚂蚁财富": "investment.ant-wealth"
        case "易方达", "易方达e钱包", "易方达财富": "investment.efunds"
        default:
            "investment." + ImportedInvestmentSnapshot.normalize(value)
        }
    }
}
