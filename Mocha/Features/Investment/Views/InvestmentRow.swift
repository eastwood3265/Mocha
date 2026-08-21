import SwiftUI

struct InvestmentRow: View {
    let investment: Investment
    @AppStorage(ProfitColorStyle.storageKey) private var profitColorStyleRawValue = ProfitColorStyle.defaultStyle.rawValue

    private var profitColorStyle: ProfitColorStyle {
        ProfitColorStyle(rawValue: profitColorStyleRawValue) ?? .defaultStyle
    }

    private var subtitle: String {
        let values = [investment.code, investment.storageLocation?.name ?? ""].filter { !$0.isEmpty }
        return values.isEmpty ? investment.type.rawValue : values.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: investment.type.icon)
                .font(.title3)
                .foregroundStyle(MochaTheme.themeForeground)
                .frame(width: 44, height: 44)
                .background(MochaTheme.yellow, in: RoundedRectangle(cornerRadius: 12))
                .overlay { RoundedRectangle(cornerRadius: 12).stroke(MochaTheme.themeBorder, lineWidth: 1) }
            VStack(alignment: .leading, spacing: 5) {
                Text(investment.name).font(.headline).lineLimit(1)
                Text(subtitle)
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                Text(CurrencyFormatting.cny(investment.holdingAmount)).font(.headline)
                if investment.type != .cash {
                    Text(ProfitPresentation.text(for: investment.effectiveTotalProfit))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ProfitPresentation.color(
                            for: investment.effectiveTotalProfit,
                            style: profitColorStyle
                        ))
                }
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(MochaTheme.yellow.opacity(0.18), lineWidth: 1) }
        .shadow(color: MochaTheme.yellow.opacity(0.08), radius: 8, y: 3)
    }
}
