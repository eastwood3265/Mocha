import Foundation
import SwiftUI

enum ProfitColorStyle: String, CaseIterable, Identifiable {
    case redForProfit
    case greenForProfit

    static let storageKey = "profitColorStyle"
    static let defaultStyle: ProfitColorStyle = .redForProfit

    var id: Self { self }

    var title: String {
        switch self {
        case .redForProfit: "正红负绿"
        case .greenForProfit: "正绿负红"
        }
    }

    func colorRole(for value: Decimal) -> ProfitColorRole {
        guard value != 0 else { return .neutral }
        switch (self, value > 0) {
        case (.redForProfit, true), (.greenForProfit, false):
            return .red
        case (.redForProfit, false), (.greenForProfit, true):
            return .green
        }
    }
}

enum ProfitColorRole: Equatable {
    case red
    case green
    case neutral
}

enum ProfitPresentation {
    static func text(for value: Decimal) -> String {
        value > 0 ? "+\(CurrencyFormatting.cny(value))" : CurrencyFormatting.cny(value)
    }

    static func color(
        for value: Decimal,
        style: ProfitColorStyle,
        neutralColor: Color = MochaTheme.secondaryText
    ) -> Color {
        switch style.colorRole(for: value) {
        case .red: .red
        case .green: .green
        case .neutral: neutralColor
        }
    }
}
