import SwiftUI

struct PortfolioSummaryCard: View {
    let summary: PortfolioSummary
    @AppStorage(ProfitColorStyle.storageKey) private var profitColorStyleRawValue = ProfitColorStyle.defaultStyle.rawValue

    private var profitColorStyle: ProfitColorStyle {
        ProfitColorStyle(rawValue: profitColorStyleRawValue) ?? .defaultStyle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("持仓金额").font(.subheadline).foregroundStyle(MochaTheme.themeForeground.opacity(0.62))
            Text(CurrencyFormatting.cny(summary.holdingAmount))
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Divider().overlay(MochaTheme.themeForeground.opacity(0.12))
            HStack(alignment: .top) {
                metric("投资项", "\(summary.investments.count) 项")
                Spacer()
                metric(
                    "总盈亏",
                    ProfitPresentation.text(for: summary.totalProfit),
                    valueColor: ProfitPresentation.color(
                        for: summary.totalProfit,
                        style: profitColorStyle,
                        neutralColor: MochaTheme.themeForeground
                    )
                )
            }
        }
        .foregroundStyle(MochaTheme.themeForeground)
        .padding(20)
        .background(MochaTheme.yellow, in: RoundedRectangle(cornerRadius: 24))
        .overlay { RoundedRectangle(cornerRadius: 24).stroke(MochaTheme.themeBorder, lineWidth: 1) }
        .shadow(color: MochaTheme.yellow.opacity(0.28), radius: 16, y: 8)
    }

    private func metric(
        _ title: String,
        _ value: String,
        valueColor: Color? = nil,
        detail: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption2).foregroundStyle(MochaTheme.themeForeground.opacity(0.58))
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(valueColor ?? MochaTheme.themeForeground)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let detail { Text(detail).font(.caption2.weight(.semibold)) }
        }
    }
}
