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

    var backgroundComponents: ThemeRGB {
        switch self {
        case .lemon: ThemeRGB(red: 0.95, green: 0.72, blue: 0.08)
        case .mint: ThemeRGB(red: 0.32, green: 0.78, blue: 0.57)
        case .sky: ThemeRGB(red: 0.38, green: 0.70, blue: 0.94)
        case .coral: ThemeRGB(red: 0.94, green: 0.43, blue: 0.38)
        case .black: ThemeRGB(red: 0.08, green: 0.08, blue: 0.09)
        case .white: ThemeRGB(red: 0.97, green: 0.97, blue: 0.98)
        }
    }

    var color: Color { backgroundComponents.color }

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

    var foregroundComponents: ThemeRGB {
        switch self {
        case .lemon: ThemeRGB(red: 0.08, green: 0.07, blue: 0.04)
        case .mint: ThemeRGB(red: 0.04, green: 0.10, blue: 0.07)
        case .sky: ThemeRGB(red: 0.04, green: 0.08, blue: 0.12)
        case .coral: ThemeRGB(red: 0.12, green: 0.04, blue: 0.03)
        case .black: ThemeRGB(red: 1, green: 1, blue: 1)
        case .white: ThemeRGB(red: 0.08, green: 0.08, blue: 0.09)
        }
    }

    var foregroundColor: Color { foregroundComponents.color }

    var secondaryForegroundColor: Color {
        switch self {
        case .lemon: ThemeRGB(red: 0.20, green: 0.16, blue: 0.06).color
        case .mint: ThemeRGB(red: 0.08, green: 0.24, blue: 0.16).color
        case .sky: ThemeRGB(red: 0.07, green: 0.20, blue: 0.30).color
        case .coral: ThemeRGB(red: 0.28, green: 0.08, blue: 0.06).color
        case .black: ThemeRGB(red: 0.78, green: 0.78, blue: 0.80).color
        case .white: ThemeRGB(red: 0.27, green: 0.27, blue: 0.30).color
        }
    }

    var foregroundContrastRatio: Double {
        backgroundComponents.contrastRatio(with: foregroundComponents)
    }
}

struct ThemeRGB {
    let red: Double
    let green: Double
    let blue: Double

    var color: Color { Color(red: red, green: green, blue: blue) }

    func contrastRatio(with other: ThemeRGB) -> Double {
        let lighter = max(relativeLuminance, other.relativeLuminance)
        let darker = min(relativeLuminance, other.relativeLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private var relativeLuminance: Double {
        0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    private func linear(_ value: Double) -> Double {
        value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
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
    static var themeSecondaryForeground: Color { selectedThemeColor.secondaryForegroundColor }
    static var themeBorder: Color {
        selectedThemeColor.foregroundColor.opacity(selectedThemeColor == .white ? 0.28 : 0.20)
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
