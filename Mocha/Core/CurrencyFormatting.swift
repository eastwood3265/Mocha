import Foundation
import SwiftUI

enum AppThemeColor: String, CaseIterable, Identifiable {
    case lemon
    case mint
    case sky
    case coral
    case black
    case white

    static let storageKey = "selectedThemeColor"

    var id: Self { self }

    var title: String {
        switch self {
        case .lemon: "柠檬黄"
        case .mint: "薄荷绿"
        case .sky: "天空蓝"
        case .coral: "珊瑚红"
        case .black: "黑色"
        case .white: "白色"
        }
    }

    var color: Color {
        switch self {
        case .lemon: Color(red: 1.0, green: 0.82, blue: 0.0)
        case .mint: Color(red: 0.35, green: 0.86, blue: 0.63)
        case .sky: Color(red: 0.31, green: 0.68, blue: 0.96)
        case .coral: Color(red: 1.0, green: 0.42, blue: 0.36)
        case .black: Color(red: 0.08, green: 0.08, blue: 0.09)
        case .white: .white
        }
    }

    var softColor: Color {
        switch self {
        case .lemon: Color(red: 1.0, green: 0.96, blue: 0.72)
        case .mint: Color(red: 0.79, green: 0.96, blue: 0.87)
        case .sky: Color(red: 0.79, green: 0.91, blue: 1.0)
        case .coral: Color(red: 1.0, green: 0.82, blue: 0.78)
        case .black: Color(red: 0.90, green: 0.90, blue: 0.92)
        case .white: Color(red: 0.96, green: 0.96, blue: 0.97)
        }
    }

    var foregroundColor: Color {
        switch self {
        case .black: .white
        default: MochaTheme.primaryText
        }
    }
}

enum MochaTheme {
    static var selectedThemeColor: AppThemeColor {
        let rawValue = UserDefaults.standard.string(forKey: AppThemeColor.storageKey)
        return rawValue.flatMap(AppThemeColor.init(rawValue:)) ?? .lemon
    }

    static var yellow: Color { selectedThemeColor.color }
    static var softYellow: Color { selectedThemeColor.softColor }
    static var themeForeground: Color { selectedThemeColor.foregroundColor }
    static var themeBorder: Color {
        switch selectedThemeColor {
        case .white:
            secondaryText.opacity(0.25)
        default:
            selectedThemeColor.color.opacity(0.18)
        }
    }
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
