import Foundation

struct ParsedStatement {
    let source: TransactionSource
    let records: [ImportedTransaction]
    let skippedEmptyRowCount: Int
}

protocol StatementImporter {
    var source: TransactionSource { get }
    func canParse(header: [String]) -> Bool
    func parse(rows: [[String]], headerIndex: Int) throws -> ParsedStatement
}

struct StatementParser {
    private let importers: [any StatementImporter] = [
        AlipayStatementImporter(),
        WeChatStatementImporter()
    ]

    func parse(data: Data) throws -> ParsedStatement {
        let document = try CSVDocument(data: data)
        for (index, row) in document.rows.enumerated() {
            if let importer = importers.first(where: { $0.canParse(header: row) }) {
                return try importer.parse(rows: document.rows, headerIndex: index)
            }
        }
        throw StatementImportError.unsupportedStatement
    }
}

struct StatementColumnMap {
    private let columns: [String: Int]

    init(header: [String]) {
        columns = header.enumerated().reduce(into: [:]) { result, item in
            let normalized = Self.normalize(item.element)
            if !normalized.isEmpty { result[normalized] = item.offset }
        }
    }

    func value(in row: [String], aliases: [String]) -> String {
        for alias in aliases {
            if let index = columns[Self.normalize(alias)], index < row.count {
                return row[index].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return ""
    }

    func contains(any aliases: [String]) -> Bool {
        aliases.contains { columns[Self.normalize($0)] != nil }
    }

    private static func normalize(_ value: String) -> String {
        value.replacingOccurrences(of: "\u{feff}", with: "")
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}

enum StatementValueParser {
    static func date(_ value: String) -> Date? {
        for formatter in dateFormatters {
            if let date = formatter.date(from: value) { return date }
        }
        return nil
    }

    static func amount(_ value: String) -> Decimal? {
        let normalized = value
            .replacingOccurrences(of: "¥", with: "")
            .replacingOccurrences(of: "￥", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }

    static func direction(_ value: String) -> TransactionDirection {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.contains("收入") || normalized == "收" { return .income }
        if normalized.contains("支出") || normalized == "支" { return .expense }
        return .neutral
    }

    private static let dateFormatters: [DateFormatter] = [
        "yyyy-MM-dd HH:mm:ss",
        "yyyy/MM/dd HH:mm:ss",
        "yyyy-MM-dd HH:mm",
        "yyyy/MM/dd HH:mm"
    ].map { format in
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        formatter.dateFormat = format
        return formatter
    }
}
