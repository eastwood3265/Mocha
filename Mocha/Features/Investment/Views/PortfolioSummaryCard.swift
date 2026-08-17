import SwiftUI

struct PortfolioSummaryCard: View {
    let summary: PortfolioSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("持仓市值").font(.subheadline).foregroundStyle(.black.opacity(0.62))
            Text(CurrencyFormatting.cny(summary.marketValue))
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Divider().overlay(.black.opacity(0.12))
            HStack(alignment: .top) {
                metric("投资项", "\(summary.investments.count) 项")
                Spacer()
                metric("当前盈亏", signed(summary.currentProfit))
            }
        }
        .foregroundStyle(.black)
        .padding(20)
        .background(MochaTheme.yellow, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: MochaTheme.yellow.opacity(0.28), radius: 16, y: 8)
    }

    private func signed(_ value: Decimal) -> String { "\(value >= 0 ? "+" : "")\(CurrencyFormatting.cny(value))" }
    private func metric(_ title: String, _ value: String, detail: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption2).foregroundStyle(.black.opacity(0.58))
            Text(value).font(.subheadline.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.7)
            if let detail { Text(detail).font(.caption2.weight(.semibold)) }
        }
    }
}
