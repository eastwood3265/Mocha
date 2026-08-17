import Foundation
import SwiftUI

enum MochaTheme {
    static let yellow = Color(red: 1.0, green: 0.82, blue: 0.0)
    static let softYellow = Color(red: 1.0, green: 0.96, blue: 0.72)
    static let background = Color.white
    static let primaryText = Color(red: 0.10, green: 0.10, blue: 0.11)
    static let secondaryText = Color(red: 0.32, green: 0.32, blue: 0.35)
}

enum CurrencyFormatting {
    static func cny(_ value: Decimal) -> String {
        value.formatted(.currency(code: "CNY").locale(Locale(identifier: "zh_CN")))
    }

    static func percent(_ value: Decimal) -> String {
        (value * 100).formatted(.number.precision(.fractionLength(2))) + "%"
    }
}
