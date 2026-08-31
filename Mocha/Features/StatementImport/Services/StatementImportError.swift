import Foundation

enum StatementImportError: LocalizedError, Equatable {
    case unreadableFile
    case unsupportedEncoding
    case unsupportedStatement
    case missingRequiredColumns([String])
    case noTransactions
    case invalidRows(Int)

    var errorDescription: String? {
        switch self {
        case .unreadableFile: "无法读取所选文件"
        case .unsupportedEncoding: "账单文件编码不受支持"
        case .unsupportedStatement: "无法识别账单来源，请选择支付宝或微信导出的 CSV 文件"
        case .missingRequiredColumns(let columns): "账单缺少必要字段：\(columns.joined(separator: "、"))"
        case .noTransactions: "账单中没有可导入的交易"
        case .invalidRows(let count): "有 \(count) 行交易无法解析，请重新导出原始账单"
        }
    }
}
