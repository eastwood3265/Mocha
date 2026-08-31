import Foundation

struct FundEAccountSnapshotImporter: InvestmentSnapshotImporter {
    let parserVersion = 2

    private let requiredColumns = ["基金代码", "基金名称", "持有份额", "份额日期"]
    private let assetColumnAliases = ["资产情况", "资产情况（结算币种）"]

    func canParse(rows: [[String]]) -> Bool {
        rows.contains { row in
            let columns = StatementColumnMap(header: row)
            return requiredColumns.allSatisfy { columns.contains(any: [$0]) }
                && columns.contains(any: assetColumnAliases)
                && columns.contains(any: ["销售机构"])
        }
    }

    func parse(rows: [[String]]) throws -> ParsedInvestmentSnapshot {
        guard let headerIndex = rows.firstIndex(where: canParseHeader) else {
            throw InvestmentSnapshotImportError.missingRequiredColumns(requiredColumns)
        }
        let columns = StatementColumnMap(header: rows[headerIndex])
        var rawRecords: [ImportedInvestmentSnapshot] = []
        var invalidCount = 0

        for row in rows.dropFirst(headerIndex + 1) {
            let fundCode = Self.fundCode(columns.value(in: row, aliases: ["基金代码"]))
            let fundName = columns.value(in: row, aliases: ["基金名称"])
            if fundCode.isEmpty && fundName.isEmpty { continue }

            let marketValueText = columns.value(in: row, aliases: assetColumnAliases)
            let shares = StatementValueParser.amount(columns.value(in: row, aliases: ["持有份额"]))
            let nav = StatementValueParser.amount(columns.value(in: row, aliases: ["基金净值"]))
            let marketValue = StatementValueParser.amount(marketValueText) ?? shares.flatMap { held in nav.map { held * $0 } }
            guard !fundCode.isEmpty, !fundName.isEmpty,
                  let snapshotAt = Self.date(columns.value(in: row, aliases: ["份额日期"])),
                  let marketValue, marketValue >= 0 else {
                invalidCount += 1
                continue
            }

            rawRecords.append(ImportedInvestmentSnapshot(
                sourceIdentifier: "investment.fund-e-account",
                externalProductID: "",
                fundCode: fundCode,
                fundName: fundName,
                assetClass: Self.assetClass(fundName),
                marketValue: marketValue,
                totalProfit: nil,
                profitMetric: .unspecified,
                snapshotAt: snapshotAt,
                accountAlias: columns.value(in: row, aliases: ["销售机构"])
            ))
        }

        if invalidCount > 0 { throw InvestmentSnapshotImportError.invalidRows(invalidCount) }
        if rawRecords.isEmpty { throw InvestmentSnapshotImportError.noSnapshots }

        let records = Dictionary(grouping: rawRecords, by: \.positionIdentityKey).values.map { holdings in
            let latestDate = holdings.map(\.snapshotAt).max()!
            let latestHoldings = holdings.filter { $0.snapshotAt == latestDate }
            let latest = latestHoldings[0]
            return ImportedInvestmentSnapshot(
                sourceIdentifier: latest.sourceIdentifier,
                externalProductID: "",
                fundCode: latest.fundCode,
                fundName: latest.fundName,
                assetClass: latest.assetClass,
                marketValue: latestHoldings.reduce(0) { $0 + $1.marketValue },
                totalProfit: nil,
                profitMetric: .unspecified,
                snapshotAt: latestDate,
                accountAlias: latest.accountAlias
            )
        }.sorted {
            ($0.fundCode, $0.accountAlias) < ($1.fundCode, $1.accountAlias)
        }

        return ParsedInvestmentSnapshot(
            sourceIdentifier: "investment.fund-e-account",
            parserVersion: parserVersion,
            records: records
        )
    }

    private func canParseHeader(_ row: [String]) -> Bool {
        let columns = StatementColumnMap(header: row)
        return requiredColumns.allSatisfy { columns.contains(any: [$0]) }
            && columns.contains(any: assetColumnAliases)
            && columns.contains(any: ["销售机构"])
    }

    private static func date(_ value: String) -> Date? {
        for format in ["yyyy-MM-dd", "yyyy/MM/dd", "yyyyMMdd"] {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
            formatter.dateFormat = format
            if let date = formatter.date(from: value) { return date }
        }
        return nil
    }

    private static func fundCode(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        guard trimmed.allSatisfy(\.isNumber), trimmed.count < 6 else { return trimmed }
        return String(repeating: "0", count: 6 - trimmed.count) + trimmed
    }

    private static func assetClass(_ name: String) -> InvestmentType {
        if name.contains("黄金") { return .gold }
        if name.contains("货币") || name.contains("现金") { return .cash }
        if name.contains("债") { return .bond }
        return .stock
    }
}
