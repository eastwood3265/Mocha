import SwiftUI

enum InvestmentType: String, Codable, CaseIterable, Identifiable {
    case bond = "债券"
    case stock = "股票"
    case gold = "黄金"
    case cash = "现金"

    var id: Self { self }

    var icon: String {
        switch self {
        case .bond: "chart.pie"
        case .stock: "chart.line.uptrend.xyaxis"
        case .gold: "seal.fill"
        case .cash: "banknote.fill"
        }
    }

    var color: Color {
        MochaTheme.yellow
    }
}
