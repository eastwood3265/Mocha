import Foundation

enum TransactionSource: String, Codable, CaseIterable, Identifiable {
    case alipay
    case wechat

    var id: Self { self }

    var title: String {
        switch self {
        case .alipay: "支付宝"
        case .wechat: "微信支付"
        }
    }
}

enum TransactionDirection: String, Codable {
    case income
    case expense
    case neutral

    var title: String {
        switch self {
        case .income: "收入"
        case .expense: "支出"
        case .neutral: "不计收支"
        }
    }
}
