import Foundation

enum InvestmentSnapshotImportError: LocalizedError, Equatable {
    case unsupportedFile
    case unsupportedStatement
    case missingRequiredColumns([String])
    case invalidRows(Int)
    case duplicateProducts([String])
    case noSnapshots
    case invalidImportConfiguration(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedFile:
            "文件损坏或不是受支持的 CSV/XLSX 文件"
        case .unsupportedStatement:
            "无法识别持仓文件，请使用基金 E 账户导出的 XLSX 或 Mocha 持仓快照 CSV"
        case .missingRequiredColumns(let columns):
            "持仓快照缺少必要字段：\(columns.joined(separator: "、"))"
        case .invalidRows(let count):
            "有 \(count) 行持仓无法解析，请修正后重新导入"
        case .duplicateProducts(let products):
            "同一文件存在重复持仓：\(products.joined(separator: "、"))"
        case .noSnapshots:
            "文件中没有可导入的持仓"
        case .invalidImportConfiguration(let message):
            message
        }
    }
}
